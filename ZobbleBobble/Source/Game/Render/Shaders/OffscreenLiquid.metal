//
//  OffscreenLiquid.metal
//  ZobbleBobble
//
//  Created by Rost on 25.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"

#define VIEWPORT_SIZE 2

using namespace metal;

struct LiquidUniforms {
    float particleRadius;
    float textureDownscale;
    float alphaTextureRadiusModifier;
    float movementTextureRadiusModifier;
    float cameraScale;
    float2 camera;
};

struct MetaballVertexOutput {
    float4 position [[position]];
    float3 color;
    float radius [[point_size]];
};

float2 convertPosition(float2 pos, float outWidth, float outHeight, LiquidUniforms uniforms, bool shouldDownscale) {
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
                     device float const &fadeMultiplier [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    // TODO: check if only red channel needs to be faded
    float4 oldColor = input.read(gid);
    oldColor.r = oldColor.r * fadeMultiplier;
    oldColor.g = 0;
    oldColor.b = 0;
    oldColor.a = 0;
    output.write(oldColor, gid);
}

vertex MetaballVertexOutput metaballs_vertex(device LiquidUniforms const &uniforms [[buffer(0)]],
                                             device float2 const* positions [[buffer(1)]],
                                             device float2 const* velocities [[buffer(2)]],
                                             device uchar4 const* colors [[buffer(3)]],
                                             device float2 const &textureSize [[buffer(4)]],
                                             device uchar4 const &mainColor [[buffer(5)]],
                                             uint vertexID [[vertex_id]]) {
    MetaballVertexOutput r;
    uchar4 color = colors[vertexID];

    if (color.a != mainColor.a) {
        r.radius = -1;
        r.position = float4(0, 0, 0, -1);
        return r;
    }
    
    
    float2 pos = convertPosition(positions[vertexID], textureSize.x, textureSize.y, uniforms, true) * VIEWPORT_SIZE / textureSize - VIEWPORT_SIZE / 2;
    pos.y *= -1;
    float radius = getRadius(uniforms, true) * VIEWPORT_SIZE;
    
//    float velocity = length(velocities[vertexID]);
//    float3 resultColor = float4(colors[vertexID]).rgb / 255.0 + velocity / 500.0;

    r.color = float3(color.rgb) / 255.0;
    r.position = float4(pos, 0, 1);
    r.radius = radius * uniforms.alphaTextureRadiusModifier;
    return r;
}

fragment float4 metaballs_fragment(device LiquidUniforms const &uniforms [[buffer(0)]],
                                   MetaballVertexOutput in [[stage_in]],
                                   float2 pointCoord [[point_coord]]) {

    if (in.radius < 0 || in.position.w < 0) {
        discard_fragment();
    }
    
    float dist = length(pointCoord - float2(0.5));
    float alphaRadius = dist;
    float movementRadius = dist * uniforms.movementTextureRadiusModifier;
    
    float alpha = 1 - smoothstep(0, 1, alphaRadius);
    float green = in.color.r * (1 - smoothstep(0, 1, movementRadius));
    float blue = in.color.g * (1 - smoothstep(0, 1, movementRadius));
    
    return float4(alpha, green, blue, 0);
}

kernel void threshold_filter(texture2d<float, access::sample> alphaInput [[texture(0)]],
                             texture2d<float, access::write> output [[texture(1)]],
                             device uchar4 const &materialColor [[buffer(0)]],
                             device uchar4 const &materialAuxColor [[buffer(1)]],
                             device float const &threshold [[buffer(2)]],
                             device float const &movementColorThreshold [[buffer(3)]],
                             sampler nearestSampler [[sampler(0)]],
                             sampler linearSampler [[sampler(1)]],
                             uint2 gid [[thread_position_in_grid]])
{
    float2 coord = float2(gid);
    coord.x /= output.get_width();
    coord.y /= output.get_height();
    
    float4 oldColor = float4(materialColor) / 255.0;
    float4 alphaColor = alphaInput.sample(linearSampler, coord);
    
    float alpha = alphaColor.r;
    float green = alphaColor.g;
    float blue = alphaColor.b;
    
    if (alpha > threshold) {
        float4 col;
        
        if (abs(green - 0.5) < movementColorThreshold && abs(blue - 0.5) < movementColorThreshold) {
            col = float4(materialAuxColor) / 255.0;
            col.a = 1;
        } else {
            col = float4(oldColor.rgb, 1);
        }
        output.write(col, gid);
        return;
    }
    output.write(float4(0), gid);
}
