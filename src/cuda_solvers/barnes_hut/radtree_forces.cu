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

__global__ void CalculateForces(
    const float3* __restrict__ positions,
    const float3* __restrict__ velocities,
    float3* positions_dst,
    float3* velocities_dst,
    const float* __restrict__ masses,
    const RadixTreeInternal* nodes,
    const float* __restrict__ node_masses,
    const float3* __restrict__ node_coms,
    const float3* __restrict__ node_bounds_min,
    const float3* __restrict__ node_bounds_max,
    const uint32_t* __restrict__ sorted_to_original,
    const float opening_angle_criterion,
    const float softening,
    const float dt,
    const int32_t num_particles,
    const int32_t leaf_bucket_size) {

    int32_t sorted_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (sorted_idx >= num_particles) return;

    int32_t idx = sorted_to_original[sorted_idx];

    float3 particle_position = positions[idx];
    float3 particle_velocity = velocities[idx];
    float3 acceleration = {0.0f, 0.0f, 0.0f};

    int32_t stack[64];
    int32_t stack_traverser = 0;
    stack[0] = 0;

    while (stack_traverser >= 0)
    {
        int32_t evaluated = stack[stack_traverser--];

        if (evaluated >= 0) {

            float3 evaluated_com = node_coms[evaluated];
            float3 displacement = {
                evaluated_com.x - particle_position.x,
                evaluated_com.y - particle_position.y,
                evaluated_com.z - particle_position.z
            };

            float distance_sqr = displacement.x * displacement.x +
                                 displacement.y * displacement.y +
                                 displacement.z * displacement.z;
            float distnce_inverse = rsqrtf(distance_sqr);

            if (MultipoleAcceptance(node_bounds_min[evaluated], node_bounds_max[evaluated], distnce_inverse, opening_angle_criterion)) {

                float evaluated_mass = node_masses[evaluated];
                float distance_sqr_soft = distance_sqr + softening;

                float inv_dist = rsqrtf(distance_sqr_soft);
                float inv_dist_cube = inv_dist * inv_dist * inv_dist;
                float accel_scalar = evaluated_mass * inv_dist_cube;

                acceleration.x += displacement.x * accel_scalar;
                acceleration.y += displacement.y * accel_scalar;
                acceleration.z += displacement.z * accel_scalar;

            } else {

                RadixTreeInternal node = nodes[evaluated];
                int32_t range_count = node.range_last - node.range_first + 1;

                if (range_count <= leaf_bucket_size) {
                    for (int32_t i = node.range_first; i <= node.range_last; i++) {
                        uint32_t orig = sorted_to_original[i];
                        if (orig == idx) continue;

                        float3 accel = PairAccelerations(particle_position, positions[orig], masses[orig], softening);
                        acceleration.x += accel.x;
                        acceleration.y += accel.y;
                        acceleration.z += accel.z;
                    }

                } else {
                    stack[++stack_traverser] = node.left_child;
                    stack[++stack_traverser] = node.right_child;
                }
            }
        } else {
            int32_t leaf_idx = ~evaluated;
            uint32_t orig = sorted_to_original[leaf_idx];

            if (orig != idx) {
                float3 accel = PairAccelerations(particle_position, positions[orig], masses[orig], softening);
                acceleration.x += accel.x;
                acceleration.y += accel.y;
                acceleration.z += accel.z;
            }
        }
    }

    acceleration.x *= c_gravitational;
    acceleration.y *= c_gravitational;
    acceleration.z *= c_gravitational;

    float3 velocity_delta = {acceleration.x * dt, acceleration.y * dt, acceleration.z * dt};
    float3 velocity_scaled = {particle_velocity.x + velocity_delta.x, particle_velocity.y + velocity_delta.y, particle_velocity.z + velocity_delta.z};

    positions_dst[idx] = {particle_position.x + velocity_scaled.x * dt, particle_position.y + velocity_scaled.y * dt, particle_position.z + velocity_scaled.z * dt};
    velocities_dst[idx] = velocity_scaled;
}