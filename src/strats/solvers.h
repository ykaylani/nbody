#ifndef NBODY_SOLVERS_H
#define NBODY_SOLVERS_H

#include <chrono>
#include <iostream>

#include "../data/body_data.h"
#include "../data/scene_settings.h"

#include "../cuda_solvers/all_pairs.cuh"

struct Solver {
    SceneSettings scene_settings;

    virtual void Propagate(BodyData& body_data, float dt) {

        std::chrono::steady_clock::time_point begin_hotloop;
        if (scene_settings.hotloop_time) begin_hotloop = std::chrono::steady_clock::now();

        Solve(body_data, dt);

        if (scene_settings.cuda_err) {
            cudaError_t launch_err = cudaGetLastError();
            if (launch_err != cudaSuccess) {
                std::cerr << "Kernel launch failed: " << cudaGetErrorString(launch_err) << std::endl;
                return;
            }

            cudaError_t sync_err = cudaDeviceSynchronize();
            if (sync_err != cudaSuccess) {
                std::cerr << "Kernel execution failed: " << cudaGetErrorString(sync_err) << std::endl;
                return;
            }
        }

        if (scene_settings.hotloop_time) {
            std::chrono::steady_clock::time_point end_hotloop = std::chrono::steady_clock::now();
            std::cout << "Execute time = " << std::chrono::duration_cast<std::chrono::microseconds>(end_hotloop - begin_hotloop).count() << " μs" << std::endl;
        }

    }

    virtual void Solve(BodyData& body_data, float dt) = 0;

    Solver(const SceneSettings& settings) : scene_settings(settings) {}
    virtual ~Solver() = default;
};

namespace Solvers {

    struct AllPairs : Solver {

        void Solve(BodyData& body_data, float dt) override {

            int body_count = scene_settings.body_count;

            uint16_t block_threads = 256;
            uint32_t blocks_grid = (body_count + block_threads - 1) / block_threads;
            size_t shared_memory_bytes = block_threads * (sizeof(float3) + sizeof(float));

            AllPairsKernel<<<blocks_grid, block_threads, shared_memory_bytes>>>(
                body_data.positions_1,
                body_data.velocities_1,
                body_data.positions_2,
                body_data.velocities_2,
                body_data.masses,
                body_count,
                dt,
                scene_settings.softening);

            std::swap(body_data.positions_1, body_data.positions_2);
            std::swap(body_data.velocities_1, body_data.velocities_2);
        }

        using Solver::Solver;
    };
}

#endif //NBODY_SOLVERS_H
