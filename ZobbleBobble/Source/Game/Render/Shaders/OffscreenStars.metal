//
//  OffscreenStars.metal
//  ZobbleBobble
//
//  Created by Rost on 30.01.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

struct StarUniforms {
    float cameraScale;
    float2 camera;
};

struct Material {
    uchar4 color;
    float2 position;
    float weight;
};

kernel void draw_star(constant StarUniforms &uniforms [[buffer(0)]],
                      constant float2 &position [[buffer(1)]],
                      constant float &radii [[buffer(2)]],
                      constant uchar4 &mainColor [[buffer(3)]],
                      constant Material *materials [[buffer(4)]],
                      constant int &materialCount [[buffer(5)]],
                      texture2d<float, access::write> output [[texture(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float radius = radii * uniforms.cameraScale;
    float2 center = (position - uniforms.camera) * uniforms.cameraScale;
    center.x += output.get_width() / 2;
    center.y += output.get_height() / 2;
    
    float2 uv = float2(gid.x, gid.y);
    float distFromCenter = distance(uv, center);
    if (distFromCenter > radius) {
        return;
    }
    
    for (int i = 0; i < materialCount; i++) {
        Material m = materials[i];
        float mRadiusStart = m.position.x * radius;
        float mRadiusEnd = m.position.y * radius;
        
        if (distFromCenter >= mRadiusStart && distFromCenter <= mRadiusEnd) {
            float4 mColor = float4(m.color) / 255.0;
            output.write(mColor, gid);
            return;
        }
    }
    
    float4 color = float4(mainColor) / 255.0;
    output.write(color, gid);
}
