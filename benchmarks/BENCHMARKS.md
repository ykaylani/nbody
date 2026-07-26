# Performance Benchmarks

All notable performance benchmarks are documented here. For details on the hardware environment, simulation parameters, and how these metrics are captured, please read the [Benchmark Methodology](BENCHMARKS_SPEC.md).

> **Versioning Note:** On 2026-07-19, historical tags `v0.1.3` through `v0.1.6` were retroactively updated to `v0.2.0` through `v0.4.0` to align with SemVer. Some older commit messages may still reference the original `0.1.x` version numbers.

## All-Pairs (Brute-Force) Performance
The All-Pairs solver is evaluated against the official NVIDIA CUDA N-Body sample (45,000 bodies, identical random distribution, 1000 steps).

| Version | Hot Loop | Lifetime | Refresh Rate | vs NVIDIA Baseline |
| :--- | :--- | :--- | :---: | :--- |
| **[NVIDIA Sample]** | 6.04 s | 6.30 s | 165.48 Hz | **Baseline** |
| [v0.4.4] | 5.88 s | 6.10 s | 170.01 Hz | +2.7% |
| [v0.4.3] | 5.84 s | 6.08 s | 171.32 Hz | +3.5% |
| [v0.4.2] | 5.90 s | 6.14 s | 169.46 Hz | +2.4% |
| [v0.4.1] | 5.86 s | 6.09 s | 170.79 Hz | +3.2% |
| [v0.4.0] | 5.64 s | 5.90 s | 177.35 Hz | +7.2% |
| [v0.3.0] | 5.58 s | 5.84 s | 179.24 Hz | +8.3% |
| [v0.2.1] | 5.73 s | 6.03 s | 174.62 Hz | +5.5% |
| [v0.2.0] | 5.62 s | 5.95 s | 177.82 Hz | +7.5% |
| [v0.1.2] | 7.67 s | 8.00 s | 130.33 Hz | −21.2% |
| [v0.1.1] | 12.45 s | 12.72 s | 80.34 Hz | −51.4% |
| [v0.1.0] | 12.38 s | 12.67 s | 80.78 Hz | −51.2% |

## Barnes-Hut Performance
Starting from `v0.4.1`, the project includes a Barnes-Hut solver.

| Version | Hot Loop | Lifetime | Refresh Rate |
| :--- | :--- | :--- | :---: |
| [v0.4.4] | 2.68 s | 2.91 s | 373.13 Hz |
| [v0.4.3] | 8.35 s | N/A | 119.82 Hz |
| [v0.4.2] | 24.35 s | N/A | 41.06 Hz |
| [v0.4.1] | 99.45 s | N/A | 10.06 Hz |

[NVIDIA Sample]: https://github.com/NVIDIA/cuda-samples/tree/master/cpp/5_Domain_Specific/nbody
[v0.4.4]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.3...v0.4.4
[v0.4.3]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.2...v0.4.3
[v0.4.2]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.1...v0.4.2
[v0.4.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.0...v0.4.1
[v0.4.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.3.0...v0.4.0
[v0.3.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.2.1...v0.3.0
[v0.2.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.2.0...v0.2.1
[v0.2.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.2...v0.2.0
[v0.1.2]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.1...v0.1.2
[v0.1.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.0...v0.1.1
[v0.1.0]: https://gitlab.com/yks4892825/nbody/-/tags/v0.1.0