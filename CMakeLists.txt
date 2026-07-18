cmake_minimum_required(VERSION 4.2)
project(nbody CUDA)

set(CMAKE_CUDA_STANDARD 20)

add_executable(nbody main.cu
        src/data/body_data.h
        src/data/scene_desc.h
        src/cuda_solvers/all_pairs.cu
        src/strats/exporters.h
        src/strats/solvers.h
        src/data/scene_settings.h
        src/cuda_solvers/all_pairs.cuh)

set_target_properties(nbody PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        INTERPROCEDURAL_OPTIMIZATION ON
)

target_compile_options(nbody PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math>
)