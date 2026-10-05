#include <chrono>
#include <iostream>
#include <string>

#include "setup.h"

#include "data/body_data.h"
#include "data/scene_description.h"

#include "strats/exporters.h"
#include "strats/energy/energy_exporters.h"

#include "loop/config_parse.h"
#include "loop/simulation_controller.h"

#include "visualization/visualizer.h"

int main(int argc, char** argv) {

    std::unordered_map<std::string, std::string> config = ParseINI(FindConfiguration(argc, argv));
    SceneSettings scene_settings = BuildSettings(config);

    Visualizer visualizer;
    InitializeVisualizer(visualizer, scene_settings);

    SceneDescription scene_description = BuildSceneDescription(scene_settings, config);
    BodyData body_data { scene_settings.body_count };

    std::pair<bool, bool> save_data = PopulateSceneDescription(scene_description, config, body_data, scene_settings);
    bool save_positions = save_data.first;
    bool save_energy = save_data.second;

    SimulationController simulation_controller(scene_settings);

    std::unique_ptr<EnergyCalculator> energy_calculator;
    if (save_energy) { energy_calculator = std::make_unique<EnergyCalculator>(scene_settings.body_count, scene_settings.softening); }

    std::cout << "Initialization Complete" << std::endl;

    for (int i = 0; i < scene_settings.steps; i++) {
        simulation_controller.Propagate(*scene_description.solver, body_data, scene_settings.dt);
        cudaDeviceSynchronize();

        if (save_energy) {
            EnergyMetrics energy = energy_calculator->Calculate(body_data);
            scene_description.energy_exporter->Export(i + 1, (i + 1) * scene_settings.dt, energy);
        }

        if (scene_settings.visualize && (i % scene_settings.n_frames_snap == 0)) {
            const float4* bounds_min = nullptr;
            const float4* bounds_max = nullptr;
            uint32_t node_count = 0;
            bool has_tree = simulation_controller.GetTreeBounds(&*scene_description.solver, &bounds_min, &bounds_max, &node_count);

            visualizer.PollEvents();
            visualizer.UpdateCamera(scene_settings.dt);
            visualizer.RenderFrame(body_data.positions_1, scene_settings.body_count, bounds_min, bounds_max, node_count, scene_settings.min_node_extent, scene_settings.visualize_tree && has_tree);
        }

        if (save_positions) { scene_description.exporter->Export(body_data.positions_1, body_data.velocities_1, i + 1, scene_settings.dt); }
    }

    cudaDeviceSynchronize();
    if (save_positions) scene_description.exporter->Finalize();
    if (save_energy) scene_description.energy_exporter->Finalize();

    std::cout << "Run Complete" << std::endl;
    return 0;
}