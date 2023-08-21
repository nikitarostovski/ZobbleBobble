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

struct GUIButton {
    uchar4 backgroundColor;
    uchar4 textColor;
    float2 origin;
    float2 size;
    float2 textPadding;
    int textureIndex;
};

struct GUILabel {
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

float4 button_color(GUIButton button, uint2 gid, texture2d<float, access::write> texture, texture2d<float, access::sample> textTexture, sampler sampler) {
    float4 result = float4(0);
    
    float x = float(gid.x) / float(texture.get_width());
    float y = float(gid.y) / float(texture.get_height());
    
    float2 uv = float2(x, y);
    float2 outTextureSize = float2(texture.get_width(), texture.get_height());
    float2 textTextureSize = float2(textTexture.get_width(), textTexture.get_height());
    
    if (x >= button.origin.x &&
        x <= button.origin.x + button.size.x &&
        y >= button.origin.y &&
        y <= button.origin.y + button.size.y) {
        
        float paddingH = button.textPadding.x / texture.get_width();
        float paddingV = button.textPadding.y / texture.get_height();
        
        float2 origin = button.origin;
        origin.x += paddingH;
        origin.y += paddingV;
        
        float2 size = button.size;
        size.x -= 2 * paddingH;
        size.y -= 2 * paddingV;
        
        float2 texCoords = text_texture_coordinates(uv, origin, size, outTextureSize, textTextureSize);
        
        float4 backgroundColor = float4(button.backgroundColor) / 255;
        float4 textTextureColor = textTexture.sample(sampler, texCoords);
        
        result.a = 1;
        if (textTextureColor.a > 0) {
            result.rgb = float3(button.textColor.rgb) / 255;
        } else {
            result.rgb = backgroundColor.rgb;
        }
    }
    return result;
}

float4 label_color(GUILabel label, uint2 gid, texture2d<float, access::write> texture, texture2d<float, access::sample> textTexture, sampler sampler) {
    float4 result = float4(0);
    
    float x = float(gid.x) / float(texture.get_width());
    float y = float(gid.y) / float(texture.get_height());
    
    float2 uv = float2(x, y);
    float2 outTextureSize = float2(texture.get_width(), texture.get_height());
    float2 textTextureSize = float2(textTexture.get_width(), textTexture.get_height());
    
    if (x >= label.origin.x &&
        x <= label.origin.x + label.size.x &&
        y >= label.origin.y &&
        y <= label.origin.y + label.size.y) {
        
        float2 texCoords = text_texture_coordinates(uv, label.origin, label.size, outTextureSize, textTextureSize);
        
        float4 backgroundColor = float4(label.backgroundColor) / 255;
        float4 textTextureColor = textTexture.sample(sampler, texCoords);
        
        if (textTextureColor.a > 0) {
            result.rgb = float3(label.textColor.rgb) / 255;
            result.a = 1;
        } else {
            result = backgroundColor;
        }
    }
    return result;
}

kernel void draw_gui(device GUIUniforms &uniforms [[buffer(0)]],
                     device GUIButton *buttons [[buffer(1)]],
                     device int &buttonCount [[buffer(2)]],
                     device GUILabel *labels [[buffer(3)]],
                     device int &labelCount [[buffer(4)]],
                     texture2d<float, access::write> output [[texture(0)]],
                     array<texture2d<float, access::sample>, (MAX_TEXTURES - 1)> textTextures [[texture(1)]],
                     sampler sampler [[sampler(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    if (uniforms.alpha == 0) {
        return;
    }
    
    float4 resultColor = float4(0);
    
    for (int i = 0; i < buttonCount; i++) {
        int ti = buttons[i].textureIndex;
        auto textTexture = textTextures[ti];
        
        float4 color = button_color(buttons[i], gid, output, textTexture, sampler);
        if (color.a > 0) {
            resultColor = color;
            break;
        }
    }
    
    for (int i = 0; i < labelCount; i++) {
        int ti = labels[i].textureIndex;
        auto textTexture = textTextures[ti];
        
        float4 color = label_color(labels[i], gid, output, textTexture, sampler);
        if (color.a > 0) {
            resultColor = color;
            break;
        }
    }
    
    if (resultColor.a == 0) {
        resultColor = float4(uniforms.backgroundColor) / 255;
    }
    
    resultColor.a *= uniforms.alpha;
    output.write(resultColor, gid);
}