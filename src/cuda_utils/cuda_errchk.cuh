#ifndef NBODY_CUDA_ERRCHK_CUH
#define NBODY_CUDA_ERRCHK_CUH

#include <stdio.h>
#include <stdlib.h>

#define cudaErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true) {
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

#endif //NBODY_CUDA_ERRCHK_CUH