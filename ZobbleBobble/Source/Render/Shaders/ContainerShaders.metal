//
//  ContainerShaders.metal
//  ZobbleBobble
//
//  Created by Rost on 24.08.2023.
//

#include <metal_stdlib>

#define WALL_WIDTH 0.008f

using namespace metal;

struct ContainerUniforms {
    float cameraScale;
    float2 camera;
};

struct Material {
    uchar4 color;
    float2 position;
};

kernel void draw_container(device ContainerUniforms &uniforms [[buffer(0)]],
                           device float2 &origin [[buffer(1)]],
                           device float2 &size [[buffer(2)]],
                           device Material *materials [[buffer(3)]],
                           device int &materialCount [[buffer(4)]],
                           texture2d<float, access::write> output [[texture(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    float x = (origin.x - uniforms.camera.x) * uniforms.cameraScale + output.get_width() / 2;
    float y = (origin.y - uniforms.camera.y) * uniforms.cameraScale + output.get_height() / 2;
    float width = size.x * uniforms.cameraScale;
    float height = size.y * uniforms.cameraScale;

    if (gid.x < x || gid.x > x + width || gid.y < y || gid.y > y + height) {
        output.write(float4(0), gid);
        return;
    }
    float4 backgroundColor = float4(0.1, 0.1, 0.1, 1);
    float progress = min(1.0, max(0.0, abs(y - gid.y) / height));
    
    if ((gid.x - x) / output.get_height() < WALL_WIDTH ||
        (x + width - gid.x) / output.get_height() < WALL_WIDTH ||
        (gid.y - y) / output.get_height() < WALL_WIDTH ||
        (y + height - gid.y) / output.get_height() < WALL_WIDTH) {
        output.write(backgroundColor, gid);
        return;
    }
    
    for (int i = 0; i < materialCount; i++) {
        Material m = materials[i];
        float mStart = 1 - m.position.y;
        float mEnd = 1 - m.position.x;

        float dist = min(abs(progress - mStart), abs(mEnd - progress)) * output.get_width() / output.get_height();

        if (dist > WALL_WIDTH && progress >= mStart && progress <= mEnd) {
            float4 mColor = float4(m.color) / 255.0;
            output.write(mColor, gid);
            return;
        }
    }

    output.write(backgroundColor, gid);
}
