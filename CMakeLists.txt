cmake_minimum_required(VERSION 4.2)
project(nbody CUDA)

set(CMAKE_CUDA_STANDARD 20)

add_executable(nbody src/main.cu
        src/cuda_solvers/all_pairs/all_pairs.cu

        src/cuda_solvers/barnes_hut/z_order.cu
        src/cuda_solvers/barnes_hut/radtree_build.cu
        src/cuda_solvers/barnes_hut/radtree_coms.cu
        src/cuda_solvers/barnes_hut/radtree_forces.cu

        src/cuda_solvers/diag/mechanical_energy.cu
        src/visualization/visualizer.h
        src/visualization/visualizer.cu
        src/setup.h
        src/strats/energy/energy_exporters.h
        src/strats/energy/energy_calculator.h)

set_target_properties(nbody PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        INTERPROCEDURAL_OPTIMIZATION ON
)

target_compile_options(nbody PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<PLATFORM_ID:Windows>>:-Xcompiler=/Zc:preprocessor>
)

include(FetchContent)
FetchContent_Declare(glfw GIT_REPOSITORY https://github.com/glfw/glfw.git GIT_TAG 3.4)
FetchContent_Declare(glm GIT_REPOSITORY https://github.com/g-truc/glm.git GIT_TAG 1.0.1)
FetchContent_MakeAvailable(glfw glm)
find_package(GLEW REQUIRED)
target_link_libraries(nbody PRIVATE glfw GLEW::GLEW glm::glm)