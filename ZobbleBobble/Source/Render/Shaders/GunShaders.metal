//
//  GunShaders.metal
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"

using namespace metal;

struct GunUniforms {
    float cameraScale;
    float2 camera;
};

kernel void draw_gun(device GunUniforms &uniforms [[buffer(0)]],
                     device float2 &origin [[buffer(1)]],
                     device float2 &size [[buffer(2)]],
                     texture2d<float, access::write> output [[texture(0)]],
                     uint2 gid [[thread_position_in_grid]])
{
    float x = (origin.x - uniforms.camera.x) * uniforms.cameraScale + output.get_width() / 2;
    float y = (origin.y - uniforms.camera.y) * uniforms.cameraScale + output.get_height() / 2;
    float width = size.x * uniforms.cameraScale;
    float height = size.y * uniforms.cameraScale;
    
    if (gid.x < x || gid.x > x + width || gid.y < y || gid.y > y + height) {
        output.write(float4(0), gid);
        return;
    }
    output.write(float4(1, 1, 1, 1), gid);
    return;
}
