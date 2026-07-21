#include "radtree_nodes.h"

__device__ inline int32_t LongestCommonPrefix(int32_t i, int32_t j, const uint64_t* codes, int32_t body_count) {
    if (i < 0 || i >= body_count || j < 0 || j >= body_count) return -1;

    uint64_t code_i = codes[i];
    uint64_t code_j = codes[j];

    if (code_i != code_j) return __clzll(code_i ^ code_j);
    return 64 + __clz(i ^ j);
}

__global__ void BuildKarrasTrie(const uint64_t* __restrict__ codes, RadixTreeInternal* internal_nodes, int32_t* leaf_parents, const int32_t body_count) {
    int32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= body_count - 1) return;

    int32_t lcp_left = LongestCommonPrefix(idx, idx - 1, codes, body_count);
    int32_t lcp_right = LongestCommonPrefix(idx, idx + 1, codes, body_count);

    int32_t direction = (lcp_left > lcp_right) ? -1 : 1;
    int32_t minimum = LongestCommonPrefix(idx, idx - direction, codes, body_count);

    int32_t upper_bound = 2;
    while (LongestCommonPrefix(idx, idx + direction * upper_bound, codes, body_count) > minimum) {
        upper_bound *= 2;
    }

    int32_t probe = 0;
    for (int32_t t = upper_bound / 2; t >= 1; t /= 2) {
        if (LongestCommonPrefix(idx, idx + (probe + t) * direction, codes, body_count) > minimum) {
            probe += t;
        }
    }
    int32_t child = idx + probe * direction;

    int32_t delta_node = LongestCommonPrefix(idx, child, codes, body_count);
    int32_t s = 0;
    int32_t t_step = probe;

    do {
        t_step = (t_step + 1) >> 1;
        if (LongestCommonPrefix(idx, idx + (s + t_step) * direction, codes, body_count) > delta_node) {
            s += t_step;
        }
    } while (t_step > 1);

    int32_t gamma = idx + s * direction + min(direction, 0);

    int32_t min_idx_child = min(idx, child);
    int32_t max_idx_child = max(idx, child);

    int32_t left_idx = (min_idx_child == gamma) ? ~gamma : gamma;
    int32_t right_idx = (max_idx_child == gamma + 1) ? ~(gamma + 1) : gamma + 1;

    internal_nodes[idx].left_child = left_idx;
    internal_nodes[idx].right_child = right_idx;

    if (left_idx < 0) {
        leaf_parents[~left_idx] = idx;
    } else {
        internal_nodes[left_idx].parent = idx;
    }

    if (right_idx < 0) {
        leaf_parents[~right_idx] = idx;
    } else {
        internal_nodes[right_idx].parent = idx;
    }
}