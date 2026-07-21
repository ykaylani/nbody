#include <cuda/__atomic/atomic.h>
#include "radtree_nodes.h"

__global__ void CalculateCOMs(
    RadixTreeInternal* internal_nodes,
    cuda::atomic<int, cuda::thread_scope_device>* flags,
    float3* node_coms,
    float* node_masses,
    float3* node_bounds_min,
    float3* node_bounds_max,
    const uint32_t* __restrict__ sorted_to_original,
    const int32_t* __restrict__ leaf_parents,
    const float3* __restrict__ positions,
    const float* __restrict__ masses,
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
        float3 left_com, right_com;
        float3 left_bounds_min, right_bounds_min;
        float3 left_bounds_max, right_bounds_max;

        if (left_child < 0) {
            uint32_t leaf_idx = ~left_child;
            uint32_t orig = sorted_to_original[leaf_idx];
            left_mass = masses[orig];
            float3 position_left = positions[orig];
            left_com = {left_mass * position_left.x, left_mass * position_left.y, left_mass * position_left.z};

            left_bounds_min = position_left;
            left_bounds_max = position_left;

        } else {
            left_mass = node_masses[left_child];
            left_com = node_coms[left_child];

            left_bounds_min = node_bounds_min[left_child];
            left_bounds_max = node_bounds_max[left_child];
        }

        if (right_child < 0) {
            uint32_t leaf_idx = ~right_child;
            uint32_t orig = sorted_to_original[leaf_idx];
            right_mass = masses[orig];
            float3 position_right = positions[orig];
            right_com = {right_mass * position_right.x, right_mass * position_right.y, right_mass * position_right.z};

            right_bounds_min = position_right;
            right_bounds_max = position_right;

        } else {
            right_mass = node_masses[right_child];
            right_com = node_coms[right_child];

            right_bounds_min = node_bounds_min[right_child];
            right_bounds_max = node_bounds_max[right_child];
        }

        float inv_mass = 1.0f / (left_mass + right_mass);

        node_coms[parent_idx] = {(left_com.x + right_com.x) * inv_mass, (left_com.y + right_com.y) * inv_mass, (left_com.z + right_com.z) * inv_mass};
        node_masses[parent_idx] = left_mass + right_mass;

        node_bounds_min[parent_idx] = {fminf(left_bounds_min.x, right_bounds_min.x), fminf(left_bounds_min.y, right_bounds_min.y), fminf(left_bounds_min.z, right_bounds_min.z)};
        node_bounds_max[parent_idx] = {fmaxf(left_bounds_max.x, right_bounds_max.x),fmaxf(left_bounds_max.y, right_bounds_max.y),fmaxf(left_bounds_max.z, right_bounds_max.z)};
        if (parent_idx == 0) return;

        __threadfence();

        parent_idx = internal_node.parent;
    }
}