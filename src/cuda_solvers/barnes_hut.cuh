#ifndef NBODY_BARNES_HUT_H
#define NBODY_BARNES_HUT_H

#include "./barnes_hut/radtree_nodes.h"

__global__ void EncodeF3A(float4* encode, uint64_t* out, uint32_t count, const float4* __restrict__ root_bounds_min, const float4* __restrict__ root_bounds_max);
void SeedSceneBounds(const float4* positions, float4* root_bounds_min, float4* root_bounds_max, uint32_t count);
__global__ void BuildKarrasTrie(const uint64_t* __restrict__ codes, RadixTreeInternal* internal_nodes, int32_t* leaf_parents, int32_t body_count);

__global__ void CalculateCOMs(
    RadixTreeInternal* internal_nodes,
    cuda::atomic<int, cuda::thread_scope_device>* flags,
    float4* node_coms,
    float4* node_bounds_min,
    float4* node_bounds_max,
    const uint32_t* __restrict__ sorted_to_original,
    const int32_t* __restrict__ leaf_parents,
    const float4* __restrict__ positions,
    const uint32_t body_count);

void CalculateForces(
    const float4* __restrict__ positions,
    const float4* __restrict__ velocities,
    float4* positions_dst,
    float4* velocities_dst,
    const RadixTreeInternal* nodes,
    const float4* __restrict__ node_coms,
    const float4* __restrict__ node_bounds_min,
    const float4* __restrict__ node_bounds_max,
    const uint32_t* __restrict__ sorted_to_original,
    float4* scratch_positions_sorted,
    float4* scratch_velocities_sorted,
    float4* scratch_positions_dst_sorted,
    float4* scratch_velocities_dst_sorted,
    float opening_angle_criterion,
    float softening,
    float dt,
    int32_t num_particles,
    const int32_t leaf_bucket_size,
    int32_t threads_per_block = 128,
    cudaStream_t stream = 0);

#endif //NBODY_BARNES_HUT_H