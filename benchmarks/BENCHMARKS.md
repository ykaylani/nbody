# Performance Benchmarks

All notable performance benchmarks are documented here. For details on the hardware environment, simulation parameters, and how these metrics are captured, see the [Benchmark Methodology](BENCHMARKS_SPEC.md).

## All-Pairs (Brute-Force) Performance

Evaluated against the official NVIDIA CUDA N-Body sample (45,000 bodies, identical random distribution, 1000 steps).

|     Version      | Hot Loop  | Lifetime  | Refresh Rate | Δ vs Previous | vs NVIDIA Baseline  |
|:----------------:|:---------:|:---------:|:------------:|:-------------:|:-------------------:|
| [NVIDIA Sample]  |  6.04 s   |  6.30 s   |  165.48 Hz   |      N/A      |      Baseline       |
|     [v0.1.0]     |  12.45 s  |  12.67 s  |   80.31 Hz   |      N/A      |       −51.5%        |
|     [v0.1.1]     |  12.44 s  |  12.64 s  |   80.41 Hz   |     +0.1%     |       −51.4%        |
|     [v0.1.2]     |  7.62 s   |  7.84 s   |  131.30 Hz   |    +63.3%     |       −20.7%        |
|     [v0.2.0]     |  5.58 s   |  5.81 s   |  179.24 Hz   |    +36.5%     |        +8.3%        |
|     [v0.2.1]     |  5.70 s   |  5.94 s   |  175.47 Hz   |     −2.1%     |        +6.0%        |
|     [v0.3.0]     |  5.69 s   |  5.94 s   |  175.65 Hz   |     +0.1%     |        +6.1%        |
|     [v0.4.0]     |  5.58 s   |  5.81 s   |  179.08 Hz   |     +2.0%     |        +8.2%        |
|     [v0.4.1]     |  5.59 s   |  5.81 s   |  178.95 Hz   |     −0.1%     |        +8.1%        |
|     [v0.4.2]     |  5.69 s   |  5.93 s   |  175.78 Hz   |     −1.8%     |        +6.2%        |
|     [v0.4.3]     |  5.67 s   |  5.90 s   |  176.40 Hz   |     +0.4%     |        +6.6%        |
|     [v0.4.4]     |  5.88 s   |  6.11 s   |  170.10 Hz   |     −3.6%     |        +2.8%        |
|     [v0.5.0]     |  5.86 s   |  6.09 s   |  170.56 Hz   |     +0.3%     |        +3.1%        |

*Δ vs Previous and vs NVIDIA Baseline are both computed from Refresh Rate (Hz).*

## Barnes-Hut Performance

Introduced in `v0.4.1`.

|  Version  | Hot Loop  | Lifetime  | Refresh Rate | Δ vs Previous |
|:---------:|:---------:|:---------:|:------------:|:-------------:|
| [v0.4.1]  | 102.93 s  | 103.17 s  |   9.72 Hz    |       —       |
| [v0.4.2]  |  24.34 s  |  24.56 s  |   41.09 Hz   |    +322.7%    |
| [v0.4.3]  |  8.08 s   |  8.32 s   |  123.79 Hz   |    +201.3%    |
| [v0.4.4]  |  2.71 s   |  2.94 s   |  368.73 Hz   |    +197.9%    |
| [v0.5.0]  |  2.71 s   |  2.93 s   |  369.55 Hz   |     +0.2%     |

## Scaling

How each solver's Hot Loop Time and Refresh Rate scale as N grows (see [Benchmark Methodology](BENCHMARKS_SPEC.md#n-count-scaling-test)). All-Pairs is only measured up to 100,000 bodies.

Version: [v0.5.1]

|    N    | size_  | Barnes-Hut Hot Loop | Barnes-Hut Refresh Rate | All-Pairs Hot Loop | All-Pairs Refresh Rate |
|:-------:|:------:|:--------------------:|:------------------------:|:--------------------:|:------------------------:|
| 10,000  | 9,086  |       1.1348 s        |         881.22 Hz         |       0.3727 s        |         2683.43 Hz         |
| 45,000  | 15,000 |       2.2326 s        |         447.91 Hz         |       6.1612 s        |          162.31 Hz         |
| 100,000 | 19,586 |       4.1605 s        |         240.35 Hz         |       29.3488 s       |          34.07 Hz          |
| 300,000 | 28,231 |      12.0383 s        |          83.07 Hz         |          —            |            —              |

[NVIDIA Sample]: https://github.com/NVIDIA/cuda-samples/tree/master/cpp/5_Domain_Specific/nbody
[v0.5.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.5.0...v0.5.1
[v0.5.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.4...v0.5.0
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