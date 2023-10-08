//
//  Terrain.metal
//  ZobbleBobble
//
//  Created by Никита Ростовский on 26.09.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

struct TerrainUniforms {
    float cameraScale;
    float2 camera;
};

struct Particle {
    float2 lastPos;
    float2 pos;
    float2 acc;
    uchar4 color;
};

float4 blend(float4 oldColor, float4 newColor) {
    oldColor.rgb = rgb2hsv(oldColor.rgb);
    newColor.rgb = rgb2hsv(newColor.rgb);
    float4 color = blend(13, oldColor, newColor);
    color.rgb = hsv2rgb(color.rgb);
    return color;
}

kernel void clear_terrain(texture2d<float, access::write> output [[texture(0)]], uint2 gid [[thread_position_in_grid]]) {
    output.write(float4(0), gid);
}

kernel void draw_terrain(texture2d<float, access::read> input [[texture(0)]],
                         texture2d<float, access::write> output [[texture(1)]],
                         device TerrainUniforms const &uniforms [[buffer(0)]],
                         device Particle const* particles [[buffer(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    
    Particle particle = particles[gid.x];
    uchar4 col = particle.color;
    float2 pos = particle.pos * uniforms.cameraScale;
    
    float2 textureSize = float2(0);//float2(output.get_width(), output.get_height());
    
    ushort2 pixel = ushort2(pos + textureSize / 2);
    float4 oldColor = input.read(pixel);
    float4 newColor = float4(col) / 255;
    
    float4 color;
    if (oldColor.a < 0.001) {
        color = newColor;
    } else {
        color = blend(oldColor, newColor);
    }
    
    output.write(color, pixel);
}
