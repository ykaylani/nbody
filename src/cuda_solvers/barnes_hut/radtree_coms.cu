#include <cuda/__atomic/atomic.h>
#include "radtree_nodes.h"

__global__ void CalculateCOMs(
    RadixTreeInternal* internal_nodes,
    cuda::atomic<int, cuda::thread_scope_device>* flags,
    float4* node_coms,
    float4* node_bounds_min,
    float4* node_bounds_max,
    const uint32_t* __restrict__ sorted_to_original,
    const int32_t* __restrict__ leaf_parents,
    const float4* __restrict__ positions,
    const uint32_t body_count) {

    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= body_count) return;
    uint32_t parent_idx = leaf_parents[idx];

    uint32_t race = 1;

    while (true)
    {
        RadixTreeInternal internal_node = internal_nodes[parent_idx];
        race = flags[parent_idx]++;

        if (race == 0) return;

        int32_t left_child = internal_node.left_child;
        int32_t right_child = internal_node.right_child;

        float left_mass, right_mass;
        float4 left_com, right_com;
        float4 left_bounds_min, right_bounds_min;
        float4 left_bounds_max, right_bounds_max;

        if (left_child < 0) {
            uint32_t leaf_idx = ~left_child;
            uint32_t orig = sorted_to_original[leaf_idx];
            float4 position_left = positions[orig];
            left_mass = position_left.w;
            left_com = {left_mass * position_left.x, left_mass * position_left.y, left_mass * position_left.z, 0};

            left_bounds_min = position_left;
            left_bounds_max = position_left;

        } else {
            float4 child_com = node_coms[left_child];
            left_mass = child_com.w;
            left_com = {left_mass * child_com.x, left_mass * child_com.y, left_mass * child_com.z, 0};

            left_bounds_min = node_bounds_min[left_child];
            left_bounds_max = node_bounds_max[left_child];
        }

        if (right_child < 0) {
            uint32_t leaf_idx = ~right_child;
            uint32_t orig = sorted_to_original[leaf_idx];
            float4 position_right = positions[orig];
            right_mass = position_right.w;
            right_com = {right_mass * position_right.x, right_mass * position_right.y, right_mass * position_right.z, 0};

            right_bounds_min = position_right;
            right_bounds_max = position_right;

        } else {
            float4 child_com = node_coms[right_child];
            right_mass = child_com.w;
            right_com = {right_mass * child_com.x, right_mass * child_com.y, right_mass * child_com.z, 0};

            right_bounds_min = node_bounds_min[right_child];
            right_bounds_max = node_bounds_max[right_child];
        }

        float total_mass = left_mass + right_mass;
        float inv_mass = 1.0f / total_mass;

        node_coms[parent_idx] = {
            (left_com.x + right_com.x) * inv_mass,
            (left_com.y + right_com.y) * inv_mass,
            (left_com.z + right_com.z) * inv_mass,
            total_mass
        };

        node_bounds_min[parent_idx] = {fminf(left_bounds_min.x, right_bounds_min.x), fminf(left_bounds_min.y, right_bounds_min.y), fminf(left_bounds_min.z, right_bounds_min.z), 0};
        node_bounds_max[parent_idx] = {fmaxf(left_bounds_max.x, right_bounds_max.x), fmaxf(left_bounds_max.y, right_bounds_max.y), fmaxf(left_bounds_max.z, right_bounds_max.z), 0};
        if (parent_idx == 0) return;

        __threadfence();

        parent_idx = internal_node.parent;
    }
}