# nbody

A GPU-accelerated N-Body simulation written in C++ and CUDA.

## Features
* **GPU-Accelerated Compute:** Physics calculations are offloaded to the GPU using CUDA.
* **Modular Architecture:** Built using the Strategy pattern, allowing you to swap out core components:
    * **Solvers:** Pluggable propagation algorithms (e.g., `Solvers::AllPairs`). 
    * **Distributions:** Customizable initial condition generators (e.g., `Distributions::RandomCube`).
    * **Exporters:** Flexible data output handlers.
* **Multiple Export Formats:** Export simulation data in **XDMF**, **VTP**, or **CSV** formats.
* **Configuration:** Tweak simulation constants (such as body count, time delta (`dt`), softening factors, and debugging flags) using a centralized `SceneSettings` struct.
## Performance

|      Version      | Hot Loop Time  | Speed vs. Sample |
|:-----------------:|:--------------:|:----------------:|
| [v0.4.0 (Latest Rel.)] |     5.64 s     |   7.2% faster    |
|  [NVIDIA Sample]  |     6.04 s     |     Baseline     |

*Measured at 45,000 bodies over 1000 steps on an RTX 4060. For complete methodology, hardware specifications, and historical version data, see [BENCHMARKS.md](BENCHMARKS.md).*

## Prerequisites
To compile and run this project, you will need:
* Compiler supporting **C++ 20** (required for `<format>`).
* CUDA Toolkit.

## Build Guidelines

### 1. Configuration (Pre-build)
Currently, simulation parameters are configured directly within `main.cu`. Before compiling, open `main.cu` and modify the `SceneDescription` and `SceneSettings` structs to suit your requirements:

```c++
    SceneSettings scene_settings {
        .body_count = 45000, //N-Count of the simulation
        .steps = 1000, //Step count
        .dt = 0.02, //Physical time elapsed per step
        .softening = 4.0f, //Distance offset for collisionless systems

        .cuda_err = false, //CUDA error checking flag
        .hotloop_time = false, //Hotloop time printing flag
    };

    SceneDescription scene_desc {
        .solver = std::make_unique<Solvers::AllPairs>(scene_settings), //Solver used for propagation
        .distribution = std::make_unique<Distributions::RandomCube>(scene_settings, 15000.0f), //Distribution used for initial conditions
        .exporter = std::make_unique<Exporters::XDMF>(scene_settings, ".", "simulation_data", "simulation_data_org"), //Data exporter
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

- The entire update history of this project will be stored in the [Changelog](CHANGELOG.md).
- This project is licensed using the [MIT License](LICENSE).

[v0.4.0 (Latest Rel.)]: https://gitlab.com/yks4892825/nbody/-/compare/v0.3.0...v0.4.0
[NVIDIA Sample]: https://github.com/NVIDIA/cuda-samples/tree/master/cpp/5_Domain_Specific/nbody