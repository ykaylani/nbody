#include <chrono>
#include <format>
#include <fstream>
#include <iostream>
#include <windows.h>
#include <psapi.h>

#include "src/data/body_data.h"
#include "src/data/scene_desc.h"

__global__ void Run(float3* positions, float3* velocities, float3* positions2, float3* velocities2, float* inv_masses, uint32_t bodyCount, float dt, uint32_t step, bool equalMass);

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

size_t getMemoryUsage() {
    PROCESS_MEMORY_COUNTERS pmc;
    GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc));
    return pmc.WorkingSetSize;
}

int main() {
    std::cout << "Initializing" << std::endl;
    int block_threads = 256;

    SceneDescription scene_desc {
        45000, true, 100, 0.02
    };

    int blocks_grid = (scene_desc.bodyCount + block_threads - 1) / block_threads;

    BodyData bodyData {
        scene_desc.bodyCount,
        scene_desc.equalMass,
    };

    for (int i = 0; i < scene_desc.bodyCount; i++) {
        bodyData.positions_1_[i] = {(float)(rand() % 10000 - 100), (float)(rand() % 10000 - 100), (float)(rand() % 10000 - 100)};
        bodyData.velocities_1_[i] = {0.0f, 0.0f, 0.0f};
        //bodyData.inverse_masses_[i] = 1.0f / 5e8f;
    }

    bodyData.inverse_masses_[0] = 1.0f / 5e8f;

    //std::ofstream output_file("D:/env/empi/NBodyData/15_7_26/1/simulation_results_0.csv");
    //output_file << "time,body_id,x,y,z,velx,vely,velz\n";

    //CSVSave(output_file, bodyData.positions_1_, bodyData.velocities_1_, scene_desc.bodyCount, 0.0f);

    std::cout << "Initialization Complete. Working Memory: " << getMemoryUsage() << " bytes" << std::endl;

    std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();

    for (int i = 0; i < scene_desc.steps; i++) {
        //std::ofstream outfile(std::format("D:/env/empi/NBodyData/15_7_26/1/simulation_results_{}.csv", i));
        //outfile << "time,body_id,x,y,z,velx,vely,velz\n";

        Run<<<blocks_grid, block_threads>>>(bodyData.positions_1_, bodyData.velocities_1_, bodyData.positions_2_, bodyData.velocities_2_, bodyData.inverse_masses_, scene_desc.bodyCount, scene_desc.dt, i, scene_desc.equalMass);

        /*cudaError_t launch_err = cudaGetLastError();
        if (launch_err != cudaSuccess) {
            std::cerr << "Kernel launch failed: " << cudaGetErrorString(launch_err) << std::endl;
            return -1;
        }

        cudaError_t sync_err = cudaDeviceSynchronize();
        if (sync_err != cudaSuccess) {
            std::cerr << "Kernel execution failed: " << cudaGetErrorString(sync_err) << std::endl;
            return -1;
        }*/

        cudaDeviceSynchronize();
        /*if (i % 2 == 0) {
            CSVSave(outfile, bodyData.positions_2_, bodyData.velocities_2_, scene_desc.bodyCount, scene_desc.dt * (i + 1));
        } else {
            CSVSave(outfile, bodyData.positions_1_, bodyData.velocities_1_, scene_desc.bodyCount, scene_desc.dt * (i + 1));
        }*/
    }

    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
    std::cout << "Execute time = " << std::chrono::duration_cast<std::chrono::microseconds>(end - begin).count() << std::endl;
    std::cout << "Complete." << std::endl;

    return 0;
}
