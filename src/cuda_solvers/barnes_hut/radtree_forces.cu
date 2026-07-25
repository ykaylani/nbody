#include <cuda/std/cstdint>
#include <cuda/atomic>
#include "radtree_nodes.h"

static __constant__ float c_gravitational = 6.6743e-11f;

__device__ __forceinline__ bool MultipoleAcceptance(float3 node_bounds_min, float3 node_bounds_max, float dist_inverse, float opening_angle_criterion) {
    float edge = fmaxf(fmaxf(node_bounds_max.x - node_bounds_min.x, node_bounds_max.y - node_bounds_min.y), node_bounds_max.z - node_bounds_min.z);
    return (edge * dist_inverse < opening_angle_criterion);
}

__device__ __forceinline__ float3 PairAccelerations(float3 particle_position, float3 other_position, float other_mass, float softening) {
    float3 displacement = {
        other_position.x - particle_position.x,
        other_position.y - particle_position.y,
        other_position.z - particle_position.z
    };

    float distance_sqr = displacement.x * displacement.x + displacement.y * displacement.y + displacement.z * displacement.z;
    float distance_sqr_soft = distance_sqr + softening;

    float inv_dist = rsqrtf(distance_sqr_soft);
    float inv_dist_cube = inv_dist * inv_dist * inv_dist;
    float accel_scalar = other_mass * inv_dist_cube;

    return {displacement.x * accel_scalar, displacement.y * accel_scalar, displacement.z * accel_scalar};
}

__global__ void GatherParticles(
    const float3* __restrict__ positions,
    const float3* __restrict__ velocities,
    const float* __restrict__ masses,
    const uint32_t* __restrict__ sorted_to_original,
    float3* __restrict__ positions_sorted,
    float3* __restrict__ velocities_sorted,
    float* __restrict__ masses_sorted,
    const int32_t num_particles) {

    int32_t sorted_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (sorted_idx >= num_particles) return;

    uint32_t orig = sorted_to_original[sorted_idx];

    positions_sorted[sorted_idx] = positions[orig];
    velocities_sorted[sorted_idx] = velocities[orig];
    masses_sorted[sorted_idx] = masses[orig];
}

__global__ void CalculateForcesSorted(
    const float3* __restrict__ positions_sorted,
    const float3* __restrict__ velocities_sorted,
    float3* positions_dst_sorted,
    float3* velocities_dst_sorted,
    const float* __restrict__ masses_sorted,
    const RadixTreeInternal* nodes,
    const float* __restrict__ node_masses,
    const float3* __restrict__ node_coms,
    const float3* __restrict__ node_bounds_min,
    const float3* __restrict__ node_bounds_max,
    const float opening_angle_criterion,
    const float softening,
    const float dt,
    const int32_t num_particles,
    const int32_t leaf_bucket_size) {

    int32_t sorted_idx = blockIdx.x * blockDim.x + threadIdx.x;
    bool is_active = sorted_idx < num_particles;

    float3 particle_position = is_active ? positions_sorted[sorted_idx] : make_float3(0.0f, 0.0f, 0.0f);
    float3 particle_velocity = is_active ? velocities_sorted[sorted_idx] : make_float3(0.0f, 0.0f, 0.0f);
    float3 acceleration = {0.0f, 0.0f, 0.0f};

    int32_t stack[64];
    int32_t stack_traverser = 0;
    stack[0] = 0;

    while (stack_traverser >= 0) {
        int32_t evaluated = stack[stack_traverser--];

        if (evaluated >= 0) {

            float3 evaluated_com = node_coms[evaluated];
            float3 displacement = { evaluated_com.x - particle_position.x, evaluated_com.y - particle_position.y, evaluated_com.z - particle_position.z };

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
                    float evaluated_mass = node_masses[evaluated];
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
                            float3 accel = PairAccelerations(particle_position, positions_sorted[i], masses_sorted[i], softening);
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
                float3 accel = PairAccelerations(particle_position, positions_sorted[leaf_idx], masses_sorted[leaf_idx], softening);
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

        float3 velocity_delta = {acceleration.x * dt, acceleration.y * dt, acceleration.z * dt};
        float3 velocity_scaled = {particle_velocity.x + velocity_delta.x, particle_velocity.y + velocity_delta.y, particle_velocity.z + velocity_delta.z};

        positions_dst_sorted[sorted_idx] = {particle_position.x + velocity_scaled.x * dt, particle_position.y + velocity_scaled.y * dt, particle_position.z + velocity_scaled.z * dt};
        velocities_dst_sorted[sorted_idx] = velocity_scaled;
    }
}

__global__ void ScatterParticles(
    const float3* __restrict__ positions_dst_sorted,
    const float3* __restrict__ velocities_dst_sorted,
    const uint32_t* __restrict__ sorted_to_original,
    float3* __restrict__ positions_dst,
    float3* __restrict__ velocities_dst,
    const int32_t num_particles) {

    int32_t sorted_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (sorted_idx >= num_particles) return;

    uint32_t orig = sorted_to_original[sorted_idx];
    positions_dst[orig] = positions_dst_sorted[sorted_idx];
    velocities_dst[orig] = velocities_dst_sorted[sorted_idx];
}

void CalculateForces(
    const float3* positions,
    const float3* velocities,
    float3* positions_dst,
    float3* velocities_dst,
    const float* masses,
    const RadixTreeInternal* nodes,
    const float* node_masses,
    const float3* node_coms,
    const float3* node_bounds_min,
    const float3* node_bounds_max,
    const uint32_t* sorted_to_original,
    float3* scratch_positions_sorted,
    float3* scratch_velocities_sorted,
    float* scratch_masses_sorted,
    float3* scratch_positions_dst_sorted,
    float3* scratch_velocities_dst_sorted,
    const float opening_angle_criterion,
    const float softening,
    const float dt,
    const int32_t num_particles,
    const int32_t leaf_bucket_size,
    const int32_t threads_per_block,
    cudaStream_t stream) {

    int32_t blocks = (num_particles + threads_per_block - 1) / threads_per_block;

    GatherParticles<<<blocks, threads_per_block, 0, stream>>>(
        positions, velocities, masses, sorted_to_original,
        scratch_positions_sorted, scratch_velocities_sorted, scratch_masses_sorted,
        num_particles);

    CalculateForcesSorted<<<blocks, threads_per_block, 0, stream>>>(
        scratch_positions_sorted, scratch_velocities_sorted,
        scratch_positions_dst_sorted, scratch_velocities_dst_sorted,
        scratch_masses_sorted, nodes, node_masses, node_coms, node_bounds_min, node_bounds_max,
        opening_angle_criterion, softening, dt, num_particles, leaf_bucket_size);

    ScatterParticles<<<blocks, threads_per_block, 0, stream>>>(
        scratch_positions_dst_sorted, scratch_velocities_dst_sorted, sorted_to_original,
        positions_dst, velocities_dst, num_particles);
}