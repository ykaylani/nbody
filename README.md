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

## Configuration
Currently, simulation parameters are configured directly within `main.cu` via the `SceneDescription` struct:
```cpp
SceneDescription scene_desc {
    45000,   // bodyCount: Number of particles
    true,    // equalMass: Flag for simplified mass calculations
    100,     // steps: Total simulation steps to execute
    0.02     // dt: Delta time per step
};
```
## Notes on CSV Logging
By default, the CSV data logging functions `CSVSave()` and device synchronization checks inside the main loop are commented out to strictly benchmark the raw compute performance of the CUDA kernel.

### To export data:

1. Uncomment the file stream and CSVSave calls inside the main.cu loop.
1. Update the absolute output path (D:/env/empi/NBodyData/...) to match your local directory structure before compiling.

## Extra Information

- This project is licensed using the [MIT License](LICENSE).
- The entire update history of this project will be stored in the [Changelog](CHANGELOG.md).