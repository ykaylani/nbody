#include <chrono>
#include <format>
#include <fstream>
#include <iostream>

#include <filesystem>

#include "src/data/body_data.h"
#include "src/data/scene_desc.h"
#include "src/distributions.h"

__global__ void Run(float3* positions, float3* velocities, float3* positions2, float3* velocities2, const float* __restrict__ inv_masses, uint32_t bodyCount, float dt, uint32_t step, float softening, bool equalMass);

void CSVSave(std::ofstream& file, float3* dataPos, float3* dataVel, int count, float current_time) {
    for (int i = 0; i < count; i++) {
        file << current_time << ","
            << i << ","
            << dataPos[i].x << ","
            << dataPos[i].y << ","
            << dataPos[i].z << ","
            << dataVel[i].x << ","
            << dataVel[i].y << ","
            << dataVel[i].z << "\n";
    }
}

int main() {
    std::cout << "Initializing" << std::endl;
    SceneDescription scene_desc {
        std::make_unique<RandomCube>(15000.0f),
        45000,
        1000,
        0.02f,
        4.0f,

        true,
        false,
        false,
        "D:/env/empi/NBodyData/17_7_26/2"
    };

    uint16_t block_threads = 256;
    uint32_t blocks_grid = (scene_desc.body_count_ + block_threads - 1) / block_threads;
    size_t shared_memory_bytes = block_threads * (sizeof(float3) + sizeof(float));

    BodyData body_data {
        scene_desc.body_count_,
        scene_desc.equal_mass_,
    };

    scene_desc.distribution_->ApplyPositions(body_data.positions_1_, scene_desc.body_count_);
    scene_desc.distribution_->ApplyVelocities(body_data.velocities_1_, scene_desc.body_count_);

    for (int i = 0; i < scene_desc.body_count_; i++) {
        if (!scene_desc.equal_mass_) { body_data.masses_[i] = 5e17f; } else { body_data.masses_[0] = 5e17f; }
    }

    std::filesystem::path export_data_path;

    if (scene_desc.export_data_) {
        export_data_path = scene_desc.data_directory_.value_or(".");

        std::ofstream output_file(export_data_path / "simulation_results_0.csv");
        output_file << "time,body_id,x,y,z,velx,vely,velz\n";

        CSVSave(output_file, body_data.positions_1_, body_data.velocities_1_, scene_desc.body_count_, 0.0f);
    }

    std::cout << "Initialization complete" << std::endl;

    std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();

    for (int i = 0; i < scene_desc.steps_; i++) {

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
        } else { cudaDeviceSynchronize(); }

        if (scene_desc.export_data_) {
            std::ofstream outfile(export_data_path / std::format("simulation_results_{}.csv", i + 1));
            outfile << "time,body_id,x,y,z,velx,vely,velz\n";

            if (i % 2 == 0) {
                CSVSave(outfile, body_data.positions_2_, body_data.velocities_2_, scene_desc.body_count_, scene_desc.dt_ * (i + 1));
            } else {
                CSVSave(outfile, body_data.positions_1_, body_data.velocities_1_, scene_desc.body_count_, scene_desc.dt_ * (i + 1));
            }
        }

    }

    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
    std::cout << "Execute time = " << std::chrono::duration_cast<std::chrono::microseconds>(end - begin).count() << std::endl;
    std::cout << "Complete." << std::endl;

    return 0;
}
