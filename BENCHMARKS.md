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
- Hot Loop Time
- Executable Lifetime

## Benchmarks

### Execution Time (all versions)

| Version | Hot Loop Time | Executable Lifetime | Steps / Second (Hz) |
|:-------:|:-------------:|:-------------------:|:-------------------:|
| v0.1.3  |    5.62 s     |       5.95 s        |      177.82 Hz      |
| v0.1.2  |    7.67 s     |       8.00 s        |      130.33 Hz      |
| v0.1.1  |    12.45 s    |       12.72 s       |      80.34 Hz       |
| v0.1.0  |    12.38 s    |       12.67 s       |      80.78 Hz       |

### v0.1.2 N-Count Scaling
This graph shows the hot loop time (in ms) v0.1.2 took for varying N-Counts.

O(n<sup>2</sup>) summation is used, which is correctly shown in the scaling.

![N-Body Simulation Performance](https://quickchart.io/chart?w=800&h=400&bkg=white&c={type:'line',data:{labels:['512','1024','2048','4096','8192','16384','32768','65536','131072'],datasets:[{label:'Execution%20Time%20(milliseconds)',data:[41.06,58.86,96.79,170.98,393.07,1099.71,4186.56,15293.75,60398.06],borderColor:'rgb(54,%20162,%20235)',backgroundColor:'rgba(54,%20162,%20235,%200.2)',fill:true}]},options:{plugins:{title:{display:true,text:'N-Body%20Simulation%20Performance',font:{size:18}}}}})