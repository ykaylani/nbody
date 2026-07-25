# Performance Benchmarks
All notable benchmarks done with this project will be documented in this file.
> **Versioning Note:** On 2026-07-19, historical tags `v0.1.3` through `v0.1.6` were retroactively updated to `v0.2.0` through `v0.4.0` to align with SemVer. Some older commit messages may still reference the original `0.1.x` version numbers.
## Testing Methodology
To maintain consistency, every version is profiled using the exact same initial conditions and simulation parameters:

### Simulation Parameters
- N-Count: 45,000
- Delta Time: 0.02s
- Duration: 1000 Steps (20 physical seconds)
- Distribution: Random Cube
- Solver: All-Pairs (Brute-Force)
- Precision: FP32

Execution: Each version is run 5 times, dropping the highest and lowest anomalies, with the average of the remaining 3 runs recorded.

> **Barnes-Hut Clarification:** Starting from `v0.4.1`, benchmarks also track the Barnes-Hut solver alongside the standard All-Pairs solver. The Barnes-Hut metrics are captured using the same 45,000-body Random Cube state, specifically configured with an approximation threshold of $\theta = 0.5$ and a maximum octree depth of $64$. The "against sample" percentage is calculated using the standard All-Pairs performance.

### Hardware Environment
- OS: Windows 11
- CPU: AMD Ryzen 5 5600
- GPU: NVIDIA GeForce RTX 4060 8GB
- RAM: 16GB DDR4-3200 CL16

### Measured Values
- Hot Loop Time
- Executable Lifetime

(Refresh rate calculated from hot loop time)

## Baselines
### [NVIDIA CUDA N-Body Sample]

The official NVIDIA sample was compiled in `Release` mode and executed using the following underlying CLI command:
```bash
nbody.exe -benchmark -numbodies=45000 -i=1000 -device=0
```

Note: The source code (`nbody.cpp`) was patched prior to compilation to change the default timestep from 0.016s to 0.02s and the initial distribution from SHELL to RANDOM to ensure identical initial conditions.

## Benchmarks

### Execution Time (all versions)

| Version                     | AP Hot Loop | BH Hot Loop | Lifetime |   AP Hz   |   BH Hz   | against sample |
|:----------------------------|:------------|:------------|:---------|:---------:|:---------:|:---------------|
| [NVIDIA CUDA N-Body Sample] | 6.04 s      | N/A         | 6.30 s   | 165.48 Hz | N/A       | baseline       |
| [v0.4.3]                    | 5.84 s      | 8.35 s      | 6.08 s   | 171.32 Hz | 119.82 Hz | +3.5%          |
| [v0.4.2]                    | 5.90 s      | 24.35 s     | 6.14 s   | 169.46 Hz | 41.06 Hz  | +2.4%          |
| [v0.4.1]                    | 5.86 s      | 99.45 s     | 6.09 s   | 170.79 Hz | 10.06 Hz  | +3.2%          |
| [v0.4.0]                    | 5.64 s      | N/A         | 5.90 s   | 177.35 Hz | N/A       | +7.2%          |
| [v0.3.0]                    | 5.58 s      | N/A         | 5.84 s   | 179.24 Hz | N/A       | +8.3%          |
| [v0.2.1]                    | 5.73 s      | N/A         | 6.03 s   | 174.62 Hz | N/A       | +5.5%          |
| [v0.2.0]                    | 5.62 s      | N/A         | 5.95 s   | 177.82 Hz | N/A       | +7.5%          |
| [v0.1.2]                    | 7.67 s      | N/A         | 8.00 s   | 130.33 Hz | N/A       | −21.2%         |
| [v0.1.1]                    | 12.45 s     | N/A         | 12.72 s  | 80.34 Hz  | N/A       | −51.4%         |
| [v0.1.0]                    | 12.38 s     | N/A         | 12.67 s  | 80.78 Hz  | N/A       | −51.2%         |

[NVIDIA CUDA N-Body Sample]: https://github.com/NVIDIA/cuda-samples/tree/master/cpp/5_Domain_Specific/nbody
[v0.4.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.3.0...v0.4.0
[v0.3.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.2.1...v0.3.0
[v0.2.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.2.0...v0.2.1
[v0.2.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.2...v0.2.0
[v0.1.2]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.1...v0.1.2
[v0.1.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.0...v0.1.1
[v0.1.0]: https://gitlab.com/yks4892825/nbody/-/tags/v0.1.0