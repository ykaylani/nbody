__constant__ float c_gravitational = 6.6743e-11;

__global__ void Run(float3* positions, float3* velocities, float3* positions2, float3* velocities2, const float* __restrict__ inv_masses, const  uint32_t bodyCount, const float dt, const uint32_t step, const float softening, const bool equalMass) {
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= bodyCount) return;

    const float3* current_positions = (step % 2 == 0) ? positions : positions2;
    const float3* current_velocities = (step % 2 == 0) ? velocities : velocities2;
    const float* current_invmasses = inv_masses;

    float3 force = {0, 0, 0};

    float3 process_position = current_positions[idx];
    float3 process_velocity = current_velocities[idx];

    const float process_invmass = (equalMass) ? *inv_masses : inv_masses[idx];

    uint32_t sample_length = (bodyCount + gridDim.x - 1) / gridDim.x;

    extern __shared__ char shared_memory[];
    float3* positions_sampling = (float3*)shared_memory;
    float* invmasses_sampling = (float*)&positions_sampling[sample_length];

    for (int i = 0; i < gridDim.x; i++) {
        int tile_start_idx = i * sample_length;

        for (int j = threadIdx.x; j < sample_length; j += blockDim.x) {
            if (tile_start_idx + j < bodyCount) {
                positions_sampling[j] = current_positions[tile_start_idx + j];
                invmasses_sampling[j] = current_invmasses[tile_start_idx + j];
            }
        }

        __syncthreads();

        for (int k = 0; k < sample_length; k++) {
            float3 selected_position = positions_sampling[k];
            float selected_invmass = (equalMass) ? process_invmass : invmasses_sampling[k];

            float3 displacement = {selected_position.x - process_position.x, selected_position.y - process_position.y, selected_position.z - process_position.z};
            float distance_sqr = displacement.x * displacement.x + displacement.y * displacement.y + displacement.z * displacement.z;
            if (distance_sqr < 0.01f) { continue; }

            float distance_inv = rsqrt(distance_sqr);
            float3 displacement_unit = {displacement.x * distance_inv, displacement.y * distance_inv, displacement.z * distance_inv};

            float force_magnitude = c_gravitational / (selected_invmass * process_invmass * (distance_sqr + softening * softening));
            float3 total = {displacement_unit.x * force_magnitude, displacement_unit.y * force_magnitude, displacement_unit.z * force_magnitude};

            force = {force.x + total.x, force.y + total.y, force.z + total.z};
        }

        __syncthreads();
    }

    float3 scaled_force = {force.x * dt * process_invmass, force.y * dt * process_invmass, force.z * dt * process_invmass};
    float3 velocity_scaled = {process_velocity.x + scaled_force.x, process_velocity.y + scaled_force.y, process_velocity.z + scaled_force.z};

    if (step % 2 == 0) {
        positions2[idx] = {process_position.x + velocity_scaled.x * dt, process_position.y + velocity_scaled.y * dt, process_position.z + velocity_scaled.z * dt};
        velocities2[idx] = velocity_scaled;
    } else {
        positions[idx] = {process_position.x + velocity_scaled.x * dt, process_position.y + velocity_scaled.y * dt, process_position.z + velocity_scaled.z * dt};
        velocities[idx] = velocity_scaled;
    }
}