#include <cuda/std/cstdint>
#include <cuda/atomic>
#include "radtree_nodes.h"

static __constant__ float c_gravitational = 6.6743e-11f;

__device__ __forceinline__ bool MultipoleAcceptance(float4 node_bounds_min, float4 node_bounds_max, float dist_inverse, float opening_angle_criterion) {
    float edge = fmaxf(fmaxf(node_bounds_max.x - node_bounds_min.x, node_bounds_max.y - node_bounds_min.y), node_bounds_max.z - node_bounds_min.z);
    return (edge * dist_inverse < opening_angle_criterion);
}

__device__ __forceinline__ float4 PairAccelerations(float4 particle_position, float4 other_position, float softening) {
    float4 displacement = { other_position.x - particle_position.x,other_position.y - particle_position.y,other_position.z - particle_position.z, 0 };

    float distance_sqr = displacement.x * displacement.x + displacement.y * displacement.y + displacement.z * displacement.z;
    float distance_sqr_soft = distance_sqr + softening;

    float inv_dist = rsqrtf(distance_sqr_soft);
    float inv_dist_cube = inv_dist * inv_dist * inv_dist;
    float accel_scalar = other_position.w * inv_dist_cube;

    return {displacement.x * accel_scalar, displacement.y * accel_scalar, displacement.z * accel_scalar, 0};
}

__global__ void GatherParticles(
    const float4* __restrict__ positions,
    const float4* __restrict__ velocities,
    const uint32_t* __restrict__ sorted_to_original,
    float4* __restrict__ positions_sorted,
    float4* __restrict__ velocities_sorted,
    const int32_t num_particles) {

    int32_t sorted_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (sorted_idx >= num_particles) return;

    uint32_t orig = sorted_to_original[sorted_idx];

    positions_sorted[sorted_idx] = positions[orig];
    velocities_sorted[sorted_idx] = velocities[orig];
}

__global__ void CalculateForcesSorted(
    const float4* __restrict__ positions_sorted,
    const float4* __restrict__ velocities_sorted,
    float4* positions_dst_sorted,
    float4* velocities_dst_sorted,
    const RadixTreeInternal* nodes,
    const float4* __restrict__ node_coms,   // xyz = COM, w = total mass
    const float4* __restrict__ node_bounds_min,
    const float4* __restrict__ node_bounds_max,
    const float opening_angle_criterion,
    const float softening,
    const float dt,
    const int32_t num_particles,
    const int32_t leaf_bucket_size) {

    int32_t sorted_idx = blockIdx.x * blockDim.x + threadIdx.x;
    bool is_active = sorted_idx < num_particles;

    float4 particle_position = is_active ? positions_sorted[sorted_idx] : make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 particle_velocity = is_active ? velocities_sorted[sorted_idx] : make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 acceleration = {0.0f, 0.0f, 0.0f, 0.0f};

    int32_t stack[64];
    int32_t stack_traverser = 0;
    stack[0] = 0;

    while (stack_traverser >= 0) {
        int32_t evaluated = stack[stack_traverser--];

        if (evaluated >= 0) {

            float4 evaluated_com = node_coms[evaluated];
            float4 displacement = { evaluated_com.x - particle_position.x, evaluated_com.y - particle_position.y, evaluated_com.z - particle_position.z, 0.0f };

            float distance_sqr = displacement.x * displacement.x + displacement.y * displacement.y + displacement.z * displacement.z;
            float distance_inverse = rsqrtf(distance_sqr);

            bool mac = MultipoleAcceptance(
                node_bounds_min[evaluated],
                node_bounds_max[evaluated],
                distance_inverse,
                opening_angle_criterion
            );

            bool thread_opens = is_active && !mac;
            bool warp_opens = __any_sync(0xFFFFFFFF, thread_opens);

            if (!warp_opens) {
                if (is_active) {
                    float evaluated_mass = evaluated_com.w;
                    float distance_sqr_soft = distance_sqr + softening;

                    float inv_dist = rsqrtf(distance_sqr_soft);
                    float inv_dist_cube = inv_dist * inv_dist * inv_dist;
                    float accel_scalar = evaluated_mass * inv_dist_cube;

                    acceleration.x += displacement.x * accel_scalar;
                    acceleration.y += displacement.y * accel_scalar;
                    acceleration.z += displacement.z * accel_scalar;
                }
            } else {
                RadixTreeInternal node = nodes[evaluated];
                int32_t range_count = node.range_last - node.range_first + 1;

                if (range_count <= leaf_bucket_size) {
                    for (int32_t i = node.range_first; i <= node.range_last; i++) {
                        if (is_active && i != sorted_idx) {
                            float4 accel = PairAccelerations(particle_position, positions_sorted[i], softening);

                            acceleration.x += accel.x;
                            acceleration.y += accel.y;
                            acceleration.z += accel.z;
                        }
                    }
                } else {
                    stack[++stack_traverser] = node.left_child;
                    stack[++stack_traverser] = node.right_child;
                }
            }
        } else {
            int32_t leaf_idx = ~evaluated;

            if (is_active && leaf_idx != sorted_idx) {
                float4 accel = PairAccelerations(particle_position, positions_sorted[leaf_idx], softening);

                acceleration.x += accel.x;
                acceleration.y += accel.y;
                acceleration.z += accel.z;
            }
        }
    }

    if (is_active) {
        acceleration.x *= c_gravitational;
        acceleration.y *= c_gravitational;
        acceleration.z *= c_gravitational;

        float4 velocity_delta = {acceleration.x * dt, acceleration.y * dt, acceleration.z * dt, 0.0f};
        float4 velocity_scaled = {particle_velocity.x + velocity_delta.x, particle_velocity.y + velocity_delta.y, particle_velocity.z + velocity_delta.z, 0.0f};

        positions_dst_sorted[sorted_idx] = {particle_position.x + velocity_scaled.x * dt, particle_position.y + velocity_scaled.y * dt, particle_position.z + velocity_scaled.z * dt, particle_position.w};
        velocities_dst_sorted[sorted_idx] = velocity_scaled;
    }
}

__global__ void ScatterParticles(
    const float4* __restrict__ positions_dst_sorted,
    const float4* __restrict__ velocities_dst_sorted,
    const uint32_t* __restrict__ sorted_to_original,
    float4* __restrict__ positions_dst,
    float4* __restrict__ velocities_dst,
    const int32_t num_particles) {

    int32_t sorted_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (sorted_idx >= num_particles) return;

    uint32_t orig = sorted_to_original[sorted_idx];
    positions_dst[orig] = positions_dst_sorted[sorted_idx];
    velocities_dst[orig] = velocities_dst_sorted[sorted_idx];
}

void CalculateForces(
    const float4* positions,
    const float4* velocities,
    float4* positions_dst,
    float4* velocities_dst,
    const RadixTreeInternal* nodes,
    const float4* node_coms,
    const float4* node_bounds_min,
    const float4* node_bounds_max,
    const uint32_t* sorted_to_original,
    float4* scratch_positions_sorted,
    float4* scratch_velocities_sorted,
    float4* scratch_positions_dst_sorted,
    float4* scratch_velocities_dst_sorted,
    const float opening_angle_criterion,
    const float softening,
    const float dt,
    const int32_t num_particles,
    const int32_t leaf_bucket_size,
    const int32_t threads_per_block,
    cudaStream_t stream) {

    int32_t blocks = (num_particles + threads_per_block - 1) / threads_per_block;

    GatherParticles<<<blocks, threads_per_block, 0, stream>>>(
        positions, velocities, sorted_to_original,
        scratch_positions_sorted, scratch_velocities_sorted,
        num_particles);

    CalculateForcesSorted<<<blocks, threads_per_block, 0, stream>>>(
        scratch_positions_sorted, scratch_velocities_sorted,
        scratch_positions_dst_sorted, scratch_velocities_dst_sorted,
        nodes, node_coms, node_bounds_min, node_bounds_max,
        opening_angle_criterion, softening, dt, num_particles, leaf_bucket_size);

    ScatterParticles<<<blocks, threads_per_block, 0, stream>>>(
        scratch_positions_dst_sorted, scratch_velocities_dst_sorted, sorted_to_original,
        positions_dst, velocities_dst, num_particles);
}