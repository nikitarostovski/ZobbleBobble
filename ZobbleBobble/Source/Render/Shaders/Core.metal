//
//  Core.metal
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.09.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

#define COLOR_CORE float4(0.9, 0.9, 0.9, 1)
#define COLOR_MANTLE float4(0.85, 0.8, 0.15, 1)
#define COLOR_CRUST float4(0.9, 0.5, 0.25, 1)

struct CoreUniforms {
    float cameraScale;
    float2 camera;
};

struct Core {
    float2 center;
    float radius;
};

kernel void clear_core(texture2d<float, access::write> output [[texture(0)]], uint2 gid [[thread_position_in_grid]]) {
    output.write(float4(0), gid);
}

kernel void draw_core(texture2d<float, access::write> output [[texture(0)]],
                      device CoreUniforms const &uniforms [[buffer(0)]],
                      device Core const &core [[buffer(1)]],
                      device float const &time [[buffer(2)]],
                      uint2 gid [[thread_position_in_grid]]) {
    
    float2 pos = (core.center - uniforms.camera) * uniforms.cameraScale;
    float radius = core.radius * uniforms.cameraScale;

    float2 textureSize = float2(output.get_width(), output.get_height());
    ushort2 pixel = ushort2(pos + textureSize / 2);

    float distToCore = length(float2(gid) - float2(pixel));

    float anim1 = (sin(time) + 1) / 2;
    float anim2 = (sin(time * 2) + 1) / 2;
    
    float shift1 = anim1 * (radius * 0.1);
    float shift2 = anim2 * (radius * 0.2);
    
    float threshold1 = radius * 0.25 + shift1;
    float threshold2 = radius * 0.65 + shift2;
    
    if (distToCore > radius) { return; }
    
    float4 color;
    if (distToCore <= threshold1) {
        color = COLOR_CORE;
    } else if (distToCore <= threshold2) {
        color = COLOR_MANTLE;
        float m = (threshold2 - distToCore) / (threshold2 - threshold1) * 2;
        m = min(1.0, max(0.7, m));
        color.rgb *= m;
    } else {
        color = COLOR_CRUST;
        float m = (radius - distToCore) / (radius - threshold2) * 1;
        m = min(1.0, max(0.2, m));
        color.rgb *= m;
    }
    output.write(color, gid);
}
