# Performance Benchmarks
All notable benchmarks done with this project will be documented in this file.
## Testing Methodology
To maintain consistency, every version is profiled using the exact same initial conditions and simulation parameters:

### Simulation Parameters
- N-Count: 45,000
- Delta Time: 0.02s
- Duration: 1000 Steps (20 physical seconds)
- Distribution: Random Cube

Execution: Each version is run 5 times, dropping the highest and lowest anomalies, with the average of the remaining 3 runs recorded.

### Hardware Environment
- OS: Windows 11
- CPU: AMD Ryzen 5 5600
- GPU: NVIDIA GeForce RTX 4060 8GB
- RAM: 16GB DDR4-3200 CL16

### Measured Values
- Hot Loop Time
- Executable Lifetime

(Refresh rate calculated from hot loop time)

## Benchmarks

### Execution Time (all versions)

| Version  | Hot Loop Time | Executable Lifetime | Steps / Second (Hz) |
|:--------:|:-------------:|:-------------------:|:-------------------:|
| [v0.1.6] |    5.64 s     |       5.90 s        |      177.35 Hz      |
| [v0.1.5] |    5.58 s     |       5.84 s        |      179.24 Hz      |
| [v0.1.4] |    5.73 s     |       6.03 s        |      174.62 Hz      |
| [v0.1.3] |    5.62 s     |       5.95 s        |      177.82 Hz      |
| [v0.1.2] |    7.67 s     |       8.00 s        |      130.33 Hz      |
| [v0.1.1] |    12.45 s    |       12.72 s       |      80.34 Hz       |
| [v0.1.0] |    12.38 s    |       12.67 s       |      80.78 Hz       |

[v0.1.6]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.5...v0.1.6
[v0.1.5]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.4...v0.1.5
[v0.1.4]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.3...v0.1.4
[v0.1.3]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.2...v0.1.3
[v0.1.2]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.1...v0.1.2
[v0.1.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.0...v0.1.1
[v0.1.0]: https://gitlab.com/yks4892825/nbody/-/tags/v0.1.0