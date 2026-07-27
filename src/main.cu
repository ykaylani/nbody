#include <chrono>
#include <iostream>
#include <string>

#include "data/body_data.h"
#include "data/scene_desc.h"

#include "strats/distributions.h"
#include "strats/exporters.h"

#include "loop/config_parse.h"
#include "loop/simulation_controller.h"

int main(int argc, char** argv) {
    std::cout << "Initializing" << std::endl;
    std::string config_path = "../config.ini";

    if (argc > 1) {
        std::string config_dir = argv[1];
        if (!config_dir.empty() && config_dir.back() != '/' && config_dir.back() != '\\') config_dir += "/";
        config_path = config_dir + "config.ini";
    } else {
        throw std::runtime_error("No config.ini provided");
    }

    std::cout << "Reading config from " << config_path << std::endl;
    auto config = ParseINI(config_path);

    SceneSettings scene_settings {
        .body_count = (uint32_t)std::stoi(config["settings.physical.body_count"]),
        .steps = (uint32_t)std::stoi(config["settings.physical.steps"]),
        .dt = std::stof(config["settings.physical.dt"]),
        .softening = std::stof(config["settings.physical.softening"]),

        .cuda_err = ParseBoolean(config["settings.execution.cuda_errchk"]),
        .hotloop_time = ParseBoolean(config["settings.execution.hotloop_time"]),
        .total_hotloop_time = ParseBoolean(config["settings.execution.total_hotloop_time"]),
        .mechanical_energy = ParseBoolean(config["settings.execution.mechanical_energy"]),
    };

    SceneDescription scene_description;

    if (config["solver.method"] == "all_pairs") {
        scene_description.solver = std::make_unique<Solvers::AllPairs>(scene_settings);
    } else if (config["solver.method"] == "barnes_hut") {
        int leaf_size = 32;

        float theta = std::stof(config["solver.barnes_hut.acceptance_criterion"]);
        if (!config["solver.barnes_hut.leaf_bucket_size"].empty()) leaf_size = std::stoi(config["solver.barnes_hut.leaf_bucket_size"]);

        scene_description.solver = std::make_unique<Solvers::BarnesHut>(scene_settings, theta, leaf_size);
    }

    if (config["distribution.method"] == "random_cube") {
        float size = std::stof(config["distribution.random_cube.size"]);
        scene_description.distribution = std::make_unique<Distributions::RandomCube>(scene_settings, size);
    } else if (config["distribution.method"] == "random_sphere") {
        float radius = std::stof(config["distribution.random_sphere.radius"]);
        scene_description.distribution = std::make_unique<Distributions::RandomSphere>(scene_settings, radius);
    } else if (config["distribution.method"] == "plummer") {
        float max_r = std::stof(config["distribution.plummer.max_radius"]);
        float scale_r = std::stof(config["distribution.plummer.scale_radius"]);
        scene_description.distribution = std::make_unique<Distributions::Plummer>(scene_settings, max_r, scale_r);
    }

    std::string exp_method = config["exporter.method"];
    std::string dir = config["exporter.data_directory"];
    std::string file = config["exporter.data_file_name"];

    if (exp_method == "xdmf") {
        std::string meta_out = config["exporter.xdmf.metadata_out_name"];
        scene_description.exporter = std::make_unique<Exporters::XDMF>(scene_settings, dir, file, meta_out);
    } else if (exp_method == "csv") {
        scene_description.exporter = std::make_unique<Exporters::CSV>(scene_settings, dir, file);
    } else if (exp_method == "vtp") {
        scene_description.exporter = std::make_unique<Exporters::VTP>(scene_settings, dir, file);
    } else {
        scene_description.exporter = nullptr;
    }

    BodyData body_data { scene_settings.body_count };

    float base_mass = std::stof(config["settings.physical.base_mass"]);
    scene_description.distribution->Apply(body_data.positions_1, body_data.velocities_1, base_mass);

    const bool save_data = scene_description.exporter != nullptr;

    if (save_data) {
        scene_description.exporter->Initialize();
        scene_description.exporter->Export(body_data.positions_1, body_data.velocities_1, 0, scene_settings.dt);
    }

    std::cout << "Initialization complete" << std::endl;

    SimulationController simulation_controller(scene_settings);

    for (int i = 0; i < scene_settings.steps; i++) {
        simulation_controller.Propagate(*scene_description.solver, body_data, scene_settings.dt);
        cudaDeviceSynchronize();

        if (save_data) {
            scene_description.exporter->Export(body_data.positions_1, body_data.velocities_1, i + 1, scene_settings.dt);
        }
    }

    cudaDeviceSynchronize();
    if (save_data) scene_description.exporter->Finalize();

    std::cout << "Complete." << std::endl;
    return 0;
}