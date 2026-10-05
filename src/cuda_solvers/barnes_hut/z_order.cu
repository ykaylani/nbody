#include <cfloat>
#include <thrust/execution_policy.h>
#include <thrust/transform_reduce.h>

constexpr float scale = 2097151.0f;
constexpr float c_min_extent = 1.0e-20f;
constexpr float c_bounds_padding = 0.125f;

__device__ inline uint64_t Spread21B(uint32_t x) {
    uint64_t val = x & 0x1fffff;
    val = (val | (val << 32)) & 0x1f00000000ffffULL;
    val = (val | (val << 16)) & 0x1f0000ff0000ffULL;
    val = (val | (val << 8))  & 0x100f00f00f00f00fULL;
    val = (val | (val << 4))  & 0x10c30c30c30c30c3ULL;
    val = (val | (val << 2))  & 0x1249249249249249ULL;
    return val;
}

struct SceneBoundsTotal {
    float3 lo;
    float3 hi;
};

struct PositionToBounds {
    __host__ __device__ SceneBoundsTotal operator()(const float4& p) const {
        SceneBoundsTotal b;
        if (isfinite(p.x) && isfinite(p.y) && isfinite(p.z)) {
            b.lo = make_float3(p.x, p.y, p.z);
            b.hi = make_float3(p.x, p.y, p.z);
        } else {
            b.lo = make_float3( FLT_MAX,  FLT_MAX,  FLT_MAX);
            b.hi = make_float3(-FLT_MAX, -FLT_MAX, -FLT_MAX);
        }
        return b;
    }
};

struct MergeBounds {
    __host__ __device__ SceneBoundsTotal operator()(const SceneBoundsTotal& a, const SceneBoundsTotal& b) const {
        SceneBoundsTotal r;
        r.lo = make_float3(fminf(a.lo.x, b.lo.x), fminf(a.lo.y, b.lo.y), fminf(a.lo.z, b.lo.z));
        r.hi = make_float3(fmaxf(a.hi.x, b.hi.x), fmaxf(a.hi.y, b.hi.y), fmaxf(a.hi.z, b.hi.z));
        return r;
    }
};

void SeedSceneBounds(const float4* positions, float4* root_bounds_min, float4* root_bounds_max, uint32_t count) {
    SceneBoundsTotal identity;
    identity.lo = make_float3( FLT_MAX,  FLT_MAX,  FLT_MAX);
    identity.hi = make_float3(-FLT_MAX, -FLT_MAX, -FLT_MAX);

    SceneBoundsTotal b = thrust::transform_reduce(thrust::device, positions, positions + count, PositionToBounds(), identity, MergeBounds());

    float4 lo = make_float4(b.lo.x, b.lo.y, b.lo.z, 0.0f);
    float4 hi = make_float4(b.hi.x, b.hi.y, b.hi.z, 0.0f);
    cudaMemcpy(root_bounds_min, &lo, sizeof(float4), cudaMemcpyHostToDevice);
    cudaMemcpy(root_bounds_max, &hi, sizeof(float4), cudaMemcpyHostToDevice);
}

__global__ void EncodeF3A(float4* encode, uint64_t* out, uint32_t count, const float4* __restrict__ root_bounds_min, const float4* __restrict__ root_bounds_max) {

    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= count) return;

    const float4 lo = root_bounds_min[0];
    const float4 hi = root_bounds_max[0];

    float extent = fmaxf(fmaxf(hi.x - lo.x, hi.y - lo.y), hi.z - lo.z);
    extent = fmaxf(extent, c_min_extent);
    const float pad = extent * c_bounds_padding;
    const float units_to_grid = isfinite(extent) ? scale / (extent + 2.0f * pad) : 0.0f;

    float4 process_point = encode[idx];

    float grid_x = fminf(fmaxf((process_point.x - (lo.x - pad)) * units_to_grid, 0.0f), scale);
    float grid_y = fminf(fmaxf((process_point.y - (lo.y - pad)) * units_to_grid, 0.0f), scale);
    float grid_z = fminf(fmaxf((process_point.z - (lo.z - pad)) * units_to_grid, 0.0f), scale);

    uint32_t quantized_x = __float2uint_rn(grid_x);
    uint32_t quantized_y = __float2uint_rn(grid_y);
    uint32_t quantized_z = __float2uint_rn(grid_z);

    uint64_t spaced_x = Spread21B(quantized_x);
    uint64_t spaced_y = Spread21B(quantized_y) << 1;
    uint64_t spaced_z = Spread21B(quantized_z) << 2;

    out[idx] = spaced_x | spaced_y | spaced_z;

}
