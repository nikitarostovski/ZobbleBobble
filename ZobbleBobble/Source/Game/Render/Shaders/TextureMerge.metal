//
//  TextureMerge.metal
//  ZobbleBobble
//
//  Created by Rost on 24.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"

using namespace metal;

float4 blendOver(float4 a, float4 b) {
    float newAlpha = mix(b.w, 1.0, a.w);
    float3 newColor = mix(b.w * b.xyz, a.xyz, a.w);
    float divideFactor = (newAlpha > 0.001 ? (1.0 / newAlpha) : 1.0);
    return float4(divideFactor * newColor, newAlpha);
}

kernel void merge(texture2d<float, access::write> output [[texture(0)]],
                  array<texture2d<float, access::read>, 96> textures [[texture(1)]],
                  device int const &textureCount [[buffer(0)]],
                  uint2 gid [[thread_position_in_grid]]) {
    
    // material mix (checkboard)
//    int visibleCount = 0;
//    for (int i = 0; i < textureCount; i++) {
//        float4 rgba = textures[i].read(gid);
//        if (rgba.a > 0) {
//            visibleCount += 1;
//        }
//    }
//    if (visibleCount == 0) {
//        return float4(0, 0, 0, 1);
//    }
//
//    int x = (int)pos.x * textures[0].get_width();
////    int y = (int)pos.y * textures[0].get_height();
//
//    int index = (x) % visibleCount;
//
//    int i = 0;
//    while (visibleCount > index) {
//        float4 rgba = textures[i].read(gid);
//        if (rgba.a > 0) {
//            visibleCount -= 1;
//        }
//        i++;
//    }
//
//    float4 result = textures[i - 1].read(gid);
//    result.a = 1.0;
//    return result;
    
    // material mix (hsv)
//    float3 totalChannels = float3(0, 0, 0);
//    int visibleCount = 0;
//    for (int i = 0; i < textureCount; i++) {
//        float4 rgba = textures[i].read(gid);
//        float3 hsv = rgb2hsv(rgba.rgb);
//        if (rgba.a > 0) {
//            totalChannels += hsv;
//            visibleCount += 1;
//        }
//    }
//    totalChannels /= visibleCount;
//    totalChannels.y *= 1.0 / visibleCount;
//    totalChannels = hsv2rgb(totalChannels);
//    output.write(float4(totalChannels, 1), gid);
//    return;
    
    // blend over
    float4 currentColor = float4(1, 1, 1, 0);
    for (int i = 0; i < textureCount; i++) {
        float4 col = textures[i].read(gid);
        currentColor = blendOver(currentColor, col);
    }
    output.write(float4(currentColor.rgb, 1), gid);
    return;
    
    // multiply
//    float4 totalChannels = float4(0, 0, 0, 1);
//    int visibleCount = 0;
//    for (int i = 0; i < textureCount; i++) {
//        float4 col = textures[i].read(gid);
//        if (col.a > 0) {
//            totalChannels.r += col.r;
//            totalChannels.g += col.g;
//            totalChannels.b += col.b;
//
//            visibleCount += 1;
//        }
//    }
//    totalChannels.rgb /= visibleCount;
//    output.write(float4(totalChannels.rgb, 1), gid);
//    return;
    
    // max-alpha
//    float4 maxAlphaColor = float4(0, 0, 0, -1);
//    for (int i = 0; i < textureCount; i++) {
//        float4 col = textures[i].read(gid);
//        if (col.a > maxAlphaColor.a) {
//            maxAlphaColor = col;
//        }
//    }
//    float3 result = maxAlphaColor.rgb;
//    if (result.r + result.g + result.b <= 0) {
//        result = float3(0, 0, 0);
//    }
//
//    output.write(float4(result, 1), gid);
}
