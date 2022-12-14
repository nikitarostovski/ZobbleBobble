//
//  Shaders.metal
//  ZobbleBobble
//
//  Created by Rost on 02.12.2022.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut res;
    res.position = float4(in.position, 0.0, 1.0);
    res.color = in.color;
    res.pointSize = 5;
    return res;
}

fragment float4 fragment_main(VertexOut v [[stage_in]]) {
//    if (length(pointCoord - float2(0.5)) > 0.5) {
//        discard_fragment();
//    }
    return v.color;
}
