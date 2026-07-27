#include <cuda/std/cstdint>
static __constant__ float c_gravitational = 6.6743e-11;

__global__ void AllPairsKernel(
    float4* positions_src,
    float4* velocities_src,
    float4* positions_dst,
    float4* velocities_dst,
    const uint32_t body_count,
    const float dt,
    const float softening) {

    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= body_count) return;

    float4 acceleration = {0, 0, 0, 0};
    const float4 process_position = positions_src[idx];
    const float4 process_velocity = velocities_src[idx];

    uint32_t sample_length = (body_count + gridDim.x - 1) / gridDim.x;
    const float soft_sqr = softening * softening;

    extern __shared__ float4 positions_sampling[];

    for (int i = 0; i < gridDim.x; i++) {

        int tile_start_idx = i * blockDim.x;
        int sampling_idx = tile_start_idx + threadIdx.x;
        if (sampling_idx < body_count) { positions_sampling[threadIdx.x] = positions_src[sampling_idx]; }
        __syncthreads();
        int tile_elements = min((int)blockDim.x, (int)(body_count - tile_start_idx));

        for (int k = 0; k < tile_elements; k++) {

            float4 selected = positions_sampling[k];
            float4 displacement = {selected.x - process_position.x, selected.y - process_position.y, selected.z - process_position.z, 0.0f};

            float distance_sqr = displacement.x * displacement.x + displacement.y * displacement.y + displacement.z * displacement.z;
            float inv_dist = rsqrtf(distance_sqr + soft_sqr);
            float inv_dist_cube = inv_dist * inv_dist * inv_dist;

            float accel_scalar = selected.w * inv_dist_cube;
            acceleration.x += displacement.x * accel_scalar;
            acceleration.y += displacement.y * accel_scalar;
            acceleration.z += displacement.z * accel_scalar;
        }
        __syncthreads();
    }

    acceleration.x *= c_gravitational;
    acceleration.y *= c_gravitational;
    acceleration.z *= c_gravitational;

    float4 velocity_scaled = {process_velocity.x + acceleration.x * dt,process_velocity.y + acceleration.y * dt,process_velocity.z + acceleration.z * dt, 0.0f};
    positions_dst[idx] = {process_position.x + velocity_scaled.x * dt,process_position.y + velocity_scaled.y * dt,process_position.z + velocity_scaled.z * dt, process_position.w};
    velocities_dst[idx] = velocity_scaled;
}