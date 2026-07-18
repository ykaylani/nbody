#ifndef NBODY_CUDA_SOLVERS_H
#define NBODY_CUDA_SOLVERS_H

__global__ void AllPairsKernel(float3* positions_src, float3* velocities_src, float3* positions_dst, float3* velocities_dst, const float* __restrict__ masses, const uint32_t bodyCount, const float dt, const float softening);

#endif //NBODY_CUDA_SOLVERS_H