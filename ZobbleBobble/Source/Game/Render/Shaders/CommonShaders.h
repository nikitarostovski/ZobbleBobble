//
//  CommonShaders.h
//  ZobbleBobble
//
//  Created by Rost on 24.01.2023.
//

#include <metal_stdlib>

#ifndef CommonShaders_h
#define CommonShaders_h

#define CLAMP(v, min, max) \
    if (v < min) { \
        v = min; \
    } else if (v > max) { \
        v = max; \
    }

using namespace metal;

void drawMetaball(texture2d<float, access::read> input, texture2d<float, access::write> output, texture2d<float, access::write> colorOutput, float2 center, float radius, float3 color);
void drawCircle(texture2d<float, access::write> output, float2 center, float radius, float4 color);

#endif /* CommonShaders_h */
