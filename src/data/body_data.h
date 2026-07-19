#ifndef NBODY_BODY_DATA_H
#define NBODY_BODY_DATA_H

#include <cuda_runtime.h>

#include "cuda_solvers/barnes_hut/bintrie_nodes.h"

struct BodyData {
    float3* positions_1 = nullptr;
    float3* velocities_1 = nullptr;

    float3* positions_2 = nullptr;
    float3* velocities_2 = nullptr;

    float* masses = nullptr;

    BodyData(uint32_t n_count) {
        cudaMallocManaged(&positions_1, sizeof(float3) * n_count);
        cudaMallocManaged(&velocities_1, sizeof(float3) * n_count);

        cudaMallocManaged(&positions_2, sizeof(float3) * n_count);
        cudaMallocManaged(&velocities_2, sizeof(float3) * n_count);

        cudaMallocManaged(&masses, sizeof(float) * n_count);
    }

    ~BodyData() {
        cudaFree(positions_1);
        cudaFree(velocities_1);

        cudaFree(positions_2);
        cudaFree(velocities_2);

        cudaFree(masses);
    }

    BodyData(const BodyData&) = delete;
    BodyData& operator=(const BodyData&) = delete;
};

struct BarnesHutInterData {
    uint64_t* encodings = nullptr;

    uint32_t* leaf_parents = nullptr;
    uint32_t* sorted_to_original = nullptr;

    BintrieInternal* bintrie_internals = nullptr;
    float3* node_coms = nullptr;
    float* node_masses = nullptr;

    BarnesHutInterData(uint32_t n_count) {
        cudaMallocManaged(&encodings, sizeof(uint64_t) * n_count);
        cudaMallocManaged(&leaf_parents, sizeof(uint32_t) * n_count);
        cudaMallocManaged(&sorted_to_original, sizeof(uint32_t) * n_count);

        uint32_t internal_count = n_count - 1;

        cudaMallocManaged(&bintrie_internals, sizeof(BintrieInternal) * internal_count);
        cudaMallocManaged(&node_coms, sizeof(float3) * internal_count);
        cudaMallocManaged(&node_masses, sizeof(float) * internal_count);
    }

    ~BarnesHutInterData() {
        cudaFree(encodings);
        cudaFree(leaf_parents);
        cudaFree(sorted_to_original);

        cudaFree(bintrie_internals);
        cudaFree(node_coms);
        cudaFree(node_masses);
    }
};

#endif //NBODY_BODY_DATA_H
