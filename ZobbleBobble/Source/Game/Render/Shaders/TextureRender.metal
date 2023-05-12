//
//  TextureRender.metal
//  ZobbleBobble
//
//  Created by Rost on 24.12.2022.
//

#include <metal_stdlib>

struct TexturePipelineRasterizerData {
    float4 position [[position]];
    float2 texcoord;
};

using namespace metal;

float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vertex TexturePipelineRasterizerData vertex_render(device float4 const* positions [[buffer(0)]],
                                                   constant float *angle [[buffer(1)]],
                                                   uint vertexID [[vertex_id]]) {
    float2 texcoord = float2(positions[vertexID].z, positions[vertexID].w);
    
    TexturePipelineRasterizerData r;
    r.position = float4(positions[vertexID].xy, 0, 1);
    r.texcoord = texcoord;
    return r;
}

fragment float4 fragment_render(TexturePipelineRasterizerData in [[stage_in]],
                                array<texture2d<float, access::sample>, 96> textures [[texture(0)]],
                                device int const &textureCount [[buffer(0)]],
                                sampler s [[sampler(0)]]) {
    
    // max-alpha
    float4 maxAlphaColor = float4(-1);
    for (int i = 0; i < textureCount; i++) {
        float4 col = textures[i].sample(s, in.texcoord);
        if (col.a > maxAlphaColor.a) {
            maxAlphaColor = col;
        }
    }
    if (maxAlphaColor.r + maxAlphaColor.g + maxAlphaColor.b == 0) {
        return float4(0.1, 0.0, 0.1, 1.0);
    }
    return maxAlphaColor;
    
    
    // multiply by alpha:
    float3 result = float3(0);
    for (int i = 0; i < textureCount; i++) {
        float4 col = textures[i].sample(s, in.texcoord);
//        float3 hsvCol = rgb2hsv(col.rgb);
//        result += hsvCol * col.a;
        result += col.rgb * col.a;
    }
    if (result.r + result.g + result.b == 0) {
        return float4(0.1, 0.0, 0.1, 1.0);
    } else {
//        float3 rgbColor = hsv2rgb(result);
//        return float4(rgbColor, 1);
        return float4(result, 1);
    }
}
