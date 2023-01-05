//
//  Shaders.metal
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

#include <metal_stdlib>
using namespace metal;

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
