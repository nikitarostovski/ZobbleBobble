//
//  Background.metal
//  ZobbleBobble
//
//  Created by Rost on 03.01.2023.
//

#include <metal_stdlib>
using namespace metal;

struct BackgroundUniforms {
    float textureDownscale;
    float cameraScale;
    float2 camera;
};

kernel void fill_background(constant BackgroundUniforms &uniforms [[buffer(0)]],
                             constant float2 *positions [[buffer(1)]],
                             constant float *radii [[buffer(2)]],
                             constant uchar4 *color [[buffer(3)]],
                             constant int *pointCount [[buffer(4)]],
                             texture2d<float, access::write> output [[texture(0)]],
                             uint2 gid [[thread_position_in_grid]])
{
    float3 purple = float3(29.0/255.0, 17.0/255.0, 53.0/255.0);
    
    float3 result = purple;
    
    for (int i = 0; i < *pointCount; i++) {
        float radius = radii[i] * uniforms.cameraScale * uniforms.textureDownscale;
        float3 col = float4(color[i]).rgb / 255.0;
        float2 pos = (positions[i] - uniforms.camera) * uniforms.textureDownscale * uniforms.cameraScale;
        
        pos.x += output.get_width() / 2;
        pos.y += output.get_height() / 2;
        
        float distFromCenter = distance(float2(gid), pos);
        float distFromRadius = abs(distFromCenter) - abs(radius);
        
        if (abs(distFromRadius) < 0.5) {
            result = float3(0.5);
            break;
        } else if (distFromCenter < radius) {
            float p = 1.0 - distFromCenter / radius;
            result = mix(col, purple, p + 0.75);
            break;
        }
    }
    output.write(float4(result, 1), gid);
}
