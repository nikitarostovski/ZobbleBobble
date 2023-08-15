//
//  CommonShaders.metal
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

void drawMetaball(texture2d<float, access::read> input, texture2d<float, access::write> output, texture2d<float, access::write> colorOutput, float2 center, float radius, float3 color) {
    for (int y = floor(center.y - 2 * radius); y < ceil(center.y + 2 * radius); y++) {
        for (int x = floor(center.x - 2 * radius); x < ceil(center.x + 2 * radius); x++) {
            uint2 coords = uint2(x, y);
            float dist = distance(float2(x, y), center);
            
            // TODO: wtf?
//            float alpha = smoothstep(0, 1, 1 - dist / radius);
            float alpha = 1 - dist / radius / 2;
            
            float4 oldColor = input.read(coords);
            float4 alphaColor = float4(alpha + oldColor.r,
                                       alpha + oldColor.g,
                                       alpha + oldColor.b,
                                       0);
            
            output.write(alphaColor, coords);
            colorOutput.write(float4(color.r, color.g, color.b, 1), coords);
        }
    }
}

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
