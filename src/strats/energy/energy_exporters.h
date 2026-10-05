#ifndef NBODY_ENERGY_EXPORTERS_H
#define NBODY_ENERGY_EXPORTERS_H

#include <filesystem>
#include <fstream>
#include <iostream>
#include "energy_calculator.h"
#include "../../data/scene_settings.h"

struct EnergyExporter {
    SceneSettings scene_settings;

    virtual void Initialize() = 0;
    virtual void Export(uint32_t step, float time, const EnergyMetrics& metrics) = 0;
    virtual void Finalize() = 0;

    virtual ~EnergyExporter() = default;
    explicit EnergyExporter(const SceneSettings& scene_settings) : scene_settings(scene_settings) {}
};

namespace EnergyExporters {

    struct Console : public EnergyExporter {
        using EnergyExporter::EnergyExporter;

        void Initialize() override {}
        void Export(uint32_t step, float time, const EnergyMetrics& metrics) override {
            std::cout << "[Step " << step << " | " << time << "s] Energy: " 
                      << metrics.Total() << " (Kinetic: " << metrics.kinetic 
                      << ", Potential: " << metrics.potential << ")\n";
        }
        void Finalize() override {}
    };

    struct CSV : public EnergyExporter {
        std::ofstream outfile_;
        std::filesystem::path outpath_ = ".";
        std::filesystem::path filename_ = "energy_log.csv";

        CSV(const SceneSettings& settings, std::filesystem::path outpath, std::filesystem::path filename)
            : EnergyExporter(settings), outpath_(std::move(outpath)), filename_(std::move(filename)) {}

        void Initialize() override {
            std::filesystem::create_directories(outpath_);
            std::filesystem::path full_path = outpath_ / filename_;

            outfile_.open(full_path);
            if (!outfile_.is_open()) {
                throw std::runtime_error("Failed to open energy log CSV at " + full_path.string());
            }

            outfile_ << "Step,Time,Kinetic,Potential,Total\n";
        }

        void Export(uint32_t step, float time, const EnergyMetrics& metrics) override {
            outfile_ << step << "," << time << ","
                     << metrics.kinetic << ","
                     << metrics.potential << ","
                     << metrics.Total() << "\n";
        }

        void Finalize() override {
            if (outfile_.is_open()) { outfile_.close(); }
        }
    };
}

#endif // NBODY_ENERGY_EXPORTERS_H