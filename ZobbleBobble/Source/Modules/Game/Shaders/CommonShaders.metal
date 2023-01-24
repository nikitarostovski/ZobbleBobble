//
//  CommonShaders.metal
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

void drawMetaball(texture2d<float, access::read> input, texture2d<float, access::write> output, float2 center, float radius) {
    for (int y = floor(center.y - radius); y < ceil(center.y + radius); y++) {
        for (int x = floor(center.x - radius); x < ceil(center.x + radius); x++) {
            uint2 coords = uint2(x, y);
            float dist = distance(float2(x, y), center);
            
            float4 color;
            if (dist == 0) {
                color = float4(1);
            } else {
                float alpha = radius / dist;
                color = float4(1, 1, 1, alpha);
            }
            
            float4 oldColor = input.read(coords);
            color += oldColor;
            output.write(color, coords);
        }
    }
}

void drawCircle(texture2d<float, access::write> output, float2 center, float radius, float4 color) {
    for (int y = floor(center.y - radius); y < ceil(center.y + radius); y++) {
        for (int x = floor(center.x - radius); x < ceil(center.x + radius); x++) {
            uint2 coords = uint2(x, y);
            float dist = distance(float2(x, y), center);
            
            if (dist <= radius) {
                output.write(color, coords);
            }
        }
    }
}

kernel void fill_clear(texture2d<float, access::write> output [[texture(0)]],
                       uint2 gid [[thread_position_in_grid]]) {
    output.write(float4(0), gid);
}

kernel void upscale_texture(texture2d<float, access::sample> input [[texture(0)]],
                            texture2d<float, access::write> output [[texture(1)]],
                            sampler s [[sampler(0)]],
                            uint2 gid [[thread_position_in_grid]]) {
    float2 coord = float2(gid);
    coord.x /= output.get_width();
    coord.y /= output.get_height();
    float4 oldColor = input.sample(s, coord);

    output.write(oldColor, gid);
    return;
}

kernel void blur(texture2d<float, access::read> inTexture [[ texture(0) ]],
                 texture2d<float, access::write> outTexture [[ texture(1) ]],
                 constant int *blurRadius [[buffer(0)]],
                 uint2 gid [[ thread_position_in_grid ]]) {
    
    int range = *blurRadius;//floor(blurSize/2.0);
    
    float4 colors = float4(0);
    for (int x = -range; x <= range; x++) {
        for (int y = -range; y <= range; y++) {
            float4 color = inTexture.read(uint2(gid.x+x,
                                                gid.y+y));
            colors += color;
        }
    }
    
    float4 finalColor = colors/float(range*range*4);
    outTexture.write(finalColor, gid);
}
