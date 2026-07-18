#include <chrono>
#include <format>
#include <iostream>

#include "data/body_data.h"
#include "data/scene_desc.h"

#include "strats/distributions.h"
#include "strats/exporters.h"

int main() {
    std::cout << "Initializing" << std::endl;

    SceneSettings scene_settings {
        .body_count = 45000,
        .steps = 1000,
        .dt = 0.02,
        .softening = 4.0f,

        .cuda_err = false,
        .hotloop_time = false,
    };

    SceneDescription scene_description {
        .solver = std::make_unique<Solvers::AllPairs>(scene_settings),
        .distribution = std::make_unique<Distributions::RandomCube>(scene_settings, 15000.0f),
        .exporter = std::make_unique<Exporters::XDMF>(scene_settings, ".", "simulation_data", "simulation_data_org"),
    };

    BodyData body_data { scene_settings.body_count };
    scene_description.distribution->Apply(body_data.positions_1, body_data.velocities_1, body_data.masses, 1e17f);

    const bool save_data = scene_description.exporter != nullptr;

    if (save_data) {
        scene_description.exporter->Initialize();
        scene_description.exporter->Export(body_data.positions_1, body_data.velocities_1, body_data.masses, 0, scene_settings.dt);
    }

    std::cout << "Initialization complete" << std::endl;

    for (int i = 0; i < scene_settings.steps; i++) {

        scene_description.solver->Propagate(body_data, scene_settings.dt);
        cudaDeviceSynchronize();

        if (save_data) {
            scene_description.exporter->Export(body_data.positions_1, body_data.velocities_1, body_data.masses, i + 1, scene_settings.dt);
        }
    }

    cudaDeviceSynchronize();
    if (save_data) { scene_description.exporter->Finalize(); }

    std::cout << "Complete." << std::endl;

    return 0;
}
