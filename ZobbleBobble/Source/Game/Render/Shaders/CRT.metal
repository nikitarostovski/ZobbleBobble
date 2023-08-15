//
//  Experimental.metal
//  ZobbleBobble
//
//  Created by Rost on 11.08.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"

using namespace metal;

struct ProjectedVertex {
    float4 position [[position]];
    float2 texCoords [[user(tex_coords)]];
};

struct ShaderOptions {
    uint bloom;
    float bloomRadiusR;
    float bloomRadiusG;
    float bloomRadiusB;
    float bloomBrightness;
    float bloomWeight;

    uint dotMask;
    float dotMaskBrightness;

    uint scanlines;
    float scanlineBrightness;
    float scanlineWeight;
    
    uint disalignment;
    float disalignmentH;
    float disalignmentV;
};

struct FragmentUniforms {
    float alpha;
    float white;
    uint dotMaskWidth;
    uint dotMaskHeight;
    uint scanlineDistance;
};

vertex ProjectedVertex vertex_render(device float4 const* positions [[buffer(0)]],
                                                   constant float *angle [[buffer(1)]],
                                                   uint vertexID [[vertex_id]]) {
    float2 texcoord = float2(positions[vertexID].z, positions[vertexID].w);
    
    ProjectedVertex r;
    r.position = float4(positions[vertexID].xy, 0, 1);
    r.texCoords = texcoord;
    return r;
}

float4 scanlineWeight(uint2 pixel, uint height, float weight, float brightness, float bloom) {
    // Calculate distance to nearest scanline
    float dy = ((float(pixel.y % height) / float(height - 1)) - 0.5);
 
    // Calculate scanline weight
    float scanlineWeight = max(1.0 - dy * dy * 24 * weight, brightness);
    
    // Apply bloom effect an return
    return scanlineWeight * bloom;
}

fragment half4 fragment_render(ProjectedVertex vert [[ stage_in ]],
                               texture2d<float, access::sample> texture [[ texture(0) ]],
                               texture2d<float, access::sample> bloomTextureR [[ texture(1) ]],
                               texture2d<float, access::sample> bloomTextureG [[ texture(2) ]],
                               texture2d<float, access::sample> bloomTextureB [[ texture(3) ]],
                               texture2d<float, access::sample> dotMask [[ texture(4) ]],
                               constant ShaderOptions &options [[ buffer(0) ]],
                               constant FragmentUniforms &uniforms [[ buffer(1) ]],
                               sampler texSampler [[ sampler(0) ]]) {
    
    uint x = uint(vert.position.x);
    uint y = uint(vert.position.y);
    uint2 pixel = uint2(x, y);
    float4 color;
    
    // Read fragment from texture
    float2 tc = float2(vert.texCoords.x, vert.texCoords.y);
    
    // Apply color shift
    if (options.disalignment) {
        float dx = options.disalignmentH;
        float dy = options.disalignmentV;
        float4 r = texture.sample(texSampler, tc + float2(dx,dy));
        float4 g = texture.sample(texSampler, tc);
        float4 b = texture.sample(texSampler, tc - float2(dx,dy));
        color = float4(r.r, g.g, b.b,0);
    } else {
        color = texture.sample(texSampler, float2(vert.texCoords.x, vert.texCoords.y));
    }
    
    // Apply bloom effect
    if (options.bloom) {
        float4 bloom_r = bloomTextureR.sample(texSampler, tc);
        float4 bloom_g = bloomTextureG.sample(texSampler, tc);
        float4 bloom_b = bloomTextureB.sample(texSampler, tc);
        float4 bColor = bloom_r + bloom_g + bloom_b;
        bColor = pow(bColor, options.bloomWeight) * options.bloomBrightness;
        color = saturate(color + bColor);
    }
    
    // Apply scanline effect
    if (options.scanlines == 1) {
        if (((y + 1) % 4) < 2) {
            color *= options.scanlineBrightness;
        }
    } else if (options.scanlines == 2) {
        color *= scanlineWeight(pixel,
                                uniforms.scanlineDistance,
                                options.scanlineWeight,
                                options.scanlineBrightness,
                                1.0);
    }

    // Apply dot mask effect
    if (options.dotMask) {
        uint xoffset = x % uniforms.dotMaskWidth;
        uint yoffset = y % uniforms.dotMaskHeight;
        float4 dotColor = dotMask.read(uint2(xoffset, yoffset));
        float4 gain = min(color, 1 - color) * dotColor;
        float4 loose = min(color, 1 - color) * 0.5 * (1 - dotColor);
        color += gain - loose;
    }
    
    color = mix(color, float4(1.0, 1.0, 1.0, 1.0), uniforms.white);
    return half4(color.r, color.g, color.b, uniforms.alpha);
}

kernel void split(texture2d<half, access::read> input [[texture(0)]],
                  texture2d<half, access::write> outputRed [[texture(1)]],
                  texture2d<half, access::write> outputGreen [[texture(2)]],
                  texture2d<half, access::write> outputBlue [[texture(3)]],
                  constant ShaderOptions &options [[buffer(0)]],
                  uint2 gid [[thread_position_in_grid]]) {

    half4 color = input.read(uint2(gid.x, gid.y));
    
    outputRed.write(half4(color.r, 0, 0, 0), gid);
    outputGreen.write(half4(0, color.g, 0, 0), gid);
    outputBlue.write(half4(0, 0, color.b, 0), gid);
}
