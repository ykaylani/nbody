#ifndef NBODY_EXPORTERS_H
#define NBODY_EXPORTERS_H

#include <filesystem>
#include <fstream>
#include <utility>

#include <stdexcept>
#include <cstdint>

struct Exporter {

    virtual void Initialize() = 0;
    virtual void Export(const float3* positions, const float3* velocities, const float* masses, uint32_t body_count, uint32_t step, float dt) = 0;
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

        void Export(const float3* positions, const float3* velocities, const float* masses, uint32_t body_count, uint32_t step, float dt) override {

            for (int i = 0; i < body_count; i++) {
                outfile_ << step * dt << ","
                    << i << ","
                    << positions[i].x << ","
                    << positions[i].y << ","
                    << positions[i].z << ","
                    << velocities[i].x << ","
                    << velocities[i].y << ","
                    << velocities[i].z << ","
                    << masses[i] << "\n";
            }
        }

        void Finalize() override {
            if (outfile_.is_open()) { outfile_.close(); }
        }
    };


    struct XDMF : Exporter {
        std::ofstream xmf_file_;
        std::ofstream bin_file_;
        std::filesystem::path bin_filename_ = "nbodydata_bin";
        std::filesystem::path xmf_filename_ = "nbodydata_xmf";

        std::filesystem::path outpath_ = ".";
        std::vector<float> mass_broadcast_;

        XDMF(std::filesystem::path outpath, std::filesystem::path bin_filename, std::filesystem::path xmf_filename) : bin_filename_(std::move(bin_filename)), xmf_filename_(std::move(xmf_filename)), outpath_(std::move(outpath)) {}

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

        void Export(const float3* positions, const float3* velocities, const float* masses, uint32_t body_count, uint32_t step, float dt) override {
            size_t vec_bytes = body_count * 3 * sizeof(float);
            size_t scalar_bytes = body_count * sizeof(float);

            size_t step_start_offset = static_cast<size_t>(bin_file_.tellp());

            bin_file_.write(reinterpret_cast<const char*>(positions), vec_bytes);
            bin_file_.write(reinterpret_cast<const char*>(velocities), vec_bytes);
            bin_file_.write(reinterpret_cast<const char*>(masses), scalar_bytes);
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


    struct VTP : Exporter {
        std::ofstream outfile_;
        std::filesystem::path outfile_name_ = "nbodydata";
        std::filesystem::path outpath_ = ".";
        std::vector<float> mass_broadcast_;

        VTP(std::filesystem::path outpath, std::filesystem::path outfile_name) : outfile_name_(std::move(outfile_name)), outpath_(std::move(outpath)) {}

        void Initialize() override {
            std::filesystem::create_directories(outpath_);

            outfile_name_.replace_extension(".pvd");
            std::filesystem::path full_path = outpath_ / outfile_name_;

            outfile_.open(full_path.string());
            if (!outfile_.is_open()) { throw std::runtime_error("Failed to open PVD file at " + full_path.string()); }

            outfile_ << R"(<?xml version="1.0"?>
                           <VTKFile type="Collection" version="0.1" byte_order="LittleEndian">
                           <Collection>
                         )";
        }

        void Export(const float3* positions, const float3* velocities, const float* masses, uint32_t body_count, uint32_t step, float dt) override {

            uint32_t vec_bytes = body_count * 3 * sizeof(float);
            uint32_t scalar_bytes = body_count * sizeof(float);

            std::string step_name = outfile_name_.stem().string() + "_" + std::to_string(step) + ".vtp";
            std::filesystem::path full_step_path = outpath_ / step_name;

            std::ofstream step_file(full_step_path, std::ios::binary);
            if (!step_file.is_open()) { throw std::runtime_error("Failed to open step VTP file at " + full_step_path.string()); }

            uint32_t pos_offset = 0;
            uint32_t vel_offset = pos_offset + sizeof(uint32_t) + vec_bytes;
            uint32_t mass_offset = vel_offset + sizeof(uint32_t) + vec_bytes;

            step_file << R"(<?xml version="1.0"?>
                            <VTKFile type="PolyData" version="0.1" byte_order="LittleEndian" header_type="UInt32">
                              <PolyData>
                                <Piece NumberOfPoints=")" << body_count << R"(" NumberOfVerts="0" NumberOfLines="0" NumberOfStrips="0" NumberOfPolys="0">
                                  <Points>
                                    <DataArray type="Float32" Name="Points" NumberOfComponents="3" format="appended" offset=")" << pos_offset << R"("/>
                                  </Points>
                                  <PointData Vectors="Velocity" Scalars="Mass">
                                    <DataArray type="Float32" Name="Velocity" NumberOfComponents="3" format="appended" offset=")" << vel_offset << R"("/>
                                    <DataArray type="Float32" Name="Mass" NumberOfComponents="1" format="appended" offset=")" << mass_offset << R"("/>
                                  </PointData>
                                </Piece>
                              </PolyData>
                              <AppendedData encoding="raw">
                            _)";

            step_file.write(reinterpret_cast<const char*>(&vec_bytes), sizeof(uint32_t));
            step_file.write(reinterpret_cast<const char*>(positions), vec_bytes);

            step_file.write(reinterpret_cast<const char*>(&vec_bytes), sizeof(uint32_t));
            step_file.write(reinterpret_cast<const char*>(velocities), vec_bytes);

            step_file.write(reinterpret_cast<const char*>(&scalar_bytes), sizeof(uint32_t));
            step_file.write(reinterpret_cast<const char*>(masses), scalar_bytes);

            step_file << "\n  </AppendedData>\n</VTKFile>\n";
            step_file.close();

            outfile_ << "    <DataSet timestep=\"" << (step * dt) << "\" group=\"\" part=\"0\" file=\"" << step_name << "\"/>\n";
            outfile_.flush();
        }

        void Finalize() override {
            if (outfile_.is_open()) {

                outfile_ << R"(  </Collection>
                                </VTKFile>
                                )";

                outfile_.close();
            }
        }
    };
}

#endif //NBODY_EXPORTERS_H
