# nbody

A high-performance, GPU-accelerated N-Body simulation written in C++ and CUDA. This project simulates the gravitational interactions and movements of particles (bodies) in a 3D space, leveraging parallel computation to handle large numbers of bodies.

## Features
* **GPU Acceleration:** Core physics calculations are offloaded to the GPU using CUDA.
* **Performance Profiling:** Built-in execution time tracking using `std::chrono`.
* **Data Export (Optional):** Capable of exporting position and velocity data to CSV format for external visualization (e.g., Python/ParaView).

## Prerequisites
To compile and run this project, you will need:
* Compiler supporting **C++ 20** (required for `<format>`).
* CUDA Toolkit.

## Project Structure
* `src/data/body_data.h`: Defines the `BodyData` structure holding arrays for positions, velocities, and masses.
* `src/data/scene_desc.h`: Defines the `SceneDescription` parameters (body count, step count, delta time, etc.).
* `main.cu`: The primary application entry point, memory allocation, and simulation loop.

## Build Guidelines

### 1. Configuration (Pre-build)
Currently, simulation parameters are configured directly within `main.cu`. Before compiling, open `main.cu` and modify the `SceneDescription` struct to suit your requirements:

```cpp
SceneDescription scene_desc {
    .distribution_ = std::make_unique<Distributions::RandomCube>(15000.0f), // Initial conditions distributor
    .exporter_ = std::make_unique<Exporters::XDMF>(".", "simulation_data", "simulation_data_org"), // Data exporter

    .body_count_ = 45000, // Body count
    .steps_ = 1000, // Iterations (how many times should the simulation advance)
    .dt_ = 0.02f, // physical change in time per step
    .softening_ = 4.0f, // softening for collisionless systems

    .equal_mass_ = true, // Flag that enables memory optimizations when all bodies have equal mass
    .cuda_err_ = false, // Flag for CUDA error checking (decreases performance)
};
```

### 2. Building
This project requires CMake 4.2+, a C++20 compatible compiler (such as MSVC on Windows), and the CUDA Toolkit.
1. Open a terminal
2. Navigate to the root directory of the project
3. Create a build directory: 
```bash 
mkdir build
cd build
```
4. Generate the build from CMake, then compile the executable:
```bash
cmake ..
cmake --build . --config Release
```
Once the build process is complete, the executable should be located inside a subfolder (typically named Release).
To run the simulation:
```bash
./Release/nbody.exe
```


## Extra Information

- Benchmark data is available in the [Benchmarks](BENCHMARKS.md) file.
- The entire update history of this project will be stored in the [Changelog](CHANGELOG.md).
- This project is licensed using the [MIT License](LICENSE).