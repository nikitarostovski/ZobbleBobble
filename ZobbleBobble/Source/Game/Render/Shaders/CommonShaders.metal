//
//  CommonShaders.metal
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

kernel void fill_clear(texture2d<float, access::write> output [[texture(0)]],
                       uint2 gid [[thread_position_in_grid]]) {
    output.write(float4(0), gid);
}

kernel void upscale_texture(texture2d<float, access::sample> input [[texture(0)]],
                            texture2d<float, access::write> output [[texture(1)]],
                            sampler s [[sampler(0)]],
                            uint2 gid [[thread_position_in_grid]]) {
    float2 coord = float2(gid);
    coord.x /= output.get_width();
    coord.y /= output.get_height();
    float4 oldColor = input.sample(s, coord);

    output.write(oldColor, gid);
    return;
}

float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
