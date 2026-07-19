#ifndef NBODY_BARNES_HUT_H
#define NBODY_BARNES_HUT_H

__global__ void EncodeF3A(float3* encode, uint64_t* out, uint32_t count);
__global__ void BuildKarrasTrie(const uint64_t* __restrict__ codes, BintrieInternal* internal_nodes, uint32_t* leaf_parents, const int32_t body_count);

#endif //NBODY_BARNES_HUT_H