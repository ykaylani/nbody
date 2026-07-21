# Changelog
All notable changes to this project will be documented in this file.

> **Versioning Note:** On 2026-07-19, historical tags `v0.1.3` through `v0.1.6` were retroactively updated to `v0.2.0` through `v0.4.0`. This was done to properly align with Semantic Versioning, as those releases contained breaking changes to the public API and data semantics.

## [0.4.2] - 2026-07-21
### Added
- Leaf node bucketing in Barnes-Hut strategy (performance improvement)

## [0.4.1] - 2026-07-21
### Added
- Barnes-Hut Solver Strategy (though it's currently very inefficient)

### Fixed
- Decoupled time tracking from CUDA error-checking (bugfix)

## [0.4.0] - 2026-07-18
### Added
- Framework for solver strategies (All Pairs, Barnes-Hut, etc.)
### Changed
- `SceneDescription` structure separated into `SceneDescription` and `SceneSettings` structures
- Changed name `Run()` of all-pairs kernel to `AllPairsKernel()` and added header file

## [0.3.0] - 2026-07-18
### Added
- VTP data export functionality
- RandomSphere distribution
- Plummer sphere distribution
### Changed
- Reworked ping-pong buffers and `cudaDeviceSynchronize()` calls to improve efficiency
- Simplified data movement in force kernel `Run()`
### Removed
- `equal_mass_` flag removed (negligible gain for too much code complexity)

## [0.2.1] - 2026-07-17
### Added
- `#pragma unroll` in kernel loops
- Framework for data export formats
- XDMF data export

## [0.2.0] - 2026-07-17
### Changed
- Use of mass instead of inverse mass to reduce divisions in hot loop
- Reworked initial condition distribution to be more readable
- Simplified shared memory movement

### Removed
- Memory usage metric (locked project to Windows devices)

## [0.1.2] - 2026-07-16
### Added
- Shared memory tiling in force kernel
- Framework for initial condition distributions
- Distance softening as a scene description field
- Distribution as a scene description field
- Links to tags in CHANGELOG.md

### Fixed
- Initial step data export overwriting bug in main loop
- Inconsistent naming schemes of variables to snake_case

## [0.1.1] - 2026-07-16
### Added
- Flag for CUDA error checks
- Flag for data export

### Changed
- Set data export directory to the executable directory
- Replace commented-out data export and error-checking code with conditional branches controlled by flags

## [0.1.0] - 2026-07-14
### Added
- Initial project (CUDA N-Body simulation)
- CSV data logging for visualization (currently commented out for performance testing)
- Performance benchmarking via `std::chrono`
- Memory usage tracking via `GetProcessMemoryInfo()`

[0.4.2]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.1...v0.4.2
[0.4.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.4.0...v0.4.1
[0.4.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.3.0...v0.4.0
[0.3.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.2.1...v0.3.0
[0.2.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.2.0...v0.2.1
[0.2.0]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.2...v0.2.0
[0.1.2]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.1...v0.1.2
[0.1.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.0...v0.1.1
[0.1.0]: https://gitlab.com/yks4892825/nbody/-/tags/v0.1.0