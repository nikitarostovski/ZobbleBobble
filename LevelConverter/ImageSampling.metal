//
//  ImageSampling.ci.metal
//  ZobbleCore
//
//  Created by Rost on 13.05.2023.
//

#include <metal_stdlib>
using namespace metal;

kernel void get_pixel(texture2d<float, access::sample> inTexture [[texture(0)]],
                      device float2 *points [[buffer(0)]],
                      device float4 *colors [[buffer(1)]],
                      sampler s,
                      uint2 gid [[thread_position_in_grid]]) {
    
    int index = gid.x;
    float2 pt = points[index];
    colors[index] = inTexture.sample(s, pt);
}
