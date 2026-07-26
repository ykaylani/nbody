#ifndef NBODY_BODY_DATA_H
#define NBODY_BODY_DATA_H

#include <cuda_runtime.h>
#include <cuda/__atomic/atomic.h>

#include "../cuda_solvers/barnes_hut/radtree_nodes.h"

struct BodyData {
    float4* positions_1 = nullptr;
    float4* velocities_1 = nullptr;

    float4* positions_2 = nullptr;
    float4* velocities_2 = nullptr;

    BodyData(uint32_t n_count) {
        cudaMallocManaged(&positions_1, sizeof(float4) * n_count);
        cudaMallocManaged(&velocities_1, sizeof(float4) * n_count);

        cudaMallocManaged(&positions_2, sizeof(float4) * n_count);
        cudaMallocManaged(&velocities_2, sizeof(float4) * n_count);
    }

    ~BodyData() {
        cudaFree(positions_1);
        cudaFree(velocities_1);

        cudaFree(positions_2);
        cudaFree(velocities_2);
    }

    BodyData(const BodyData&) = delete;
    BodyData& operator=(const BodyData&) = delete;
};

struct BarnesHutInterData {
    uint64_t* encodings = nullptr;

    int32_t* leaf_parents = nullptr;
    uint32_t* sorted_to_original = nullptr;

    RadixTreeInternal* bintrie_internals = nullptr;
    float4* node_coms = nullptr;
    float* node_masses = nullptr;

    float4* node_bounds_min = nullptr;
    float4* node_bounds_max = nullptr;
    cuda::atomic<int32_t, cuda::thread_scope_device>* node_flags = nullptr;

    float4* scratch_positions_sorted = nullptr;
    float4* scratch_velocities_sorted = nullptr;
    float* scratch_masses_sorted = nullptr;
    float4* scratch_positions_dst_sorted = nullptr;
    float4* scratch_velocities_dst_sorted = nullptr;

    BarnesHutInterData(uint32_t n_count) {

        cudaMallocManaged(&encodings, sizeof(uint64_t) * n_count);
        cudaMallocManaged(&leaf_parents, sizeof(int32_t) * n_count);
        cudaMallocManaged(&sorted_to_original, sizeof(uint32_t) * n_count);

        cudaMallocManaged(&scratch_positions_sorted, sizeof(float4) * n_count);
        cudaMallocManaged(&scratch_velocities_sorted, sizeof(float4) * n_count);
        cudaMallocManaged(&scratch_masses_sorted, sizeof(float) * n_count);
        cudaMallocManaged(&scratch_positions_dst_sorted, sizeof(float4) * n_count);
        cudaMallocManaged(&scratch_velocities_dst_sorted, sizeof(float4) * n_count);

        uint32_t internal_count = n_count - 1;

        cudaMallocManaged(&bintrie_internals, sizeof(RadixTreeInternal) * internal_count);
        cudaMallocManaged(&node_coms, sizeof(float4) * internal_count);
        cudaMallocManaged(&node_masses, sizeof(float) * internal_count);

        cudaMallocManaged(&node_bounds_min, sizeof(float4) * internal_count);
        cudaMallocManaged(&node_bounds_max, sizeof(float4) * internal_count);
        cudaMallocManaged(&node_flags, sizeof(int32_t) * internal_count);
    }

    ~BarnesHutInterData() {
        cudaFree(encodings);
        cudaFree(leaf_parents);
        cudaFree(sorted_to_original);

        cudaFree(scratch_positions_sorted);
        cudaFree(scratch_velocities_sorted);
        cudaFree(scratch_masses_sorted);
        cudaFree(scratch_positions_dst_sorted);
        cudaFree(scratch_velocities_dst_sorted);

        cudaFree(bintrie_internals);
        cudaFree(node_coms);
        cudaFree(node_masses);

        cudaFree(node_bounds_min);
        cudaFree(node_bounds_max);
        cudaFree(node_flags);
    }
};

#endif //NBODY_BODY_DATA_H