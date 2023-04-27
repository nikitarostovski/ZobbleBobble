//
//  OffscreenStars.metal
//  ZobbleBobble
//
//  Created by Rost on 30.01.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"

#define HALF_SCREEN float2(output.get_width() / 2, output.get_height() / 2);

using namespace metal;

struct StarUniforms {
    float cameraScale;
    float2 camera;
};

struct Material {
    uchar4 color;
    float2 position;
};

kernel void draw_star(constant StarUniforms &uniforms [[buffer(0)]],
                      constant float2 &starCenter [[buffer(1)]],
                      constant float2 &missleCenter [[buffer(2)]],
                      constant float2 &renderCenter [[buffer(3)]],
                      constant float &starRadius [[buffer(4)]],
                      constant float &notchRadius [[buffer(5)]],
                      constant Material *materials [[buffer(6)]],
                      constant int &materialCount [[buffer(7)]],
                      texture2d<float, access::write> output [[texture(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float sr = starRadius * uniforms.cameraScale;
    float nr = notchRadius * uniforms.cameraScale;
    
    float2 sc = (starCenter - uniforms.camera) * uniforms.cameraScale + HALF_SCREEN;
    float2 rc = (renderCenter - uniforms.camera) * uniforms.cameraScale + HALF_SCREEN;
    float2 nc = (missleCenter - uniforms.camera) * uniforms.cameraScale + HALF_SCREEN;
    
    float2 uv = float2(gid.x, gid.y);
    
    float dsc = distance(uv, sc);
    float drc = distance(uv, rc);
    float dnc = distance(uv, nc);
    
    // star masking
    if (dsc > sr || dnc <= nr) {
        return;
    }
    
    // last material is root star material
    for (int i = 0; i < materialCount - 1; i++) {
        Material m = materials[i];
        float mRadiusStart = m.position.x * sr + nr;
        float mRadiusEnd = m.position.y * sr + nr;

        if (drc >= mRadiusStart && drc <= mRadiusEnd) {
            float4 mColor = float4(m.color) / 255.0;
            output.write(mColor, gid);
            return;
        }
    }

    float4 color = float4(materials[materialCount - 1].color) / 255.0;
    output.write(color, gid);
}
