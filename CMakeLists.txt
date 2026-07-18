cmake_minimum_required(VERSION 4.2)
project(nbody CUDA)

set(CMAKE_CUDA_STANDARD 20)

add_executable(nbody src/main.cu
        src/cuda_solvers/all_pairs.cu)

set_target_properties(nbody PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        INTERPROCEDURAL_OPTIMIZATION ON
)

target_compile_options(nbody PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math>
)