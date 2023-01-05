//
//  OffscreenLiquid.metal
//  ZobbleBobble
//
//  Created by Rost on 25.12.2022.
//

#include <metal_stdlib>
using namespace metal;

struct LiquidUniforms {
    float particleRadius;
    float textureDownscale;
    float cameraScale;
    float2 camera;
};

#define CLAMP(v, min, max) \
    if (v < min) { \
        v = min; \
    } else if (v > max) { \
        v = max; \
    }

kernel void fade_out(texture2d<float, access::read> input [[texture(0)]],
                     texture2d<float, access::write> output [[texture(1)]],
                     constant float *fadeMultiplier [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    float4 oldColor = input.read(gid);
    oldColor.a = oldColor.r * *fadeMultiplier;
    output.write(oldColor, gid);
}

kernel void metaballs(constant LiquidUniforms &uniforms [[buffer(0)]],
                      constant float2 *positions [[buffer(1)]],
                      constant float2 *velocities [[buffer(2)]],
                      constant uchar4 *color [[buffer(3)]],
                      constant int *pointCount [[buffer(4)]],
                      texture2d<float, access::read> input [[texture(0)]],
                      texture2d<float, access::write> output [[texture(1)]],
                      texture2d<float, access::write> colorizedOutput [[texture(2)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float radius = uniforms.particleRadius * uniforms.textureDownscale * uniforms.cameraScale;

    float4 result = input.read(gid);
    float3 resultColor = float3(0);
    float minDist = MAXFLOAT;
    
    for (int i = 0; i < *pointCount; i++) {
        float velocity = length(velocities[i]);
        float3 col = float4(color[i]).rgb / 255.0;
//        col = rgb_to_hsv(col.rgb);
        
        float2 pos = (positions[i] - uniforms.camera) * uniforms.textureDownscale * uniforms.cameraScale;

//        float l = length(pos);
//        float2 norm = normalize(pos);
//        float a = atan2(norm.y, norm.x) + *angle;
//        float s = sin(a);
//        float c = cos(a);
//        pos.x = c * norm.x - s * norm.y;
//        pos.y = s * norm.x + c * norm.y;
//
//        pos *= l;
        
        pos.x += output.get_width() / 2;
        pos.y += output.get_height() / 2;
        
        
        float dist = distance(float2(gid), pos);
        
        
        
        
        if (dist < minDist) {
            minDist = dist;
            resultColor = col + (float3(1) * velocity / 1000);
        }
        if (dist > radius) {
            continue;
        }
        
        float alpha = radius / dist;
        CLAMP(alpha, 0, 1);
        result.a += alpha;
        
    }
    output.write(float4(result.a, result.a, result.a, 1), gid);
    colorizedOutput.write(float4(resultColor, result.a), gid);
}

kernel void threshold_filter(texture2d<float, access::sample> alphaInput [[texture(0)]],
                             texture2d<float, access::sample> colorInput [[texture(1)]],
                             texture2d<float, access::write> output [[texture(2)]],
                             sampler s [[sampler(0)]],
                             uint2 gid [[thread_position_in_grid]])
{
    float2 coord = float2(gid);
    coord.x /= output.get_width();
    coord.y /= output.get_height();
    
    float4 oldColor = colorInput.sample(s, coord);
    float alpha = alphaInput.sample(s, coord).r;
    
    float4 col1 = float4(oldColor.rgb, 1);
    
    float threshold1 = 0.5;
    
//    output.write(float4(alpha, alpha, alpha, 1), gid);
//    return;
    
    if (alpha > threshold1) {
        output.write(col1, gid);
        return;
    }
    output.write(float4(0), gid);
}
