#ifndef NBODY_SOLVERS_H
#define NBODY_SOLVERS_H

#include <chrono>
#include <iostream>
#include <thrust/sort.h>

#include "../data/body_data.h"
#include "../data/scene_settings.h"

#include "../cuda_solvers/all_pairs.cuh"
#include "../cuda_solvers/barnes_hut.cuh"

constexpr uint16_t block_threads = 256;

struct Solver {
    SceneSettings scene_settings;

    virtual void Propagate(BodyData& body_data, float dt) {

        bool synced = false;

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
            synced = true;
            if (sync_err != cudaSuccess) {
                std::cerr << "Kernel execution failed: " << cudaGetErrorString(sync_err) << std::endl;
                return;
            }
        }

        if (scene_settings.hotloop_time) {
            if (!synced) cudaDeviceSynchronize();
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

    struct BarnesHut : Solver {
        BarnesHutInterData inter_data;
        float opening_angle_criterion;
        int32_t leaf_bucket_size;

        void Solve(BodyData& body_data, float dt) override {
            uint32_t body_count = scene_settings.body_count;
            uint32_t blocks_grid = (body_count + block_threads - 1) / block_threads;

            EncodeF3A<<<blocks_grid, block_threads>>>(
                body_data.positions_1,
                inter_data.encodings,
                body_count);

            thrust::sequence(
                thrust::device,
                inter_data.sorted_to_original,
                inter_data.sorted_to_original + body_count);

            thrust::sort_by_key(
                thrust::device,
                inter_data.encodings,
                inter_data.encodings + body_count,
                inter_data.sorted_to_original);

            BuildKarrasTrie<<<blocks_grid, block_threads>>>(
                inter_data.encodings,
                inter_data.bintrie_internals,
                inter_data.leaf_parents,
                body_count);

            cudaMemsetAsync(inter_data.node_flags, 0, sizeof(int32_t) * (body_count - 1));

            CalculateCOMs<<<blocks_grid, block_threads>>>(
                inter_data.bintrie_internals,
                inter_data.node_flags,
                inter_data.node_coms,
                inter_data.node_masses,
                inter_data.node_bounds_min,
                inter_data.node_bounds_max,
                inter_data.sorted_to_original,
                inter_data.leaf_parents,
                body_data.positions_1,
                body_data.masses,
                body_count);

            CalculateForces<<<blocks_grid, block_threads>>>(
                body_data.positions_1,
                body_data.velocities_1,
                body_data.positions_2,
                body_data.velocities_2,
                body_data.masses,
                inter_data.bintrie_internals,
                inter_data.node_masses,
                inter_data.node_coms,
                inter_data.node_bounds_min,
                inter_data.node_bounds_max,
                inter_data.sorted_to_original,
                opening_angle_criterion,
                scene_settings.softening,
                dt,
                body_count,
                leaf_bucket_size);

            std::swap(body_data.positions_1, body_data.positions_2);
            std::swap(body_data.velocities_1, body_data.velocities_2);
        }

        BarnesHut(const SceneSettings& settings, float opening_angle_criterion, int32_t leaf_bucket_size = 32) : Solver(settings), inter_data(scene_settings.body_count), opening_angle_criterion(opening_angle_criterion), leaf_bucket_size(leaf_bucket_size) {}
    };
}

#endif //NBODY_SOLVERS_H
