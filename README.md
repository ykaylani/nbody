## ykaylani/nbody

A GPU N-Body simulation written in C++ and CUDA.

<p>
  <img src="imgs/plummer_rtree.png" alt="Plummer Sphere + Radix Tree Wireframe" width="49%" />
  <img src="imgs/plummer.png" alt="Plummer Sphere" width="49%" />
</p>

## Features
Calculations are offloaded to the GPU using CUDA.
* **Modular Architecture:** Built using the Strategy pattern, allowing you to swap out components:
    * **Solvers:** **Barnes-Hut (Radix Tree) / All-Pairs** solvers
    * **Distributions:** **Plummer / Kuzmin / Random** distributions
    * **Exporters:** **CSV / XDMF / VTP** exporters
* **Configuration:** Tweak simulation constants (such as body count, time delta (`dt`), softening factors, and debugging flags) using a config.ini file.
* **Visualization:** Visualize the simulation using OpenGL.

## Prerequisites
To compile and run this project, you will need:
* Compiler supporting **C++ 20**
* CMake ≥ 4.2
* CUDA Toolkit
* OpenGL
* GLEW

## Build Guidelines

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
Once the build process is complete, the executable should be located inside a subfolder.
To run the simulation:
```bash
./Release/nbody.exe /directory/of/config/config.ini
```

For the config.ini structure, go to [config.ini.example](config.ini.example).

## Tests
Test design can be found in [the benchmark specification](BENCHMARKS_SPEC.md).

<p>
  <img src="imgs/scaling.png" alt="Solver Scaling Benchmark"/>
  <img src="imgs/energytrj.png" alt="Energy Trajectory for Theta = 0.5"/>
  <img src="imgs/secons.png" alt="Energy Conservation"/>
</p>

## Information

* All changes are documented in [CHANGELOG.md](CHANGELOG.md).
* [MIT License](LICENSE).
