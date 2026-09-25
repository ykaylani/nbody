# Benchmark Methodology

To maintain consistency, every version of this project is profiled using the exact same initial conditions, simulation parameters, and hardware environment.

## Measured Values
To avoid capturing one-off system stutters, every version is executed **5 times**. We drop the highest and lowest anomalies, and record the average of the remaining 3 runs (the "Middle 3 Average").

* **Hot Loop Time:** The execution time of the physics integration loop exclusively. This isolates the mathematical and GPU performance by excluding setup, file I/O, and memory allocation.
* **Executable Lifetime:** The total wall-clock time from process start to process termination. This includes CUDA context initialization, memory transfers (Host to Device), and teardown.
* **Refresh Rate (Hz):** Derived directly from the Hot Loop time (Total Steps / Hot Loop Time).

## Hardware / Environment
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

## NVIDIA Baseline
The official NVIDIA CUDA N-Body sample is used as the performance baseline for the All-Pairs solver.

The source code (`nbody.cpp`) was patched prior to compilation to change the default timestep from `0.016s` to `0.02s`, and the initial distribution from `SHELL` to `RANDOM` to guarantee identical initial conditions.

The patched sample was compiled in `Release` mode and executed via:
```bash
nbody.exe -benchmark -numbodies=45000 -i=1000 -device=0
```

## N-Count Scaling Test

In addition to the fixed 45,000-body comparison above, a separate test measures how each solver's Hot Loop Time and Refresh Rate scale as N grows.
**Hardware / Environment**: Same as above.

### Simulation Parameters
* **N-Count:** Variable (see below)
* **Delta Time:** 0.02s
* **Duration:** 1000 Steps (20 physical seconds)
* **Distribution:** Random Cube (variable size, see below)
* **Masses**: 1e17
* **Precision:** FP32
* **Approximation Threshold ($\theta$)**: 0.5
* **Leaf Bucket Size**: 16

### Domain Scaling
`size_` is not held constant across N. Packing more bodies into the same 15,000-unit cube would raise number density as N grows, which confounds the test in two ways: it makes each region of the tree harder to evaluate independently of N (deeper local structure, more bodies per leaf bucket at a given $\theta$), and it shrinks the average inter-body spacing relative to the softening factor tuned for the sparser 45,000-body case, inviting close-encounter forces large enough to destabilize the integrator. Instead, `size_` scales with N to hold number density and mass density:
`s(N) = 15,000 * (N / 45,000)^(1/3)`

  |    N    |       size_       |
  |:-------:|:-----------------:|
  | 10,000  |       9,086       |
  | 45,000  | 15,000 (baseline) |
  | 100,000 |      19,586       |
  | 300,000 |      28,231       |

## Measured Values
Same methodology as the main test (5 runs, drop the high/low, average the remaining 3), recorded per N-Count.
* **N-Count Values Tested:** 10,000 / 45,000 (baseline) / 100,000 / 300,000
* **All-Pairs Scope:** All-Pairs is only measured up to 100,000 bodies.

## Results

Results are found in [BENCHMARKS.md](BENCHMARKS.md)