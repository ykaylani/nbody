#ifndef NBODY_ALL_PAIRS_H
#define NBODY_ALL_PAIRS_H

__global__ void AllPairsKernel(float4* positions_src, float4* velocities_src, float4* positions_dst, float4* velocities_dst, const uint32_t bodyCount, const float dt, const float softening);

#endif //NBODY_ALL_PAIRS_H