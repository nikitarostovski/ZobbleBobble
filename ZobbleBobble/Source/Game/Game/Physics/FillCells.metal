//
//  FillCells.metal
//  ZobbleBobble
//
//  Created by Никита Ростовский on 26.09.2023.
//

#include <metal_stdlib>

using namespace metal;

kernel void clear_cells(texture2d<float, access::write> output [[texture(0)]],
                        uint2 gid [[thread_position_in_grid]])
{
    float4 color = float4(0);
    output.write(color, gid);
}

kernel void fill_cells(device float2 const* positions [[buffer(0)]],
                       device float2 const* velocities [[buffer(1)]],
                       device uchar4 const* colors [[buffer(2)]],
                       texture2d<float, access::write> output [[texture(0)]],
                       uint2 gid [[thread_position_in_grid]])
{
    
    float2 pos = positions[gid.x];
    
    float4 color;// = float4(colors[gid.x]) / 255;
    color.r = 1;
    color.a = 1;
    
    int x = pos.x * output.get_width();
    int y = pos.y * output.get_height();
    
    output.write(color, ushort2(x, y));
}
