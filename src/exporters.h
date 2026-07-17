#ifndef NBODY_EXPORTERS_H
#define NBODY_EXPORTERS_H

#include <filesystem>
#include <fstream>
#include <utility>

#include <stdexcept>
#include <cstdint>

struct Exporter {

    virtual void Initialize() = 0;
    virtual void Export(const float3* positions, const float3* velocities, const float* masses, uint32_t body_count, uint32_t step, float dt, bool equal_mass) = 0;
    virtual void Finalize() = 0;

    virtual ~Exporter() = default;
};

namespace Exporters {

    struct CSV : Exporter {
        std::ofstream outfile_;

        std::filesystem::path outpath_ = ".";
        std::filesystem::path filename_ = "nbodydata";

        CSV(std::filesystem::path outpath, std::filesystem::path filename) : outpath_(std::move(outpath)), filename_(std::move(filename)) {}

        void Initialize() override {
            std::filesystem::path full_path = outpath_ / filename_;
            std::filesystem::create_directories(outpath_);

            outfile_.open(outpath_ / filename_);
            if (!outfile_.is_open()) { throw std::runtime_error("Failed to open CSV file at " + full_path.string()); }

            outfile_ << "Time,ID,PosX,PosY,PosZ,VelX,VelY,VelZ\n";
        }

        void Export(const float3* positions, const float3* velocities, const float* masses, uint32_t body_count, uint32_t step, float dt, bool equal_mass) override {
            for (int i = 0; i < body_count; i++) {
                outfile_ << step * dt << ","
                    << i << ","
                    << positions[i].x << ","
                    << positions[i].y << ","
                    << positions[i].z << ","
                    << velocities[i].x << ","
                    << velocities[i].y << ","
                    << velocities[i].z << "\n";
            }
        }

        void Finalize() override {
            if (outfile_.is_open()) { outfile_.close(); }
        }
    };


    struct XDMF : Exporter {
        std::ofstream xmf_file_;
        std::ofstream bin_file_;
        std::filesystem::path bin_filename_;
        std::filesystem::path xmf_filename_;

        std::filesystem::path outpath_;
        std::vector<float> mass_broadcast_;

        XDMF(std::filesystem::path outpath, std::filesystem::path bin_filename, std::filesystem::path xmf_filename) : outpath_(std::move(outpath)), bin_filename_(std::move(bin_filename)), xmf_filename_(std::move(xmf_filename)) {}

        void Initialize() override {
            std::filesystem::create_directories(outpath_);

            xmf_filename_.replace_extension(".xmf");
            bin_filename_.replace_extension(".bin");
            std::filesystem::path xmf_full_path = outpath_ / xmf_filename_;
            std::filesystem::path bin_full_path = outpath_ / bin_filename_;

            xmf_file_.open(xmf_full_path);
            if (!xmf_file_.is_open()) { throw std::runtime_error("Failed to open XDMF file at " + xmf_full_path.string()); }

            bin_file_.open(bin_full_path, std::ios::binary);
            if (!bin_file_.is_open()) { throw std::runtime_error("Failed to open binary file at " + bin_full_path.string()); }

            xmf_file_ << R"(<?xml version="1.0" ?>
            <!DOCTYPE Xdmf SYSTEM "Xdmf.dtd" []>
            <Xdmf Version="2.0">
              <Domain>
                <Grid Name="Simulation" GridType="Collection" CollectionType="Temporal">
            )";
        }

        void Export(const float3* positions, const float3* velocities, const float* masses, uint32_t body_count, uint32_t step, float dt, bool equal_mass) override {
            size_t vec_bytes = body_count * 3 * sizeof(float);
            size_t scalar_bytes = body_count * sizeof(float);

            const float* mass_ptr = masses;

            if (equal_mass) {

                if (mass_broadcast_.size() != body_count) { mass_broadcast_.resize(body_count); }
                std::fill(mass_broadcast_.begin(), mass_broadcast_.end(), masses[0]);
                mass_ptr = mass_broadcast_.data();
            }

            size_t step_start_offset = static_cast<size_t>(bin_file_.tellp());

            bin_file_.write(reinterpret_cast<const char*>(positions), vec_bytes);
            bin_file_.write(reinterpret_cast<const char*>(velocities), vec_bytes);
            bin_file_.write(reinterpret_cast<const char*>(mass_ptr), scalar_bytes);
            bin_file_.flush();

            size_t pos_offset  = step_start_offset;
            size_t vel_offset  = step_start_offset + vec_bytes;
            size_t mass_offset = step_start_offset + vec_bytes + vec_bytes;

            xmf_file_ <<
                R"(<Grid Name="Step_)" << step << R"(" GridType="Uniform">
                    <Time Value=")" << step * dt << R"(" />
                    <Topology TopologyType="Polyvertex" NumberOfElements=")" << body_count << R"("/>
                    <Geometry GeometryType="XYZ">
                      <DataItem Dimensions=")" << body_count << R"( 3" NumberType="Float" Precision="4" Format="Binary" Seek=")" << pos_offset << R"(" Endian="Native">
                        )" << bin_filename_.string() << R"(
                      </DataItem>
                    </Geometry>
                    <Attribute Name="Velocity" AttributeType="Vector" Center="Node">
                      <DataItem Dimensions=")" << body_count << R"( 3" NumberType="Float" Precision="4" Format="Binary" Seek=")" << vel_offset << R"(" Endian="Native">
                        )" << bin_filename_.string() << R"(
                      </DataItem>
                    </Attribute>
                    <Attribute Name="Mass" AttributeType="Scalar" Center="Node">
                      <DataItem Dimensions=")" << body_count << R"(" NumberType="Float" Precision="4" Format="Binary" Seek=")" << mass_offset << R"(" Endian="Native">
                        )" << bin_filename_.string() << R"(
                      </DataItem>
                    </Attribute>
                  </Grid>
            )";

            xmf_file_.flush();
        }

        void Finalize() override {
            if (bin_file_.is_open()) { bin_file_.close(); }

            if (xmf_file_.is_open()) {
                xmf_file_ <<
                    R"(    </Grid>
                      </Domain>
                    </Xdmf>
                    )";
                xmf_file_.close();
            }
        }
    };
}

#endif //NBODY_EXPORTERS_H
