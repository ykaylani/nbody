#ifndef NBODY_BODY_DATA_H
#define NBODY_BODY_DATA_H

#include <cuda_runtime.h>

struct BodyData { // when step is even, output is buffers (two). buffers (one) are output when step is odd.
    float3* positions_1 = nullptr;
    float3* velocities_1 = nullptr;

    float3* positions_2 = nullptr;
    float3* velocities_2 = nullptr;

    float* masses = nullptr;

    BodyData(uint32_t nCount) {
        cudaMallocManaged(&positions_1, sizeof(float3) * nCount);
        cudaMallocManaged(&velocities_1, sizeof(float3) * nCount);

        cudaMallocManaged(&positions_2, sizeof(float3) * nCount);
        cudaMallocManaged(&velocities_2, sizeof(float3) * nCount);

        cudaMallocManaged(&masses, sizeof(float) * nCount);
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

#endif //NBODY_BODY_DATA_H
