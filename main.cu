#include <chrono>
#include <format>
#include <iostream>

#include <filesystem>

#include "src/data/body_data.h"
#include "src/data/scene_desc.h"

#include "src/distributions.h"
#include "src/exporters.h"

__global__ void Run(float3* positions, float3* velocities, float3* positions2, float3* velocities2, const float* __restrict__ inv_masses, uint32_t bodyCount, float dt, uint32_t step, float softening, bool equalMass);

int main() {
    std::cout << "Initializing" << std::endl;

    SceneDescription scene_desc {
        .distribution_ = std::make_unique<Distributions::RandomCube>(15000.0f),
        .exporter_ = std::make_unique<Exporters::XDMF>(".", "simulation_data", "simulation_data_org"),

        .body_count_ = 45000,
        .steps_ = 10000,
        .dt_ = 0.02f,
        .softening_ = 4.0f,

        .equal_mass_ = true,
        .cuda_err_ = false,
    };

    uint16_t block_threads = 256;
    uint32_t blocks_grid = (scene_desc.body_count_ + block_threads - 1) / block_threads;
    size_t shared_memory_bytes = block_threads * (sizeof(float3) + sizeof(float));

    BodyData body_data { scene_desc.body_count_, scene_desc.equal_mass_ };
    scene_desc.distribution_->ApplyPositions(body_data.positions_1_, scene_desc.body_count_);
    scene_desc.distribution_->ApplyVelocities(body_data.velocities_1_, scene_desc.body_count_);
    scene_desc.distribution_->ApplyMasses(body_data.masses_, scene_desc.body_count_, 5e17f, scene_desc.equal_mass_);

    const bool save_data = scene_desc.exporter_ != nullptr;
    if (save_data) {
        scene_desc.exporter_->Initialize();
        scene_desc.exporter_->Export(body_data.positions_1_, body_data.velocities_1_, body_data.masses_, scene_desc.body_count_, 0, scene_desc.dt_, scene_desc.equal_mass_);
    }

    std::cout << "Initialization complete" << std::endl;
    std::chrono::steady_clock::time_point begin_hotloop = std::chrono::steady_clock::now();

    for (int i = 0; i < scene_desc.steps_; i++) {

        bool synced = false;
        Run<<<blocks_grid, block_threads, shared_memory_bytes>>>(body_data.positions_1_, body_data.velocities_1_, body_data.positions_2_, body_data.velocities_2_, body_data.masses_, scene_desc.body_count_, scene_desc.dt_, i, scene_desc.softening_, scene_desc.equal_mass_);

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
            if (i % 2 == 0) { scene_desc.exporter_->Export(body_data.positions_2_, body_data.velocities_2_, body_data.masses_, scene_desc.body_count_, i + 1, scene_desc.dt_, scene_desc.equal_mass_); }
            else { scene_desc.exporter_->Export(body_data.positions_1_, body_data.velocities_1_, body_data.masses_, scene_desc.body_count_, i + 1, scene_desc.dt_, scene_desc.equal_mass_); }
        }
    }

    cudaDeviceSynchronize();
    if (save_data) { scene_desc.exporter_->Finalize(); }

    std::chrono::steady_clock::time_point end_hotloop = std::chrono::steady_clock::now();
    std::cout << "Execute time = " << std::chrono::duration_cast<std::chrono::microseconds>(end_hotloop - begin_hotloop).count() << std::endl;
    std::cout << "Complete." << std::endl;


    return 0;
}
