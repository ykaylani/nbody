#include <GL/glew.h>
#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

#include "visualizer.h"
#include <cuda_gl_interop.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <cstdio>
#include <cstring>


__global__ void BuildNodeInstances(
    const float4* __restrict__ node_bounds_min,
    const float4* __restrict__ node_bounds_max,
    uint32_t internal_node_count,
    float min_node_extent,
    float* __restrict__ instances, //center.xyz, halfExtent.xyz
    uint32_t max_instances,
    unsigned int* __restrict__ instance_counter)
{
    uint32_t i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= internal_node_count) return;

    float4 min = node_bounds_min[i];
    float4 max = node_bounds_max[i];

    float hfx = 0.5f * (max.x - min.x);
    float hfy = 0.5f * (max.y - min.y);
    float hfz = 0.5f * (max.z - min.z);
    float maxExtent = fmaxf(hfx, fmaxf(hfy, hfz));

    if (maxExtent < min_node_extent) return;

    unsigned int slot = atomicAdd(instance_counter, 1);
    if (slot >= max_instances) return;

    float* out = instances + slot * 6;
    out[0] = 0.5f * (min.x + max.x);
    out[1] = 0.5f * (min.y + max.y);
    out[2] = 0.5f * (min.z + max.z);
    out[3] = hfx;
    out[4] = hfy;
    out[5] = hfz;
}

static const char* kPointVert = R"GLSL(
#version 430 core
layout(location = 0) in vec4 aPosMass;
uniform mat4 uViewProj;
uniform vec3 uCamPos;
uniform float uBasePointSize;
uniform float uRefDist;
uniform float uGlowRadius;
out float vDistNorm;

void main() {
    vec3 worldPos = aPosMass.xyz;
    gl_Position = uViewProj * vec4(worldPos, 1.0);

    vec3 rel = worldPos - uCamPos;
    gl_Position = uViewProj * vec4(rel, 1.0);

    float camDist = max(length(rel), 1.0);
    float massScale = clamp(pow(max(aPosMass.w, 1e-4), 0.15), 0.5, 2.0);
    float sizeAtten = clamp(uRefDist / camDist, 0.3, 4.0);
    gl_PointSize = clamp(uBasePointSize * massScale * sizeAtten, 1.0, 10.0);

    vDistNorm = length(worldPos) / max(uGlowRadius, 1.0);
}
)GLSL";

static const char* kPointFrag = R"GLSL(
#version 430 core
in float vDistNorm;
uniform float uGlowIntensity;
out vec4 FragColor;

void main() {
    vec2 c = gl_PointCoord - vec2(0.5);
    float r2 = dot(c, c);
    if (r2 > 0.25) discard;
    float edge = smoothstep(0.0, 0.25, r2);
    float shape = pow(1.0 - edge, 1.5);
    vec3 color = vec3(0.8, 0.5, 0.2);
    FragColor = vec4(color * shape * uGlowIntensity, 1.0);
}
)GLSL";

static const char* kCubeVert = R"GLSL(
#version 430 core
layout(location = 0) in vec3 aLocalPos;
layout(location = 1) in vec3 aCenter;
layout(location = 2) in vec3 aHalfExtent;
uniform mat4 uViewProj;
uniform vec3 uCamPos;
void main() {
    vec3 worldPos = aCenter + aLocalPos * aHalfExtent;
    gl_Position = uViewProj * vec4(worldPos - uCamPos, 1.0);
}
)GLSL";

static const char* kCubeFrag = R"GLSL(
#version 430 core
out vec4 FragColor;
void main() {
    FragColor = vec4(0.35, 0.55, 0.95, 0.12);
}
)GLSL";

unsigned int Visualizer::CompileShader(const char* vertSrc, const char* fragSrc) {
    auto compile = [](GLenum type, const char* src) {
        unsigned int s = glCreateShader(type);
        glShaderSource(s, 1, &src, nullptr);
        glCompileShader(s);
        int ok = 0;
        glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
        if (!ok) {
            char log[1024];
            glGetShaderInfoLog(s, sizeof(log), nullptr, log);
            std::fprintf(stderr, "Shader compile error: %s\n", log);
        }
        return s;
    };
    unsigned int vs = compile(GL_VERTEX_SHADER, vertSrc);
    unsigned int fs = compile(GL_FRAGMENT_SHADER, fragSrc);
    unsigned int prog = glCreateProgram();
    glAttachShader(prog, vs);
    glAttachShader(prog, fs);
    glLinkProgram(prog);
    int linked = 0;
    glGetProgramiv(prog, GL_LINK_STATUS, &linked);
    if (!linked) {
        char log[1024];
        glGetProgramInfoLog(prog, sizeof(log), nullptr, log);
        std::fprintf(stderr, "Shader link error: %s\n", log);
    }
    glDeleteShader(vs);
    glDeleteShader(fs);
    return prog;
}

bool Visualizer::init(uint32_t max_bodies, uint32_t max_node_instances, int window_w, int window_h) {
    max_node_instances_ = max_node_instances;

    if (!glfwInit()) return false;
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_SAMPLES, 4); // MSAA

    GLFWmonitor* monitor = glfwGetPrimaryMonitor();
    const GLFWvidmode* mode = glfwGetVideoMode(monitor);

    if (monitor && mode) {
        glfwWindowHint(GLFW_DECORATED, GLFW_FALSE);
        glfwWindowHint(GLFW_RED_BITS, mode->redBits);
        glfwWindowHint(GLFW_GREEN_BITS, mode->greenBits);
        glfwWindowHint(GLFW_BLUE_BITS, mode->blueBits);
        glfwWindowHint(GLFW_REFRESH_RATE, mode->refreshRate);

        window_ = glfwCreateWindow(mode->width, mode->height, "nbody", nullptr, nullptr);

        if (window_) {
            int xpos = 0, ypos = 0;
            glfwGetMonitorPos(monitor, &xpos, &ypos);
            glfwSetWindowPos(window_, xpos, ypos);
        }
    } else {
        window_ = glfwCreateWindow(window_w, window_h, "nbody", nullptr, nullptr);
    }

    if (!window_) { glfwTerminate(); return false; }
    glfwMakeContextCurrent(window_);
    glfwSwapInterval(0);

    glfwSetWindowUserPointer(window_, this);
    glfwSetMouseButtonCallback(window_, MouseButtonCallback);
    glfwSetCursorPosCallback(window_, CursorPosCallback);

    glewExperimental = GL_TRUE;
    if (glewInit() != GLEW_OK) return false;

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_PROGRAM_POINT_SIZE);
    glEnable(GL_BLEND);
    glEnable(GL_MULTISAMPLE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.02f, 0.02f, 0.04f, 1.0f);

    glGenVertexArrays(1, &point_vao_);
    glGenBuffers(1, &position_vbo_);
    glBindVertexArray(point_vao_);
    glBindBuffer(GL_ARRAY_BUFFER, position_vbo_);
    glBufferData(GL_ARRAY_BUFFER, max_bodies * sizeof(float4), nullptr, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, sizeof(float4), (void*)0);
    glEnableVertexAttribArray(0);
    glBindVertexArray(0);

    cudaGraphicsGLRegisterBuffer(&cuda_position_res_, position_vbo_, cudaGraphicsMapFlagsWriteDiscard);

    static const float cubeVerts[8 * 3] = {
        -1,-1,-1,  1,-1,-1,  1,1,-1,  -1,1,-1,
        -1,-1, 1,  1,-1, 1,  1,1, 1,  -1,1, 1,
    };
    static const unsigned int cubeEdges[24] = {
        0,1, 1,2, 2,3, 3,0,   4,5, 5,6, 6,7, 7,4,   0,4, 1,5, 2,6, 3,7
    };

    glGenVertexArrays(1, &cube_vao_);
    glBindVertexArray(cube_vao_);

    glGenBuffers(1, &cube_vbo_);
    glBindBuffer(GL_ARRAY_BUFFER, cube_vbo_);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVerts), cubeVerts, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    glGenBuffers(1, &cube_ebo_);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cube_ebo_);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(cubeEdges), cubeEdges, GL_STATIC_DRAW);

    glGenBuffers(1, &node_instance_vbo_);
    glBindBuffer(GL_ARRAY_BUFFER, node_instance_vbo_);
    glBufferData(GL_ARRAY_BUFFER, max_node_instances * 6 * sizeof(float), nullptr, GL_DYNAMIC_DRAW);

    // center (location 1)
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(1);
    glVertexAttribDivisor(1, 1);

    // halfExtent (location 2)
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(2);
    glVertexAttribDivisor(2, 1);

    glBindVertexArray(0);

    cudaGraphicsGLRegisterBuffer(&cuda_node_instance_res_, node_instance_vbo_, cudaGraphicsMapFlagsWriteDiscard);
    cudaMalloc(&instance_counter_, sizeof(unsigned int));

    point_shader_ = CompileShader(kPointVert, kPointFrag);
    cube_shader_ = CompileShader(kCubeVert, kCubeFrag);

    return true;
}

void Visualizer::Shutdown() {
    if (cuda_position_res_) cudaGraphicsUnregisterResource(cuda_position_res_);
    if (cuda_node_instance_res_) cudaGraphicsUnregisterResource(cuda_node_instance_res_);
    if (instance_counter_) cudaFree(instance_counter_);
    if (window_) glfwDestroyWindow(window_);
    glfwTerminate();
}

bool Visualizer::window_close() const {
    return window_ && glfwWindowShouldClose(window_);
}

void Visualizer::PollEvents() { glfwPollEvents(); }

void Visualizer::MouseButtonCallback(GLFWwindow* window, int button, int action, int /*mods*/) {
    auto* self = static_cast<Visualizer*>(glfwGetWindowUserPointer(window));
    if (!self || button != GLFW_MOUSE_BUTTON_LEFT) return;

    if (action == GLFW_PRESS) {
        self->left_mouse_down_ = true;
        glfwGetCursorPos(window, &self->last_mouse_x_, &self->last_mouse_y_);
        glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    } else if (action == GLFW_RELEASE) {
        self->left_mouse_down_ = false;
        glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }
}

void Visualizer::CursorPosCallback(GLFWwindow* window, double xpos, double ypos) {
    auto* self = static_cast<Visualizer*>(glfwGetWindowUserPointer(window));
    if (!self) return;

    double dx = xpos - self->last_mouse_x_;
    double dy = self->last_mouse_y_ - ypos;
    self->last_mouse_x_ = xpos;
    self->last_mouse_y_ = ypos;

    if (!self->left_mouse_down_) return;

    self->cam_yaw_   += static_cast<float>(dx) * self->mouse_sensitivity_;
    self->cam_pitch_ += static_cast<float>(dy) * self->mouse_sensitivity_;

    if (self->cam_pitch_ > 89.0f) self->cam_pitch_ = 89.0f;
    if (self->cam_pitch_ < -89.0f) self->cam_pitch_ = -89.0f;
}

void Visualizer::UpdateCamera(float dt) {
    float yaw_rad = glm::radians(cam_yaw_);
    float pitch_rad = glm::radians(cam_pitch_);
    glm::vec3 front(cosf(yaw_rad) * cosf(pitch_rad), sinf(pitch_rad), sinf(yaw_rad) * cosf(pitch_rad));
    front = glm::normalize(front);

    glm::vec3 world_up(0.0f, 1.0f, 0.0f);
    glm::vec3 right = glm::normalize(glm::cross(front, world_up));
    glm::vec3 up = glm::normalize(glm::cross(right, front));

    glm::vec3 pos(cam_pos_[0], cam_pos_[1], cam_pos_[2]);
    glm::vec3 move(0.0f);
    if (glfwGetKey(window_, GLFW_KEY_W) == GLFW_PRESS) move += front * dt;
    if (glfwGetKey(window_, GLFW_KEY_S) == GLFW_PRESS) move -= front * dt;
    if (glfwGetKey(window_, GLFW_KEY_A) == GLFW_PRESS) move -= right * dt;
    if (glfwGetKey(window_, GLFW_KEY_D) == GLFW_PRESS) move += right * dt;

    if (glm::length(move) > 0.0f) {
        pos += glm::normalize(move) * (move_speed_ * 0.02f);
    }
    cam_pos_[0] = pos.x; cam_pos_[1] = pos.y; cam_pos_[2] = pos.z;

    glm::mat4 view = glm::lookAt(glm::vec3(0.0f), front, up);

    int fb_w = 1, fb_h = 1;
    glfwGetFramebufferSize(window_, &fb_w, &fb_h);
    float aspect = fb_h > 0 ? static_cast<float>(fb_w) / static_cast<float>(fb_h) : 1.0f;
    glm::mat4 proj = glm::perspective(glm::radians(60.0f), aspect, 100.0f, 10000000.0f);

    glm::mat4 vp = proj * view;
    std::memcpy(view_proj_, glm::value_ptr(vp), sizeof(view_proj_));
}

void Visualizer::RenderFrame(const float4* d_positions, uint32_t body_count, const float4* d_node_bounds_min, const float4* d_node_bounds_max, uint32_t internal_node_count, float min_node_extent, bool show_tree, cudaStream_t stream) {
    float4* mapped_positions = nullptr;
    size_t mapped_size = 0;
    cudaGraphicsMapResources(1, &cuda_position_res_, stream);
    cudaGraphicsResourceGetMappedPointer((void**)&mapped_positions, &mapped_size, cuda_position_res_);
    cudaMemcpyAsync(mapped_positions, d_positions, body_count * sizeof(float4), cudaMemcpyDeviceToDevice, stream);
    cudaGraphicsUnmapResources(1, &cuda_position_res_, stream);

    unsigned int num_instances = 0;
    if (show_tree && internal_node_count > 0) {
        cudaMemsetAsync(instance_counter_, 0, sizeof(unsigned int), stream);

        float* mapped_instances = nullptr;
        cudaGraphicsMapResources(1, &cuda_node_instance_res_, stream);
        cudaGraphicsResourceGetMappedPointer((void**)&mapped_instances, &mapped_size, cuda_node_instance_res_);

        int threads = 256;
        int blocks = (internal_node_count + threads - 1) / threads;
        BuildNodeInstances<<<blocks, threads, 0, stream>>>(d_node_bounds_min, d_node_bounds_max, internal_node_count, min_node_extent, mapped_instances, max_node_instances_, instance_counter_);

        cudaGraphicsUnmapResources(1, &cuda_node_instance_res_, stream);

        cudaMemcpyAsync(&num_instances, instance_counter_, sizeof(unsigned int), cudaMemcpyDeviceToHost, stream);
        cudaStreamSynchronize(stream);
        if (num_instances > max_node_instances_) num_instances = max_node_instances_;
    }

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    if (show_tree && num_instances > 0) {
        glDepthMask(GL_FALSE);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glUseProgram(cube_shader_);
        glUniform3f(glGetUniformLocation(cube_shader_, "uCamPos"), cam_pos_[0], cam_pos_[1], cam_pos_[2]);
        glUniformMatrix4fv(glGetUniformLocation(cube_shader_, "uViewProj"), 1, GL_FALSE, view_proj_);
        glBindVertexArray(cube_vao_);
        glDrawElementsInstanced(GL_LINES, 24, GL_UNSIGNED_INT, 0, num_instances);
        glDepthMask(GL_TRUE);
    }

    glDepthMask(GL_FALSE);
    glBlendFunc(GL_ONE, GL_ONE);
    glUseProgram(point_shader_);
    glUniformMatrix4fv(glGetUniformLocation(point_shader_, "uViewProj"), 1, GL_FALSE, view_proj_);
    glUniform3f(glGetUniformLocation(point_shader_, "uCamPos"), cam_pos_[0], cam_pos_[1], cam_pos_[2]);
    glUniform1f(glGetUniformLocation(point_shader_, "uBasePointSize"), base_point_size_);
    glUniform1f(glGetUniformLocation(point_shader_, "uRefDist"), point_size_ref_dist_);
    glUniform1f(glGetUniformLocation(point_shader_, "uGlowRadius"), glow_radius_);
    glUniform1f(glGetUniformLocation(point_shader_, "uGlowIntensity"), glow_intensity_);
    glBindVertexArray(point_vao_);
    glDrawArrays(GL_POINTS, 0, body_count);
    glDepthMask(GL_TRUE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // restore default for the next frame

    glfwSwapBuffers(window_);
}
