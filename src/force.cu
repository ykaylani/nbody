__constant__ float c_gravitational = 6.6743e-11;

__global__ void Run(float3* positions, float3* velocities, float3* positions2, float3* velocities2, const float* __restrict__ masses, const  uint32_t bodyCount, const float dt, const uint32_t step, const float softening, const bool equalMass) {
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= bodyCount) return;

    const float3* current_positions = (step % 2 == 0) ? positions : positions2;
    const float3* current_velocities = (step % 2 == 0) ? velocities : velocities2;
    const float* current_masses = masses;

    float3 acceleration = {0, 0, 0};

    float3 process_position = current_positions[idx];
    float3 process_velocity = current_velocities[idx];
    const float process_mass = equalMass ? *masses : masses[idx];

    uint32_t sample_length = (bodyCount + gridDim.x - 1) / gridDim.x;

    extern __shared__ char shared_memory[];
    float3* positions_sampling = (float3*)shared_memory;
    float* masses_sampling = (float*)&positions_sampling[sample_length];

    #pragma unroll
    for (int i = 0; i < gridDim.x; i++) {
        int tile_start_idx = i * sample_length;
        int sampling_idx = tile_start_idx + threadIdx.x;

        if (sampling_idx < bodyCount) {
            positions_sampling[threadIdx.x] = current_positions[sampling_idx];
            masses_sampling[threadIdx.x] = current_masses[sampling_idx];
        }

        __syncthreads();

        int tile_elements = min(blockDim.x, bodyCount - tile_start_idx);

        #pragma unroll
        for (int k = 0; k < tile_elements; k++) {

            float3 selected_position = positions_sampling[k];
            float selected_mass = (equalMass) ? process_mass : masses_sampling[k];

            float3 displacement = {selected_position.x - process_position.x,selected_position.y - process_position.y,selected_position.z - process_position.z};
            float distance_sqr = displacement.x * displacement.x +displacement.y * displacement.y +displacement.z * displacement.z;
            float distance_sqr_soft = distance_sqr + softening * softening;

            float inv_dist = rsqrtf(distance_sqr_soft);
            float inv_dist_cube = inv_dist * inv_dist * inv_dist;

            float accel_scalar = c_gravitational * selected_mass * inv_dist_cube;

            acceleration.x += displacement.x * accel_scalar;
            acceleration.y += displacement.y * accel_scalar;
            acceleration.z += displacement.z * accel_scalar;
        }

        __syncthreads();
    }

    float3 velocity_delta = {acceleration.x * dt, acceleration.y * dt, acceleration.z * dt};
    float3 velocity_scaled = {process_velocity.x + velocity_delta.x, process_velocity.y + velocity_delta.y, process_velocity.z + velocity_delta.z};

    if (step % 2 == 0) {
        positions2[idx] = {process_position.x + velocity_scaled.x * dt, process_position.y + velocity_scaled.y * dt, process_position.z + velocity_scaled.z * dt};
        velocities2[idx] = velocity_scaled;
    } else {
        positions[idx] = {process_position.x + velocity_scaled.x * dt, process_position.y + velocity_scaled.y * dt, process_position.z + velocity_scaled.z * dt};
        velocities[idx] = velocity_scaled;
    }
}