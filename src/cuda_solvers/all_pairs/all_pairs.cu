static __constant__ float c_gravitational = 6.6743e-11;

__global__ void AllPairsKernel(float3* positions_src,
    float3* velocities_src,
    float3* positions_dst,
    float3* velocities_dst,
    const float* __restrict__ masses,
    const uint32_t bodyCount,
    const float dt,
    const float softening) {

    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= bodyCount) return;

    float3 acceleration = {0, 0, 0};

    const float3 process_position = positions_src[idx];
    const float3 process_velocity = velocities_src[idx];

    uint32_t sample_length = (bodyCount + gridDim.x - 1) / gridDim.x;
    const float soft_sqr = softening * softening;

    extern __shared__ char shared_memory[];
    float3* positions_sampling = (float3*)shared_memory;
    float* masses_sampling = (float*)&positions_sampling[sample_length];

    for (int i = 0; i < gridDim.x; i++) {
        int tile_start_idx = i * sample_length;
        int sampling_idx = tile_start_idx + threadIdx.x;

        if (sampling_idx < bodyCount) {
            positions_sampling[threadIdx.x] = positions_src[sampling_idx];
            masses_sampling[threadIdx.x] = masses[sampling_idx];
        }

        __syncthreads();

        int tile_elements = min(blockDim.x, bodyCount - tile_start_idx);

        for (int k = 0; k < tile_elements; k++) {

            float3 selected_position = positions_sampling[k];
            float selected_mass = masses_sampling[k];

            float3 displacement = {selected_position.x - process_position.x,selected_position.y - process_position.y,selected_position.z - process_position.z};
            float distance_sqr = displacement.x * displacement.x +displacement.y * displacement.y +displacement.z * displacement.z;
            float distance_sqr_soft = distance_sqr + soft_sqr;

            float inv_dist = rsqrtf(distance_sqr_soft);
            float inv_dist_cube = inv_dist * inv_dist * inv_dist;

            float accel_scalar = selected_mass * inv_dist_cube;

            acceleration.x += displacement.x * accel_scalar;
            acceleration.y += displacement.y * accel_scalar;
            acceleration.z += displacement.z * accel_scalar;
        }

        __syncthreads();
    }

    acceleration.x *= c_gravitational;
    acceleration.y *= c_gravitational;
    acceleration.z *= c_gravitational;

    float3 velocity_delta = {acceleration.x * dt, acceleration.y * dt, acceleration.z * dt};
    float3 velocity_scaled = {process_velocity.x + velocity_delta.x, process_velocity.y + velocity_delta.y, process_velocity.z + velocity_delta.z};

    positions_dst[idx] = {process_position.x + velocity_scaled.x * dt, process_position.y + velocity_scaled.y * dt, process_position.z + velocity_scaled.z * dt};
    velocities_dst[idx] = velocity_scaled;
}