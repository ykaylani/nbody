# Performance Benchmarks
All notable benchmarks done with this project will be documented in this file.
## Testing Methodology
To maintain consistency, every version is profiled using the exact same initial conditions and simulation parameters:

### Simulation Parameters
- N-Count: 45,000
- Delta Time: 0.02s
- Duration: 1000 Steps (20 physical seconds)
- Distribution: Random Cube (seed 1)
Execution: Each version is run 5 times, dropping the highest and lowest anomalies, with the average of the remaining 3 runs recorded.

### Hardware Environment
- OS: Windows 11
- CPU: AMD Ryzen 5 5600
- GPU: NVIDIA GeForce RTX 4060 8GB
- RAM: 16GB DDR4-3200 CL16

### Measured Values
- Time in Hot loop
- Total Executable Runtime

## Benchmarks

| Version | Hot loop Time | Total Executable Time | Refresh Rate (Hotloop) |
| :---: | :---: | :---: | :---: |
| v0.1.2 | 7.67 s | 8.00 s | 130.33 Hz |
| v0.1.1 | 12.45 s | 12.72 s | 80.34 Hz |
| v0.1.0 | 12.38 s | 12.67 s | 80.78 Hz |