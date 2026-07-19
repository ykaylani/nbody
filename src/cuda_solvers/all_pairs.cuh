#ifndef NBODY_ALL_PAIRS_H
#define NBODY_ALL_PAIRS_H

__global__ void AllPairsKernel(float3* positions_src, float3* velocities_src, float3* positions_dst, float3* velocities_dst, const float* __restrict__ masses, const uint32_t bodyCount, const float dt, const float softening);

#endif //NBODY_ALL_PAIRS_H