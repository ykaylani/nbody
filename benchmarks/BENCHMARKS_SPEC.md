# Benchmark Methodology

To maintain strict consistency, every version of this project is profiled using the exact same initial conditions, simulation parameters, and hardware environment.

## Measured Values
To avoid capturing one-off system stutters, every version is executed **5 times**. We drop the highest and lowest anomalies, and record the average of the remaining 3 runs (the "Middle 3 Average").

* **Hot Loop Time:** The execution time of the physics integration loop exclusively. This isolates the mathematical and GPU performance by excluding setup, file I/O, and memory allocation.
* **Executable Lifetime:** The total wall-clock time from process start to process termination. This includes CUDA context initialization, memory transfers (Host to Device), and teardown.
* **Refresh Rate (Hz):** Derived directly from the Hot Loop time (Total Steps / Hot Loop Time).

## Hardware Environment
* **OS:** Windows 11
* **CPU:** AMD Ryzen 5 5600
* **GPU:** NVIDIA GeForce RTX 4060 8GB
* **RAM:** 16GB DDR4-3200 CL16

## Simulation Parameters
* **N-Count:** 45,000 bodies
* **Delta Time:** 0.02s
* **Duration:** 1000 Steps (20 physical seconds)
* **Distribution:** Random Cube (15,000 meters)
* **Masses**: 1e17
* **Precision:** FP32

When profiling the Barnes-Hut solver, the following additional parameters are used:
* Approximation Threshold ($\theta$): 0.5
* Leaf Bucket Size: 64

## Establishing the NVIDIA Baseline
The official NVIDIA CUDA N-Body sample is used as the performance baseline for the All-Pairs solver.

The source code (`nbody.cpp`) was patched prior to compilation to change the default timestep from `0.016s` to `0.02s`, and the initial distribution from `SHELL` to `RANDOM` to guarantee mathematically identical initial conditions.

The patched sample was compiled in `Release` mode and executed via:
```bash
nbody.exe -benchmark -numbodies=45000 -i=1000 -device=0
```

## Results

Results are found in [BENCHMARKS.md](BENCHMARKS.md)