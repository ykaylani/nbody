# nbody

A GPU-accelerated N-Body simulation written in C++ and CUDA.

## Features
* **GPU-Accelerated Compute:** Physics calculations are offloaded to the GPU using CUDA.
* **Modular Architecture:** Built using the Strategy pattern, allowing you to swap out core components:
    * **Solvers:** Pluggable propagation algorithms (e.g., `Solvers::AllPairs`). 
    * **Distributions:** Customizable initial condition generators (e.g., `Distributions::RandomCube`).
    * **Exporters:** Flexible data output handlers.
* **Multiple Export Formats:** Export simulation data in **XDMF**, **VTP**, or **CSV** formats.
* **Configuration:** Tweak simulation constants (such as body count, time delta (`dt`), softening factors, and debugging flags) using a config.ini file.
## Performance

|       Version       | Hot Loop Time | Speed vs. Sample |
|:-------------------:|:-------------:|:----------------:|
| [v0.5.0 Barnes-Hut] |    2.71 s     |     +123.3%      |
| [v0.5.0 All-Pairs]  |    5.64 s     |      +3.1%       |
|   [NVIDIA Sample]   |    6.04 s     |     Baseline     |

*Measured at 45,000 bodies over 1000 steps on an RTX 4060. For complete methodology, hardware specifications, and historical version data, see [BENCHMARKS.md](benchmarks/BENCHMARKS.md) and [BENCHMARKS_SPEC.md](benchmarks/BENCHMARKS_SPEC.md).*

## Prerequisites
To compile and run this project, you will need:
* Compiler supporting **C++ 20** (required for `<format>`).
* CUDA Toolkit.

## Build Guidelines

### 1. Configuration
simulation parameters are configured from config.ini.

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
./Release/nbody.exe /directory/of/config
```


## Extra Information

- The entire update history of this project will be stored in the [Changelog](CHANGELOG.md).
- This project is licensed using the [MIT License](LICENSE).

[v0.5.0 Barnes-Hut]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.4...v0.5.0
[v0.5.0 All-Pairs]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.4...v0.5.0
[NVIDIA Sample]: https://github.com/NVIDIA/cuda-samples/tree/master/cpp/5_Domain_Specific/nbody