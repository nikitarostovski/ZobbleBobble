//
//  CellsShaders.metal
//  ZobbleBobble
//
//  Created by Никита Ростовский on 12.09.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"

using namespace metal;

struct CellsUniforms {
};

kernel void draw_cells(device CellsUniforms &uniforms [[buffer(0)]],
                       texture2d<float, access::read> input [[texture(0)]],
                       texture2d<float, access::write> output [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]])
{
    auto in = input.read(gid);
    output.write(in, gid);
}
