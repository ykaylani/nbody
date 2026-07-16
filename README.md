# nbody

A high-performance, GPU-accelerated N-Body simulation written in C++ and CUDA. This project simulates the gravitational interactions and movements of particles (bodies) in a 3D space, leveraging parallel computation to handle large numbers of bodies.

## Features
* **GPU Acceleration:** Core physics calculations are offloaded to the GPU using CUDA.
* **Performance Profiling:** Built-in execution time tracking using `std::chrono`.
* **Memory Monitoring:** Real-time working set memory tracking upon initialization.
* **Data Export (Optional):** Capable of exporting position and velocity data to CSV format for external visualization (e.g., Python/ParaView).

## Prerequisites
To compile and run this project, you will need:
* Windows (relies on `windows.h` and `psapi.h` for memory profiling).
* Compiler supporting **C++ 20** (required for `<format>`).
* CUDA Toolkit.

## Project Structure
* `src/data/body_data.h`: Defines the `BodyData` structure holding arrays for positions, velocities, and inverse masses.
* `src/data/scene_desc.h`: Defines the `SceneDescription` parameters (body count, step count, delta time, etc.).
* `main.cu`: The primary application entry point, memory allocation, and simulation loop.

## Build Guidelines

### 1. Configuration (Pre-build)
Currently, simulation parameters are configured directly within `main.cu`. Before compiling, open `main.cu` and modify the `SceneDescription` struct to suit your requirements:

```cpp
SceneDescription scene_description {
    45000,             // body_count_: Number of particles
    100,               // steps_: Total simulation steps to execute
    0.02,              // dt_: Delta time per step
    true,              // equal_mass_: Flag for simplified mass calculations
    false,             // cuda_err_: Flag for CUDA error checking
    true,              // export_data_: Flag for data export
    "C:/Users/USER..." // data_directory: Output path (defaults to executable directory if empty)
};
```

### 2. Building
This project requires CMake 4.2+, a C++20 compatible compiler (such as MSVC on Windows), and the CUDA Toolkit (on CUDA standard 26).
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