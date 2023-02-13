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
                                texture2d<float> texture1 [[texture(0)]],
                                texture2d<float> texture2 [[texture(1)]],
                                texture2d<float> texture3 [[texture(2)]],
                                texture2d<float> texture4 [[texture(3)]],
                                texture2d<float> texture5 [[texture(4)]],
                                constant float2 *destSize [[buffer(0)]],
                                sampler s [[sampler(0)]]) {
    float4 c1 = texture1.sample(s, in.texcoord);
    float4 c2 = texture2.sample(s, in.texcoord);
    float4 c3 = texture3.sample(s, in.texcoord);
    float4 c4 = texture4.sample(s, in.texcoord);
    float4 c5 = texture5.sample(s, in.texcoord);

    if (c5.a > 0) {
        return c5;
    } else if (c4.a > 0) {
        return c4;
    } else if (c3.a > 0) {
        return c3;
    } else if (c2.a > 0) {
        return c2;
    } else {
        return c1;
    }
}
