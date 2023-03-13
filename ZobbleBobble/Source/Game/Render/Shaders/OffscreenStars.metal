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
                      constant float2 &centerPosition [[buffer(2)]],
                      constant float &radii [[buffer(3)]],
                      constant float &missleRadii [[buffer(4)]],
                      constant Material *materials [[buffer(5)]],
                      constant int &materialCount [[buffer(6)]],
                      texture2d<float, access::write> output [[texture(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float radius = radii * uniforms.cameraScale;
    float missleRadius = missleRadii * uniforms.cameraScale;
    
    float2 starCenter = (position - uniforms.camera) * uniforms.cameraScale;
    float2 renderCenter = (centerPosition - uniforms.camera) * uniforms.cameraScale;
    float2 missleCenter = (float2(position.x, position.y - radii - uniforms.missleOffset) - uniforms.camera) * uniforms.cameraScale;
    
    starCenter.x += output.get_width() / 2;
    starCenter.y += output.get_height() / 2;
    
    renderCenter.x += output.get_width() / 2;
    renderCenter.y += output.get_height() / 2;
    
    missleCenter.x += output.get_width() / 2;
    missleCenter.y += output.get_height() / 2;
    
    float2 uv = float2(gid.x, gid.y);
    float distFromCenter = distance(uv, starCenter);
    float distFromRenderCenter = distance(uv, renderCenter);
    float distFromMissle = distance(uv, missleCenter);
    
    if (distFromCenter > radius/* || distFromMissle < missleRadius*/) {
        return;
    }
    
    if (abs(distFromMissle - missleRadius) < 1) {
        output.write(float4(0, 1, 0, 1), gid);
        return;
    }
    
    // last material is root star material
    for (int i = 0; i < materialCount - 1; i++) {
        Material m = materials[i];
        float mRadiusStart = m.position.x * radius + missleRadius;
        float mRadiusEnd = m.position.y * radius + missleRadius;
        
        if (distFromRenderCenter >= mRadiusStart && distFromRenderCenter <= mRadiusEnd) {
            float4 mColor = float4(m.color) / 255.0;
            output.write(mColor, gid);
            return;
        }
    }
    
    float4 color = float4(materials[materialCount - 1].color) / 255.0;
    output.write(color, gid);
}
