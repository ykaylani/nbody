# Changelog
All notable changes to this project will be documented in this file.

## [0.1.1] - 2026-07-16
### Added
- Flag for CUDA error checks
- Flag for data export

### Changed
- Default data export directory is now the executable directory
- Replaced commented-out data export and error-checking code with conditional branches controlled by flags

## [0.1.0] - 2026-07-14
### Added
- Initial project (CUDA N-Body simulation)
- CSV data logging for visualization (currently commented out for performance testing)
- Performance benchmarking via `std::chrono`
- Memory usage tracking via `GetProcessMemoryInfo()`