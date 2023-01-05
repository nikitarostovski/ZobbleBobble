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
    float4 purple = float4(29.0/255.0, 17.0/255.0, 53.0/255.0, 1);
    float4 darkBlue = float4(12.0/255.0, 22.0/255.0, 79.0/255.0, 1);
    float4 pink = float4(186.0/255.0, 30.0/255.0, 104.0/255.0, 1);
    float4 lavanda = float4(118.0/255.0, 73.0/255.0, 254.0/255.0, 1);
    
    float4 result = purple;
    for (int i = 0; i < *pointCount; i++) {
        float radius = radii[i] * uniforms.cameraScale * uniforms.textureDownscale;
        float3 col = float4(color[i]).rgb / 255.0;
        float2 pos = (positions[i] - uniforms.camera) * uniforms.textureDownscale * uniforms.cameraScale;
        
        pos.x += output.get_width() / 2;
        pos.y += output.get_height() / 2;
        
        float distFromCenter = distance(float2(gid), pos);
        float distFromRadius = abs(distFromCenter) - abs(radius);
        
        if (abs(distFromRadius) < 0.5) {
            result = float4(1);
        } else if (distFromCenter < radius) {
//            result = float4(col, 1);
            break;
        }
        
        
    }
    output.write(result, gid);
}
