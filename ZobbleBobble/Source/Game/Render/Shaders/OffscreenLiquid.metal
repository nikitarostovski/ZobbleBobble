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
                     device float *fadeMultiplier [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    float4 oldColor = input.read(gid);
    oldColor = oldColor * *fadeMultiplier;
    output.write(oldColor, gid);
}

kernel void crop_alpha_texture(texture2d<float, access::sample> textureA [[texture(0)]],
                               texture2d<float, access::sample> textureB [[texture(1)]],
                               texture2d<float, access::write> outputA [[texture(2)]],
                               texture2d<float, access::write> outputB [[texture(3)]],
                               sampler sampler [[sampler(0)]],
                               uint2 gid [[thread_position_in_grid]]) {
    
    float2 coord = float2(gid);
    coord.x /= outputA.get_width();
    coord.y /= outputA.get_height();
    
    float alphaA = textureA.sample(sampler, coord).r;
    float alphaB = textureB.sample(sampler, coord).r;
    
    float newAlphaA = 0;
    float newAlphaB = 0;
    
    if (alphaA > alphaB) {
        newAlphaA = alphaA;
        newAlphaB = 0;
    } else if (alphaA < alphaB) {
        newAlphaA = 0;
        newAlphaB = alphaB;
    } else if (alphaA != 0 && alphaB != 0) {
        // alpha:
        newAlphaA = alphaA * 0.5;
        newAlphaB = alphaB * 0.5;
        
        // checkmarks:
//        float shiftX = (gid.x / 8) % 2;
//        float shiftY = (gid.y / 8) % 2;
//        if (shiftX == shiftY) {
//            newAlphaA = 1;
//            newAlphaB = 0;
//        } else {
//            newAlphaA = 0;
//            newAlphaB = 1;
//        }
    }
    
    outputA.write(float4(newAlphaA, 0, 0, 0), gid);
    outputB.write(float4(newAlphaB, 0, 0, 0), gid);
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

    
    r.position = float4(pos, 0, 1);
    r.radius = 2 * radius;
    return r;
}

fragment float metaballs_fragment(MetaballVertexOutput in [[stage_in]],
                                   float2 pointCoord [[point_coord]]) {

    if (in.radius < 0 || in.position.w < 0) {
        discard_fragment();
    }
    float dist = length(pointCoord - float2(0.5));
    float alpha = 1 - smoothstep(0, 1, dist * 2);
    // TODO: magic number
    return alpha * 0.5;// * 0.18;
}

kernel void threshold_filter(texture2d<float, access::sample> alphaInput [[texture(0)]],
                             texture2d<float, access::write> output [[texture(1)]],
                             device uchar4 const &materialColor [[buffer(0)]],
                             device float const &threshold [[buffer(1)]],
                             sampler nearestSampler [[sampler(0)]],
                             sampler linearSampler [[sampler(1)]],
                             uint2 gid [[thread_position_in_grid]])
{
    float2 coord = float2(gid);
    coord.x /= output.get_width();
    coord.y /= output.get_height();
    
    float4 oldColor = float4(materialColor) / 255.0;
    float alpha = alphaInput.sample(linearSampler, coord).r;
    
    if (alpha > threshold) {
        float4 col = float4(oldColor.rgb, 1);
        output.write(col, gid);
        return;
    }
    output.write(float4(0), gid);
}



float pixel_alpha(texture2d<float, access::sample> texture, sampler s, uint2 p) {
    float2 coord = float2(p);
    coord.x /= texture.get_width();
    coord.y /= texture.get_height();
    return texture.sample(s, coord).r;
}

kernel void surface_filter(array<texture2d<float, access::read>, 96> textures [[texture(1)]],
                           texture2d<float, access::write> output [[texture(0)]],
                           device int const &textureCount [[buffer(0)]],
                           device uint const &thickness [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    float mCenter = 0;
    float mRight = 0;
    float mTopRight = 0;
    float mTop = 0;
    float mBottom = 0;
    float mLeft = 0;
    float mTopLeft = 0;
    float mBottomLeft = 0;
    float mBottomRight = 0;
    
    float3 color = float3(0);
    
    for (int i = 0; i < textureCount; i++) {
        float4 centerColor = textures[i].read(gid);
        mCenter += centerColor.a;
        mRight += textures[i].read(uint2(gid.x + thickness, gid.y)).a;
        mTopRight += textures[i].read(uint2(gid.x + thickness, gid.y - thickness)).a;
        mTop += textures[i].read(uint2(gid.x, gid.y - thickness)).a;
        mBottom += textures[i].read(uint2(gid.x, gid.y + thickness)).a;
        mLeft += textures[i].read(uint2(gid.x - thickness, gid.y)).a;
        mTopLeft += textures[i].read(uint2(gid.x - thickness, gid.y - thickness)).a;
        mBottomLeft += textures[i].read(uint2(gid.x - thickness, gid.y + thickness)).a;
        mBottomRight += textures[i].read(uint2(gid.x + thickness, gid.y + thickness)).a;
        
        float3 col = centerColor.rgb;
        if (col.r + col.g + col.b > 0) {
            color = col;
        }
    }
    
    mCenter = min(1.0, mCenter);
    mRight = min(1.0, mRight);
    mTopRight = min(1.0, mTopRight);
    mTop = min(1.0, mTop);
    mBottom = min(1.0, mBottom);
    mLeft = min(1.0, mLeft);
    mTopLeft = min(1.0, mTopLeft);
    mBottomLeft = min(1.0, mBottomLeft);
    mBottomRight = min(1.0, mBottomRight);
    
//    mCenter = clamp(mCenter, 0.0, 1.0);
//    mTop = clamp(mTop, 0.0, 1.0);
//    mBottom = clamp(mBottom, 0.0, 1.0);
//    mLeft = clamp(mLeft, 0.0, 1.0);
//    mRight = clamp(mRight, 0.0, 1.0);
//    mTopRight = clamp(mTopRight, 0.0, 1.0);
//    mTopLeft = clamp(mTopLeft, 0.0, 1.0);
//    mBottomLeft = clamp(mBottomLeft, 0.0, 1.0);
//    mBottomRight = clamp(mBottomRight, 0.0, 1.0);

    float dT  = abs(mCenter - mTop);
    float dR  = abs(mCenter - mRight);
    float dTR = abs(mCenter - mTopRight);
    float dB  = abs(mCenter - mBottom);
    float dL  = abs(mCenter - mLeft);
    float dTL = abs(mCenter - mTopLeft);
    float dBR = abs(mCenter - mBottomRight);
    float dBL = abs(mCenter - mBottomLeft);

    float delta = 0.0;
    delta = max(delta, dT);
    delta = max(delta, dR);
    delta = max(delta, dTR);
    delta = max(delta, dL);
    delta = max(delta, dB);
    delta = max(delta, dTL);
    delta = max(delta, dBR);
    delta = max(delta, dBL);

    if (delta > 0.5) {
        output.write(float4(color * 1.8, 1), gid);
    }
}
