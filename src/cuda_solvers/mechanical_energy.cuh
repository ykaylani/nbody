#ifndef NBODY_MECHANICAL_ENERGY_CUH
#define NBODY_MECHANICAL_ENERGY_CUH

__global__ void KineticEnergyArray(const float4* __restrict__ positions, const float4* __restrict__ velocities, float* kinetic_memory, const uint32_t body_count);
__global__ void PotentialEnergyArray(const float4* __restrict__ positions, float* potential_memory, const uint32_t body_count, const float softening);

#endif //NBODY_MECHANICAL_ENERGY_CUH