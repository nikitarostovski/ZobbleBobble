//
//  OffscreenLiquid.metal
//  ZobbleBobble
//
//  Created by Rost on 25.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

struct LiquidUniforms {
    float particleRadius;
    float textureDownscale;
    float cameraScale;
    float cameraAngle;
    float2 camera;
};

float2 convertPosition(float2 pos, float outWidth, float outHeight, LiquidUniforms uniforms, bool shouldDownscale) {
    float l = length(pos);
    float2 norm = normalize(pos);
    float a = atan2(norm.y, norm.x) + uniforms.cameraAngle;
    float s = sin(a);
    float c = cos(a);
    
    pos.x = l * c;
    pos.y = l * s;
    
    pos -= uniforms.camera;
    
    float2 result;
    if (shouldDownscale) {
        result = pos * uniforms.textureDownscale * uniforms.cameraScale;
    } else {
        result = pos * uniforms.cameraScale;
    }
    
    result.x += outWidth / 2;
    result.y += outHeight / 2;
    
    return result;
}

float getRadius(LiquidUniforms uniforms, bool shouldDownscale) {
    if (shouldDownscale) {
        return uniforms.particleRadius * uniforms.textureDownscale * uniforms.cameraScale;
    } else {
        return uniforms.particleRadius * uniforms.cameraScale;
    }
}

kernel void fade_out(texture2d<float, access::read> input [[texture(0)]],
                     texture2d<float, access::write> output [[texture(1)]],
                     constant float *fadeMultiplier [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    float4 oldColor = input.read(gid);
    oldColor = oldColor * *fadeMultiplier;
    output.write(oldColor, gid);
}

kernel void metaballs(constant LiquidUniforms &uniforms [[buffer(0)]],
                      constant float2 *positions [[buffer(1)]],
                      constant float2 *velocities [[buffer(2)]],
                      constant uchar4 *color [[buffer(3)]],
                      constant int *pointCount [[buffer(4)]],
                      texture2d<float, access::read> input [[texture(0)]],
                      texture2d<float, access::write> output [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float radius = getRadius(uniforms, true);
    int i = gid.x;
    
    float2 pos = convertPosition(positions[i], output.get_width(), output.get_height(), uniforms, true);
    
    drawMetaball(input, output, pos, radius);
}

kernel void fill_particle_colors(constant LiquidUniforms &uniforms [[buffer(0)]],
                                 constant float2 *positions [[buffer(1)]],
                                 constant float2 *velocities [[buffer(2)]],
                                 constant uchar4 *color [[buffer(3)]],
                                 constant int *pointCount [[buffer(4)]],
                                 texture2d<float, access::write> output [[texture(0)]],
                                 uint2 gid [[thread_position_in_grid]])
{
    float radius = getRadius(uniforms, false);
    float3 resultColor = float3(0);
    float minDist = MAXFLOAT;

    for (int i = 0; i < *pointCount; i++) {
        float velocity = length(velocities[i]);
        float3 col = float4(color[i]).rgb / 255.0;
        float2 pos = convertPosition(positions[i], output.get_width(), output.get_height(), uniforms, false);

        float dist = distance(float2(gid), pos);
        bool isInsideCircle = dist <= radius;

        if (dist < minDist || isInsideCircle) {
            minDist = dist;
            resultColor = col + (float3(1) * velocity / 300);
            if (isInsideCircle) {
                break;
            }
        }
    }
    output.write(float4(resultColor, 1), gid);
}

kernel void threshold_filter(texture2d<float, access::sample> alphaInput [[texture(0)]],
                             texture2d<float, access::sample> colorInput [[texture(1)]],
                             texture2d<float, access::write> output [[texture(2)]],
                             sampler nearestSampler [[sampler(0)]],
                             sampler linearSampler [[sampler(1)]],
                             uint2 gid [[thread_position_in_grid]])
{
    float2 coord = float2(gid);
    coord.x /= output.get_width();
    coord.y /= output.get_height();
    
    float4 oldColor = colorInput.sample(nearestSampler, coord);
    float alpha = alphaInput.sample(linearSampler, coord).r;
    
    float4 col1 = float4(oldColor.rgb, 1);
    
    float threshold1 = 0.5;
    
//    output.write(oldColor, gid);
//    return;
//    output.write(float4(alpha, alpha, alpha, 1), gid);
//    return;
    
    if (alpha > threshold1) {
        output.write(col1, gid);
        return;
    }
    output.write(float4(0), gid);
}
