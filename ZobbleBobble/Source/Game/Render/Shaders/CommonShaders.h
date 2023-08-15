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

float3 rgb2hsv(float3 c);
float3 hsv2rgb(float3 c);

#endif /* CommonShaders_h */
