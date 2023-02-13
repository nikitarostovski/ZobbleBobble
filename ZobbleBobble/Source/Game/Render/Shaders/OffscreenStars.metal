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
    float transitionProgress;
    float missleOffset; // vertical
    float2 camera;
};

struct Material {
    uchar4 color;
    float2 position;
};

kernel void draw_star(constant StarUniforms &uniforms [[buffer(0)]],
                      constant float2 &position [[buffer(1)]],
                      constant float &radii [[buffer(2)]],
                      constant float &missleRadii [[buffer(3)]],
                      constant uchar4 &mainColor [[buffer(4)]],
                      constant Material *materials [[buffer(5)]],
                      constant int &materialCount [[buffer(6)]],
                      texture2d<float, access::write> output [[texture(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float radius = radii * uniforms.cameraScale;
    float missleRadius = missleRadii * uniforms.cameraScale;
    
    float2 starCenter = (position - uniforms.camera) * uniforms.cameraScale;
    float2 missleCenter = (float2(position.x, position.y - radii - uniforms.missleOffset) - uniforms.camera) * uniforms.cameraScale;
    
    
//    float2 centerMenu = starCenter;
//    float2 centerLevel = (float2(position.x, position.y - radii) - uniforms.camera) * uniforms.cameraScale;
//
//    float2 center = centerLevel + (centerMenu - centerLevel) * uniforms.transitionProgress;
//    center.x += output.get_width() / 2;
//    center.y += output.get_height() / 2;
    
    starCenter.x += output.get_width() / 2;
    starCenter.y += output.get_height() / 2;
    
    missleCenter.x += output.get_width() / 2;
    missleCenter.y += output.get_height() / 2;
    
    float2 uv = float2(gid.x, gid.y);
    float distFromCenter = distance(uv, starCenter);
    float distFromMissle = distance(uv, missleCenter);
    
    if (distFromCenter > radius || distFromMissle < missleRadius) {
        return;
    }
    
    float distFromDrawCenter = distFromCenter;//distance(uv, center);
    
    for (int i = 0; i < materialCount; i++) {
        Material m = materials[i];
        float mRadiusStart = m.position.x * radius;
        float mRadiusEnd = m.position.y * radius;
        
        if (distFromDrawCenter >= mRadiusStart && distFromDrawCenter <= mRadiusEnd) {
            float4 mColor = float4(m.color) / 255.0;
            output.write(mColor, gid);
            return;
        }
    }
    
    float4 color = float4(mainColor) / 255.0;
    output.write(color, gid);
}
