#ifndef NBODY_SIMULATION_CONTROLLER_H
#define NBODY_SIMULATION_CONTROLLER_H

#include <chrono>
#include <iostream>

#include "../strats/solvers.h"
#include "../data/body_data.h"
#include "../data/scene_settings.h"
#include "../cuda_utils/cuda_errchk.cuh"

class SimulationController
{
    SceneSettings scene_settings;
    double total_hotloop = 0.0;

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
    }

    virtual bool GetTreeBounds(Solver* solver, const float4** bounds_min, const float4** bounds_max, uint32_t* node_count) {
        return solver->GetTreeBounds(bounds_min, bounds_max, node_count);
    }
};

#endif // NBODY_SIMULATION_CONTROLLER_H