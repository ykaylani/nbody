#include <chrono>
#include <format>
#include <iostream>
#include <filesystem>

#include "src/data/body_data.h"
#include "src/data/scene_desc.h"

#include "src/distributions.h"
#include "src/exporters.h"

__global__ void Run(float3* positions_src, float3* velocities_src, float3* positions_dst, float3* velocities_dst, const float* __restrict__ masses, const uint32_t bodyCount, const float dt, const float softening);

int main() {
    std::cout << "Initializing" << std::endl;

    SceneDescription scene_desc {
        .distribution_ = std::make_unique<Distributions::Plummer>(15000.0f, 2800.0f),
        .exporter_ = nullptr, //std::make_unique<Exporters::XDMF>(".", "simulation_data", "simulation_data_org"),

        .body_count_ = 45000,
        .steps_ = 1000,
        .dt_ = 0.02f,
        .softening_ = 4.0f,

        .cuda_err_ = false,
    };

    uint16_t block_threads = 256;
    uint32_t blocks_grid = (scene_desc.body_count_ + block_threads - 1) / block_threads;
    size_t shared_memory_bytes = block_threads * (sizeof(float3) + sizeof(float));

    BodyData body_data { scene_desc.body_count_ };
    scene_desc.distribution_->Apply(body_data.positions_1_, body_data.velocities_1_, body_data.masses_, 1e17f, scene_desc.body_count_);

    const bool save_data = scene_desc.exporter_ != nullptr;

    if (save_data) {
        scene_desc.exporter_->Initialize();
        scene_desc.exporter_->Export(body_data.positions_1_, body_data.velocities_1_, body_data.masses_, scene_desc.body_count_, 0, scene_desc.dt_);
    }

    float3* positions_source = body_data.positions_1_;
    float3* velocities_source = body_data.velocities_1_;
    float3* positions_destination = body_data.positions_2_;
    float3* velocities_destination = body_data.velocities_2_;

    std::cout << "Initialization complete" << std::endl;
    std::chrono::steady_clock::time_point begin_hotloop = std::chrono::steady_clock::now();

    for (int i = 0; i < scene_desc.steps_; i++) {

        bool synced = false;
        Run<<<blocks_grid, block_threads, shared_memory_bytes>>>(positions_source, velocities_source, positions_destination, velocities_destination, body_data.masses_, scene_desc.body_count_, scene_desc.dt_, scene_desc.softening_);

        if (scene_desc.cuda_err_) {
            cudaError_t launch_err = cudaGetLastError();
            if (launch_err != cudaSuccess) {
                std::cerr << "Kernel launch failed: " << cudaGetErrorString(launch_err) << std::endl;
                return -1;
            }

            cudaError_t sync_err = cudaDeviceSynchronize();
            if (sync_err != cudaSuccess) {
                std::cerr << "Kernel execution failed: " << cudaGetErrorString(sync_err) << std::endl;
                return -1;
            }

            synced = true;
        }

        if (save_data) {

            if (!synced) { cudaDeviceSynchronize(); }
            scene_desc.exporter_->Export(positions_destination, velocities_destination, body_data.masses_, scene_desc.body_count_, i + 1, scene_desc.dt_);
        }

        std::swap(positions_source, positions_destination);
        std::swap(velocities_source, velocities_destination);
    }

    cudaDeviceSynchronize();
    if (save_data) { scene_desc.exporter_->Finalize(); }

    std::chrono::steady_clock::time_point end_hotloop = std::chrono::steady_clock::now();
    std::cout << "Execute time = " << std::chrono::duration_cast<std::chrono::microseconds>(end_hotloop - begin_hotloop).count() << std::endl;
    std::cout << "Complete." << std::endl;

    return 0;
}
