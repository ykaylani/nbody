#ifndef NBODY_SIMULATION_CONTROLLER_H
#define NBODY_SIMULATION_CONTROLLER_H

#include <chrono>
#include <iostream>
#include <memory>

#include <thrust/execution_policy.h>
#include <thrust/reduce.h>

#include "../strats/solvers.h"

#include "../data/body_data.h"
#include "../data/scene_settings.h"

#include "../cuda_solvers/mechanical_energy.cuh"

#include "../cuda_utils/cuda_errchk.cuh"

class SimulationController
{
    SceneSettings scene_settings;
    double total_hotloop = 0.0;

    float last_mechanical_energy = 0.0f;
    std::unique_ptr<EnergyCalculationData> energy_data = nullptr;

    void CUDAErrorCheck(bool& synced) {
        cudaErrchk(cudaGetLastError());
        cudaErrchk(cudaDeviceSynchronize());
        synced = true;
    }

    void RecordHotloopTime(std::chrono::steady_clock::time_point begin_hotloop) {
        std::chrono::steady_clock::time_point end_hotloop = std::chrono::steady_clock::now();

        if (scene_settings.total_hotloop_time) {
            total_hotloop += std::chrono::duration<double>(end_hotloop - begin_hotloop).count();
        }

        if (scene_settings.hotloop_time) {
            std::cout << "Hotloop Time: " << std::chrono::duration_cast<std::chrono::seconds>(end_hotloop - begin_hotloop).count() << " s" << std::endl;
        }
    }

    float CalculateMechanicalEnergy(BodyData& body_data) {
        if (!energy_data) energy_data = std::make_unique<EnergyCalculationData>(scene_settings.body_count);

        uint32_t body_count = scene_settings.body_count;
        uint32_t blocks_grid = (body_count + block_threads - 1) / block_threads;
        size_t shared_memory_bytes = block_threads * sizeof(float4);

        KineticEnergyArray<<<blocks_grid, block_threads>>>(body_data.positions_1, body_data.velocities_1, energy_data->kinetics, body_count);
        PotentialEnergyArray<<<blocks_grid, block_threads, shared_memory_bytes>>>(body_data.positions_1, energy_data->potentials, body_count, scene_settings.softening);

        float kinetic = thrust::reduce(thrust::device, energy_data->kinetics, energy_data->kinetics + body_count);
        float potential = thrust::reduce(thrust::device, energy_data->potentials, energy_data->potentials + body_count);

        return kinetic + potential;
    }

public:
    explicit SimulationController(const SceneSettings& settings) : scene_settings(settings) {}

    ~SimulationController() {
        if (scene_settings.total_hotloop_time) {
            std::cout << "Total Hotloop Time: " << total_hotloop << " s" << std::endl;
        }
    }

    void Propagate(Solver& solver, BodyData& body_data, float dt) {

        bool synced = false;
        bool track_time = scene_settings.hotloop_time || scene_settings.total_hotloop_time;

        std::chrono::steady_clock::time_point begin_hotloop;
        if (track_time) begin_hotloop = std::chrono::steady_clock::now();

        solver.Solve(body_data, dt);

        if (scene_settings.cuda_err) CUDAErrorCheck(synced);

        if (track_time) {
            if (!synced) cudaDeviceSynchronize();
            RecordHotloopTime(begin_hotloop);
        }

        if (scene_settings.mechanical_energy)
        {
            cudaDeviceSynchronize();
            last_mechanical_energy = CalculateMechanicalEnergy(body_data);
        }
    }

    float LastMechanicalEnergy() const { return last_mechanical_energy; }

};

#endif //NBODY_SIMULATION_CONTROLLER_H