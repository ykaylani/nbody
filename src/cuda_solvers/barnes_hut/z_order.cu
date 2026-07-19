constexpr float c_max_bound = 1048576.0f;
constexpr float c_min_bound = -1048576.0f;
constexpr float c_scale_denominator_inv = 1 / (c_max_bound - c_min_bound);
constexpr float scale = 2097151.0f;

__device__ inline uint64_t Spread21B(uint32_t x) {
    uint64_t val = x & 0x1fffff;
    val = (val | (val << 32)) & 0x1f00000000ffffULL;
    val = (val | (val << 16)) & 0x1f0000ff0000ffULL;
    val = (val | (val << 8))  & 0x100f00f00f00f00fULL;
    val = (val | (val << 4))  & 0x10c30c30c30c30c3ULL;
    val = (val | (val << 2))  & 0x1249249249249249ULL;
    return val;
}

__global__ void EncodeF3A(float3* encode, uint64_t* out, uint32_t count) {
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= count) return;

    float3 process_point = encode[idx];
    float normalized_x = (process_point.x - c_min_bound) * c_scale_denominator_inv;
    float normalized_y = (process_point.y - c_min_bound) * c_scale_denominator_inv;
    float normalized_z = (process_point.z - c_min_bound) * c_scale_denominator_inv;

    normalized_x = fmaxf(0.0f, fminf(1.0f, normalized_x));
    normalized_y = fmaxf(0.0f, fminf(1.0f, normalized_y));
    normalized_z = fmaxf(0.0f, fminf(1.0f, normalized_z));

    uint32_t quantized_x = __float2uint_rn(normalized_x * scale);
    uint32_t quantized_y = __float2uint_rn(normalized_y * scale);
    uint32_t quantized_z = __float2uint_rn(normalized_z * scale);

    uint64_t spaced_x = Spread21B(quantized_x);
    uint64_t spaced_y = Spread21B(quantized_y) << 1;
    uint64_t spaced_z = Spread21B(quantized_z) << 2;

    out[idx] = spaced_x | spaced_y | spaced_z;

}