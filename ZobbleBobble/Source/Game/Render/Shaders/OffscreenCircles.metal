//
//  OffscreenCircles.metal
//  ZobbleBobble
//
//  Created by Rost on 25.12.2022.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

struct CircleUniforms {
    float cameraScale;
    float2 camera;
};

#define CLAMP(v, min, max) \
    if (v < min) { \
        v = min; \
    } else if (v > max) { \
        v = max; \
    }

kernel void draw_circles(constant CircleUniforms &uniforms [[buffer(0)]],
                         constant float2 *positions [[buffer(1)]],
                         constant float *radii [[buffer(2)]],
                         constant uchar4 *color [[buffer(3)]],
                         constant int *pointCount [[buffer(4)]],
                         texture2d<float, access::write> output [[texture(0)]],
                         uint2 gid [[thread_position_in_grid]])
{
    int i = gid.x;
    float radius = radii[i] * uniforms.cameraScale;
    float4 col = float4(color[i]) / 255.0;
    float2 pos = (positions[i] - uniforms.camera) * uniforms.cameraScale;
    pos.x += output.get_width() / 2;
    pos.y += output.get_height() / 2;
    
    drawCircle(output, pos, radius, col);
}
