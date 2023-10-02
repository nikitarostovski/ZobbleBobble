//
//  Core.metal
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.09.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

#define COLOR_CORE              float4(255.0/255.0, 219/255.0, 0, 1)
#define COLOR_MANTLE_START      float4(255.0/255.0, 169.0/255.0, 4.0/255.0, 1)
#define COLOR_MANTLE_END        float4(238.0/255.0, 123.0/255.0, 6.0/255.0, 1)
#define COLOR_CRUST_START       float4(161.0/255.0, 36.0/255.0, 36.0/255.0, 1)
#define COLOR_CRUST_END         float4(64.0/255.0, 11.0/255.0, 11.0/255.0, 1)

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
        float p = 1 - (threshold2 - distToCore) / (threshold2 - threshold1);
        color = mix(COLOR_MANTLE_START, COLOR_MANTLE_END, float4(p));
    } else {
        float p = 1 - (radius - distToCore) / (radius - threshold2);
        color = mix(COLOR_CRUST_START, COLOR_CRUST_END, float4(p));
    }
    output.write(color, gid);
}
