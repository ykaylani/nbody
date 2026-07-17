# Changelog
All notable changes to this project will be documented in this file.

## [0.1.4] - 2026-07-17
### Added
- `#pragma unroll` in kernel loops
- Framework for data export formats
- XDMF data export

## [0.1.3] - 2026-07-17
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

[0.1.4]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.3...v0.1.4
[0.1.3]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.2...v0.1.3
[0.1.2]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.1...v0.1.2
[0.1.1]: https://gitlab.com/yks4892825/nbody/-/compare/v0.1.0...v0.1.1
[0.1.0]: https://gitlab.com/yks4892825/nbody/-/tags/v0.1.0