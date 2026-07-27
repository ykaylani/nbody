#include <stdexcept>
#include <cuda/std/cstdint>

static __constant__ float c_gravitational = 6.6743e-11;

__global__ void KineticEnergyArray(const float4* __restrict__ positions, const float4* __restrict__ velocities, float* kinetic_memory, const uint32_t body_count) {
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= body_count) return;

    float4 velocity = velocities[idx];
    float sqr_velocity = velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z;
    kinetic_memory[idx] = 0.5f * positions[idx].w * sqr_velocity;
}

__global__ void PotentialEnergyArray(const float4* __restrict__ positions, float* potential_memory, const uint32_t body_count, const float softening) {
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    bool is_active = idx < body_count;

    float GPE = 0.0f;
    float4 process_position = is_active ? positions[idx] : make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    float softening_sqr = softening * softening;

    extern __shared__ float4 positions_sampling[];

    for (int i = 0; i < gridDim.x; i++) {
        int tile_start_idx = i * blockDim.x;
        int sampling_idx = tile_start_idx + threadIdx.x;

        positions_sampling[threadIdx.x] = (sampling_idx < body_count) ? positions[sampling_idx] : make_float4(0.0f, 0.0f, 0.0f, 0.0f);
        int tile_elements = min((int)blockDim.x, (int)(body_count - tile_start_idx));

        __syncthreads();

        if (is_active) {
            for (int k = 0; k < tile_elements; k++) {
                float4 selected = positions_sampling[k];
                float4 displacement = {selected.x - process_position.x, selected.y - process_position.y, selected.z - process_position.z, 0.0f};
                float distance_sqr = displacement.x * displacement.x + displacement.y * displacement.y + displacement.z * displacement.z;
                int current_j = tile_start_idx + k;

                if (idx != current_j) {
                    float inv_dist = rsqrtf(distance_sqr + softening_sqr);
                    GPE += -c_gravitational * process_position.w * selected.w * inv_dist * 0.5f;
                }
            }
        }
        __syncthreads();
    }

    if (is_active) potential_memory[idx] = GPE;
}