# **nbody Benchmarks**

## **Testing Environment**

* **OS:** Windows 10
* **CPU:** AMD Ryzen 5 5600
* **GPU:** NVIDIA GeForce RTX 4060 8GB
* **RAM:** 16GB DDR4-3200 CL16

## **Tests**

### **Historical Benchmark**

* **N:** 65,535
* **DT:** 0.01s
* **Steps:** 1,000
* **Distribution:** Random Cube (size 15,000)
* **Masses**: 1e17
* **Softening**: 16
* **\[Barnes-Hut\] Acceptance Criterion**: 0.5
* **\[Barnes-Hut\] Leaf Bucket Size**: 16

**Measured Values**:

* **Refresh Rate** (Hz)
*  **vs Previous** (Percentage)

Per solver (All-Pairs and Barnes-Hut, if available)  
All snapshots are measured five times with the average of the middling three taken.

### **Scaling Benchmark**

* **N**: Variable
* **DT**: 0.01s
* **Steps**: 1,000
* **Distribution**: Plummer (Variable Sizing, see below)
* **Masses**: 2.5e16
* **Softening**: 16
* **\[Barnes-Hut\] Acceptance Criterion**: 0.5
* **\[Barnes-Hut\] Leaf Bucket Size**: 16

**Domain Scaling**

the Plummer scale radius is not held constant across N. Packing more bodies into a fixed radius Plummer sphere would raise local density as N grows, shrinking spacing relative to softening. Instead, the scale radius *a* grows with N to hold characteristic density constant:

`a(N) = 15,000 * (N / 45,000)^(1/3)`

|         N         | Plummer radius *a* |
|:-----------------:|:------------------:|
|     2^6 \= 64     |       1,687        |
|   2^10 \= 1,024   |       4,251        |
|   2^12 \= 4,096   |       6,748        |
|  2^14 \= 16,384   |       10,711       |
|  2^16 \= 65,536   |       17,003       |
|  2^17 \= 131,072  |       21,422       |
| 2^20 \= 1,048,576 |       42,844       |
| 2^21 \= 2,097,152 |       53,980       |
| 2^22 \= 4,194,304 |       68,010       |

Note: Maximum radius is 10a.

**Measured Values**:

* **Refresh Rate** (Hz)

Per unique N value: 2^6, 2^10, 2^12, 2^14, 2^16, 2^17, 2^20, 2^21, 2^22  
All-Pairs Measurements end at 2^17  
All snapshots are measured five times with the average of the middling three taken.

### **Energy Benchmark**

* **N**: 4,096
* **DT**: 0.01s
* **Steps**: 50,000
* **Distribution**: Plummer (*a* \= 6,748)
* **Masses**: 2.5e16
* **Softening**: 8
* **\[Barnes-Hut\] Acceptance Criterion**: Variable
* **\[Barnes-Hut\] Leaf Bucket Size**: 16

**Measured Values**:

* **Mechanical Energy** (J)

Per solver: All-Pairs, Barnes-Hut ($\theta$ = 0.3), Barnes-Hut ($\theta$ = 0.5), Barnes-Hut ($\theta$ = 0.7)  
All snapshots are measured five times with the average of the middling three taken at every data point.
