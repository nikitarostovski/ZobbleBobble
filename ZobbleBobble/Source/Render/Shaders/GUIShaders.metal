//
//  GUIShaders.metal
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

#include <metal_stdlib>
#include "CommonShaders.h"
using namespace metal;

struct GUIUniforms {
    float alpha;
    uchar4 backgroundColor;
};

struct GUIRect {
    uchar4 backgroundColor;
    float2 origin;
    float2 size;
};

struct GUIText {
    uchar4 backgroundColor;
    uchar4 textColor;
    float2 origin;
    float2 size;
    int textureIndex;
};

float2 text_texture_coordinates(float2 uv, float2 origin, float2 size, float2 outTextureSize, float2 textTextureSize) {
    float2 coords;
    coords.x = (uv.x - origin.x) / size.x;
    coords.y = 1 - (uv.y - origin.y) / size.y;
    
    // Aspect fit
    float scaleX = size.x * outTextureSize.x / textTextureSize.x;
    float scaleY = size.y * outTextureSize.y / textTextureSize.y;

    if (scaleX < scaleY) {
        scaleY = scaleX / scaleY;
        scaleX = 1.0;
    } else {
        scaleX = scaleY / scaleX;
        scaleY = 1.0;
    }
    coords.x /= scaleX;
    coords.y /= scaleY;
    
    return coords;
}

float4 rect_color(GUIRect rect, uint2 gid, texture2d<float, access::write> texture) {
    float4 result = float4(0);
    
    float x = float(gid.x) / float(texture.get_width());
    float y = float(gid.y) / float(texture.get_height());
    
    if (x >= rect.origin.x &&
        x <= rect.origin.x + rect.size.x &&
        y >= rect.origin.y &&
        y <= rect.origin.y + rect.size.y) {
        
        float4 backgroundColor = float4(rect.backgroundColor) / 255;
        result = backgroundColor;
    }
    return result;
}

float4 text_color(GUIText text, uint2 gid, texture2d<float, access::write> texture, texture2d<float, access::sample> textTexture, sampler sampler) {
    float4 result = float4(0);
    
    float x = float(gid.x) / float(texture.get_width());
    float y = float(gid.y) / float(texture.get_height());
    
    float2 uv = float2(x, y);
    float2 outTextureSize = float2(texture.get_width(), texture.get_height());
    float2 textTextureSize = float2(textTexture.get_width(), textTexture.get_height());
    
    if (x >= text.origin.x &&
        x <= text.origin.x + text.size.x &&
        y >= text.origin.y &&
        y <= text.origin.y + text.size.y) {
        
        float2 texCoords = text_texture_coordinates(uv, text.origin, text.size, outTextureSize, textTextureSize);
        
        float4 backgroundColor = float4(text.backgroundColor) / 255;
        float4 textTextureColor = textTexture.sample(sampler, texCoords);
        
        if (textTextureColor.a > 0) {
            result.rgb = float3(text.textColor.rgb) / 255;
            result.a = textTextureColor.a;
        } else {
            result = backgroundColor;
        }
    }
    return result;
}

kernel void draw_gui(device GUIUniforms &uniforms [[buffer(0)]],
                     device GUIRect *rects [[buffer(1)]],
                     device int &rectCount [[buffer(2)]],
                     device GUIText *texts [[buffer(3)]],
                     device int &textCount [[buffer(4)]],
                     texture2d<float, access::write> output [[texture(0)]],
                     array<texture2d<float, access::sample>, (MAX_TEXTURES - 1)> textTextures [[texture(1)]],
                     sampler sampler [[sampler(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    if (uniforms.alpha == 0) {
        return;
    }
    
    int blendMode = 0;
    float4 resultColor = float4(0);
    
    for (int i = 0; i < rectCount; i++) {
        float4 color = rect_color(rects[i], gid, output);
        if (color.a > 0) {
            resultColor = blend(blendMode, resultColor, color);
        }
    }
    
    for (int i = 0; i < textCount; i++) {
        int ti = texts[i].textureIndex;
        auto textTexture = textTextures[ti];
        
        float4 color = text_color(texts[i], gid, output, textTexture, sampler);
        if (color.a > 0) {
            resultColor = blend(blendMode, resultColor, color);
        }
    }
    
    if (resultColor.a == 0) {
        resultColor = float4(uniforms.backgroundColor) / 255;
    }
    
    resultColor.a *= uniforms.alpha;
    output.write(resultColor, gid);
}
