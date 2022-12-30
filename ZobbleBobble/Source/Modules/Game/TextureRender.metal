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

float rand(float);
float pattern(float2, float);

float rand(float x)
{
    return fract(sin(x * 10000.0));
}

float pattern(float2 uv, float time)
{
    return 1.0 + sin((uv.y + rand(uv.x + time) * 0.02) * 100.0 + time * 100.0) * 0.2;
}

//kernel void crt(texture2d<float, access::read> inTexture [[ texture(0) ]],
//                texture2d<float, access::write> outTexture [[ texture(1) ]],
//                device const float *time [[ buffer(0) ]],
//                uint2 gid [[ thread_position_in_grid ]])
//{
//
//}


vertex TexturePipelineRasterizerData vertex_render(device float4 const* positions [[buffer(0)]],
                                                   constant float *angle [[buffer(1)]],
                                                   uint vertexID [[vertex_id]]) {
    float2 texcoord = float2(positions[vertexID].z, positions[vertexID].w);
//    float l = length(texcoord);
//    float2 norm = normalize(texcoord);
//    float a = atan2(texcoord.y, texcoord.x) + *angle;
//    float s = sin(a);
//    float c = cos(a);
//    texcoord.x = c * texcoord.x - s * texcoord.y;
//    texcoord.y = s * texcoord.x + c * texcoord.y;
    
//    texcoord *= l;
    
    TexturePipelineRasterizerData r;
    r.position = float4(positions[vertexID].xy, 0, 1);
    r.texcoord = texcoord;
    return r;
}


//float2 CRTCurveUV(float2 uv) {
//    uv = uv * 2.0 - 1.0;
//    float2 offset = fabs( uv.yx ) / float2(6.0, 4.0);
//    uv = uv + uv * offset * offset;
//    uv = uv * 0.5 + 0.5;
//    return uv;
//}
//
//void DrawVignette( thread float3& color, float2 uv )
//{
//    float vignette = uv.x * uv.y * ( 1.0 - uv.x ) * ( 1.0 - uv.y );
//    vignette = clamp( pow( 16.0 * vignette, 0.3 ), 0.0, 1.0 );
//    color *= vignette;
//}
//
//void DrawScanline( thread float3& color, float2 uv, float iTime )
//{
//    float scanline     = clamp( 0.95 + 0.05 * cos( 3.14 * ( uv.y + 0.008 * iTime ) * 240.0 * 1.0 ), 0.0, 1.0 );
//    float grille     = 0.85 + 0.15 * clamp( 1.5 * cos( 3.14 * uv.x * 640.0 * 1.0 ), 0.0, 1.0 );
//    color *= scanline * grille * 1.2;
//}

fragment float4 fragment_render(TexturePipelineRasterizerData in [[stage_in]],
                                texture2d<float> texture1 [[texture(0)]],
                                texture2d<float> texture2 [[texture(1)]],
                                constant float2 *destSize [[buffer(0)]],
                                sampler s [[sampler(0)]]) {
    float4 c1 = texture1.sample(s, in.texcoord);
    float4 c2 = texture2.sample(s, in.texcoord);

    float4 result;
    if (c2.a > 0) {
        result = c2;
    } else {
        result = c1 + c2;
    }
    
    return result;
//    float2 uv = in.position.xy / *destSize;
//    float2 crtUV = CRTCurveUV(uv);
//
//    float3 color = result.rgb;
//    if ( crtUV.x < 0.0 || crtUV.x > 1.0 || crtUV.y < 0.0 || crtUV.y > 1.0 ) {
//        color = float3(0.0, 0.0, 0.0);
//    }
//    DrawVignette( color, crtUV);
//    DrawScanline( color, uv, 1);
//
//    return float4(color, 1);
}
