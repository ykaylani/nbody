#ifndef NBODY_ENERGY_CALCULATOR_H
#define NBODY_ENERGY_CALCULATOR_H

#include <memory>
#include <thrust/execution_policy.h>
#include <thrust/reduce.h>

#include "../data/body_data.h"
#include "../cuda_solvers/mechanical_energy.cuh"

struct EnergyMetrics {
    float kinetic = 0.0f;
    float potential = 0.0f;

    float Total() const { return kinetic + potential; }
};

class EnergyCalculator {
    std::unique_ptr<EnergyCalculationData> energy_data_;
    uint32_t body_count_;
    float softening_;

public:
    EnergyCalculator(uint32_t body_count, float softening) : body_count_(body_count), softening_(softening), energy_data_(std::make_unique<EnergyCalculationData>(body_count)) {}

    EnergyMetrics Calculate(const BodyData& body_data) {
        uint32_t blocks_grid = (body_count_ + block_threads - 1) / block_threads;
        size_t shared_memory_bytes = block_threads * sizeof(float4);

        KineticEnergyArray<<<blocks_grid, block_threads>>>(body_data.positions_1, body_data.velocities_1, energy_data_->kinetics, body_count_);
        PotentialEnergyArray<<<blocks_grid, block_threads, shared_memory_bytes>>>(body_data.positions_1, energy_data_->potentials, body_count_, softening_);

        EnergyMetrics metrics;
        metrics.kinetic = thrust::reduce(thrust::device, energy_data_->kinetics, energy_data_->kinetics + body_count_);
        metrics.potential = thrust::reduce(thrust::device, energy_data_->potentials, energy_data_->potentials + body_count_);

        return metrics;
    }
};

#endif // NBODY_ENERGY_CALCULATOR_H