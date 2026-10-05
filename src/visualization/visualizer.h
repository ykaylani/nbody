#ifndef NBODY_VISUALIZER_H
#define NBODY_VISUALIZER_H

#include <cuda_runtime.h>
#include <cstdint>

#include "GLFW/glfw3.h"

struct GLFWWindow;

struct Visualizer {
    bool init(uint32_t max_bodies, uint32_t max_nodes, int32_t window_width = 2560, int32_t window_height = 1440);
    bool window_close() const;

    void Shutdown();
    void PollEvents();
    void UpdateCamera(float dt);

    void RenderFrame(const float4* positions, uint32_t body_count, const float4* node_bounds_min, const float4* node_bounds_max, uint32_t internal_node_count, float node_extent_min, bool show_tree, cudaStream_t stream = 0);
private:
    GLFWwindow* window_ = nullptr;
    unsigned int position_vbo_ = 0, point_vao_ = 0, point_shader_ = 0;
    cudaGraphicsResource* cuda_position_res_ = nullptr;

    unsigned int cube_vao_ = 0, cube_vbo_ = 0, cube_ebo_ = 0, cube_shader_ = 0;
    unsigned int node_instance_vbo_ = 0;
    cudaGraphicsResource* cuda_node_instance_res_ = nullptr;

    unsigned int* instance_counter_ = nullptr; // reset every frame
    uint32_t max_node_instances_ = 0;

    float view_proj_[16];

    float cam_pos_[3] = {0.0f, 16000.0f, 40000.0f};
    float cam_yaw_ = -90.0f;
    float cam_pitch_ = -15.0f;
    float move_speed_ = 3000.0f;
    float mouse_sensitivity_ = 0.12f;

    bool left_mouse_down_ = false;
    double last_mouse_x_ = 0.0;
    double last_mouse_y_ = 0.0;

    float base_point_size_ = 4.0f;
    float point_size_ref_dist_ = 30000.0f;
    float glow_radius_ = 20000.0f;
    float glow_intensity_ = 0.3f;

    unsigned int CompileShader(const char* vertSrc, const char* fragSrc);

    static void MouseButtonCallback(GLFWwindow* window, int button, int action, int mods);
    static void CursorPosCallback(GLFWwindow* window, double xpos, double ypos);
};

#endif //NBODY_VISUALIZER_H