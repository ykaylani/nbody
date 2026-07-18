#ifndef NBODY_BODY_DATA_H
#define NBODY_BODY_DATA_H

#include <cuda_runtime.h>

struct BodyData { // when step is even, output is buffers (two). buffers (one) are output when step is odd.
    float3* positions_1_ = nullptr;
    float3* velocities_1_ = nullptr;

    float3* positions_2_ = nullptr;
    float3* velocities_2_ = nullptr;

    float* masses_ = nullptr;

    BodyData(uint32_t nCount) {
        cudaMallocManaged(&positions_1_, sizeof(float3) * nCount);
        cudaMallocManaged(&velocities_1_, sizeof(float3) * nCount);

        cudaMallocManaged(&positions_2_, sizeof(float3) * nCount);
        cudaMallocManaged(&velocities_2_, sizeof(float3) * nCount);

        cudaMallocManaged(&masses_, sizeof(float) * nCount);
    }

    ~BodyData() {
        cudaFree(positions_1_);
        cudaFree(velocities_1_);

        cudaFree(positions_2_);
        cudaFree(velocities_2_);

        cudaFree(masses_);
    }

    BodyData(const BodyData&) = delete;
    BodyData& operator=(const BodyData&) = delete;
};

#endif //NBODY_BODY_DATA_H
