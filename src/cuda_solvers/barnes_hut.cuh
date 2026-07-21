#ifndef NBODY_BARNES_HUT_H
#define NBODY_BARNES_HUT_H

__global__ void EncodeF3A(float3* encode, uint64_t* out, uint32_t count);

__global__ void BuildKarrasTrie(const uint64_t* __restrict__ codes, RadixTreeInternal* internal_nodes, int32_t* leaf_parents, int32_t body_count);

__global__ void CalculateCOMs(
    RadixTreeInternal* internal_nodes,
    cuda::atomic<int, cuda::thread_scope_device>* flags,
    float3* node_coms,
    float* node_masses,
    float3* node_bounds_min,
    float3* node_bounds_max,
    const uint32_t* __restrict__ sorted_to_original,
    const int32_t* __restrict__ leaf_parents,
    const float3* __restrict__ positions,
    const float* __restrict__ masses,
    const uint32_t body_count);

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
    float opening_angle_criterion,
    float softening,
    float dt,
    int32_t num_particles,
    const int32_t leaf_bucket_size);

#endif //NBODY_BARNES_HUT_H