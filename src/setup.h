#ifndef NBODY_SETUP_H
#define NBODY_SETUP_H

#include <string>

#include "data/scene_description.h"
#include "loop/config_parse.h"
#include "data/scene_settings.h"
#include "strats/distributions.h"
#include "visualization/visualizer.h"
#include "strats/energy/energy_exporters.h"


using ConfigMap = std::unordered_map<std::string, std::string>;

inline std::string FindConfiguration(int argc, char** argv) {
    std::string config_path;

    if (argc > 1) {
        std::string config_dir = argv[1];
        if (!config_dir.empty() && config_dir.back() != '/' && config_dir.back() != '\\') config_dir;
        config_path = config_dir;
    } else {

        throw std::runtime_error("No config.ini provided");
    }

    std::cout << "Reading config from " << config_path << std::endl;
    return config_path;
}

inline SceneSettings BuildSettings(ConfigMap& config) {
    return {
        .body_count = static_cast<uint32_t>(std::stoi(config["settings.physical.body_count"])),
        .steps = static_cast<uint32_t>(std::stoi(config["settings.physical.steps"])),
        .dt = std::stof(config["settings.physical.dt"]),
        .softening = std::stof(config["settings.physical.softening"]),

        .cuda_err = ParseBoolean(config["settings.execution.cuda_errchk"]),
        .hotloop_time = ParseBoolean(config["settings.execution.hotloop_time"]),
        .total_hotloop_time = ParseBoolean(config["settings.execution.total_hotloop_time"]),

        .visualize = ParseBoolean(config["settings.visualization.visualize"]),
        .visualize_tree = ParseBoolean(config["settings.visualization.visualize_tree"]),
        .min_node_extent = std::stof(config["settings.visualization.min_node_extent"]),
        .n_frames_snap = static_cast<uint32_t>(std::stof(config["settings.visualization.n_frames_snap"])),
    };
}

inline void InitializeVisualizer(Visualizer& visualizer, const SceneSettings& scene_settings) {
    if (scene_settings.visualize) {
        if (!visualizer.init(scene_settings.body_count, 1000000)) {
            throw std::runtime_error("Failed to initialize visualizer");
        }
    }
}

inline SceneDescription BuildSceneDescription(SceneSettings& scene_settings, ConfigMap& config) {
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
    } else if (config["distribution.method"] == "kuzmin") {
        float max_r = std::stof(config["distribution.kuzmin.max_radius"]);
        float scale_r = std::stof(config["distribution.kuzmin.scale_radius"]);
        float scale_h = std::stof(config["distribution.kuzmin.scale_height"]);
        scene_description.distribution = std::make_unique<Distributions::Kuzmin>(scene_settings, max_r, scale_r, scale_h);
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

    std::string eexp_method = config["exporter.energy.method"];
    std::string edir = config["exporter.energy.data_directory"];
    std::string efile = config["exporter.energy.data_file_name"];

    if (eexp_method == "csv") {
        scene_description.energy_exporter = std::make_unique<EnergyExporters::CSV>(scene_settings, edir, efile);
    } else {
        scene_description.energy_exporter = nullptr;
    }

    return scene_description;
}

inline std::pair<bool, bool> PopulateSceneDescription(SceneDescription& scene_description, ConfigMap& config, BodyData& body_data, SceneSettings& scene_settings) {

    float base_mass = std::stof(config["settings.physical.base_mass"]);
    scene_description.distribution->Apply(body_data.positions_1, body_data.velocities_1, base_mass);

    const bool save_data = scene_description.exporter != nullptr;

    if (save_data) {
        scene_description.exporter->Initialize();
        scene_description.exporter->Export(body_data.positions_1, body_data.velocities_1, 0, scene_settings.dt);
    }

    const bool save_energy_data = scene_description.energy_exporter != nullptr;

    if (save_energy_data) {
        scene_description.energy_exporter->Initialize();
    }

    return std::make_pair(save_data, save_energy_data);
}

#endif //NBODY_SETUP_H
