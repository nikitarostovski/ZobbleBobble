//
//  TextureMerge.metal
//  ZobbleBobble
//
//  Created by Rost on 24.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"

using namespace metal;

float4 lerpColor(float4 fraction, float4 from, float4 to);

float4 blend(int mode, float4 ca, float4 cb) {
    
    float pi = 3.14159265359;

    float4 c;
    float3 rgb_a = float3(ca);
    float3 rgb_b = float3(cb);
    float aa = max(ca.a, cb.a);
    float ia = min(ca.a, cb.a);
    float oa = ca.a - cb.a;
    float xa = abs(ca.a - cb.a);
    switch (mode) {
        case 0: // Over
            c = float4(rgb_a * (1.0 - cb.a) + rgb_b * cb.a, aa);
            break;
        case 1: // Under
            c = float4(rgb_a * ca.a + rgb_b * (1.0 - ca.a), aa);
            break;
        case 2: // Add Color
            c = float4(rgb_a + rgb_b, aa);
            break;
        case 3: // Add
            c = ca + cb;
            break;
        case 4: // Mult
            c = ca * cb;
            break;
        case 5: // Diff
            c = float4(abs(rgb_a - rgb_b), aa);
            break;
        case 6: // Sub Color
            c = float4(rgb_a - rgb_b, aa);
            break;
        case 7: // Sub
            c = ca - cb;
            break;
        case 8: // Max
            c = max(ca, cb);
            break;
        case 9: // Min
            c = min(ca, cb);
            break;
        case 10: // Gamma
            c = pow(ca, 1 / cb);
            break;
        case 11: // Power
            c = pow(ca, cb);
            break;
        case 12: // Divide
            c = ca / cb;
            break;
        case 13: // Average
            c = ca / 2 + cb / 2;
            break;
        case 14: // Cosine
            c = lerpColor(min(cb.r, 1.0), ca, cos(ca * pi + pi) / 2 + 0.5);
            for (int i = 1; i < int(ceil(cb.r)); i++) {
                c = lerpColor(min(max(cb.r - float(i), 0.0), 1.0), c, cos(c * pi + pi) / 2 + 0.5);
            }
            break;
        case 15: // Inside Source
            c = float4(rgb_a * ia, ia);
            break;
//        case 15: // Inside Destination
//            c = float4(rgb_b * ia, ia);
//            break;
        case 16: // Outside Source
            c = float4(rgb_a * oa, oa);
            break;
//        case 17: // Outside Destination
//            c = float4(rgb_b * oa, oa);
//            break;
        case 17: // XOR
            c = float4(rgb_a * (ca.a * xa) + rgb_b * (cb.a * xa), xa);
            break;
    }
    
    return c;
}

float4 lerpColor(float4 fraction, float4 from, float4 to) {
    return from * (1.0 - fraction) + to * fraction;
}

kernel void merge(texture2d<float, access::write> output [[texture(0)]],
                  array<texture2d<float, access::read>, (MAX_TEXTURES - 1)> textures [[texture(1)]],
                  device int const &textureCount [[buffer(0)]],
                  device uchar4 const &backgroundColor [[buffer(1)]],
                  uint2 gid [[thread_position_in_grid]]) {
    
    float4 currentColor = float4(1, 1, 1, 0);
    for (int i = 0; i < textureCount; i++) {
        float4 col = textures[i].read(gid);
        currentColor = blend(1, currentColor, col);
    }
    if (currentColor.a == 0) {
        currentColor = float4(backgroundColor) / 255;
        currentColor.a = 1;
    }
    output.write(float4(currentColor.rgb, 1), gid);
    return;
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
