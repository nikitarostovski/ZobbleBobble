//
//  CommonShaders.h
//  ZobbleBobble
//
//  Created by Rost on 24.01.2023.
//

#include <metal_stdlib>

#ifndef CommonShaders_h
#define CommonShaders_h

using namespace metal;

void drawMetaball(texture2d<float, access::read> input, texture2d<float, access::write> output, float2 center, float radius);
void drawCircle(texture2d<float, access::write> output, float2 center, float radius, float4 color);

#endif /* CommonShaders_h */
