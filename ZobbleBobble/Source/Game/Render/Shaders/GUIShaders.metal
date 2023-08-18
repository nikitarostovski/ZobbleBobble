//
//  GUIShaders.metal
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

#include <metal_stdlib>
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

// TODO: unify button and label text drawings

float4 button_color(GUIButton button, uint2 gid, texture2d<float, access::write> texture, texture2d<float, access::read> textTexture) {
    float4 result = float4(0);
    
    float x = float(gid.x) / float(texture.get_width());
    float y = float(gid.y) / float(texture.get_height());
    
    if (x >= button.origin.x &&
        x <= button.origin.x + button.size.x &&
        y >= button.origin.y &&
        y <= button.origin.y + button.size.y) {
        
        float paddingH = button.textPadding.x / texture.get_width();
        float paddingV = button.textPadding.y / texture.get_height();
        
        ushort2 texCoords;
        float xp = (x - button.origin.x - paddingH) / (button.size.x - 2 * paddingH);
        float yp = 1 - (y - button.origin.y - paddingV) / (button.size.y - 2 * paddingV);
        texCoords.x = xp * textTexture.get_width();
        texCoords.y = yp * textTexture.get_height();
        
        // Aspect fit
        float scaleX = (button.size.x - 2 * paddingH) * texture.get_width() / textTexture.get_width();
        float scaleY = (button.size.y - 2 * paddingV) * texture.get_height() / textTexture.get_height();

        if (scaleX < scaleY) {
            scaleY = scaleX / scaleY;
            scaleX = 1.0;
        } else {
            scaleX = scaleY / scaleX;
            scaleY = 1.0;
        }
        texCoords.x /= scaleX;
        texCoords.y /= scaleY;
        //
        
        float4 backgroundColor = float4(button.backgroundColor) / 255;
        float4 textTextureColor = textTexture.read(texCoords);
        
        result.a = 1;
        if (textTextureColor.a > 0) {
            result.rgb = float3(button.textColor.rgb) / 255;
        } else {
            result.rgb = backgroundColor.rgb;
        }
    }
    return result;
}

float4 label_color(GUILabel label, uint2 gid, texture2d<float, access::write> texture, texture2d<float, access::read> textTexture) {
    float4 result = float4(0);
    
    float x = float(gid.x) / float(texture.get_width());
    float y = float(gid.y) / float(texture.get_height());
    
    if (x >= label.origin.x &&
        x <= label.origin.x + label.size.x &&
        y >= label.origin.y &&
        y <= label.origin.y + label.size.y) {
        
        ushort2 texCoords;
        float xp = (x - label.origin.x) / (label.size.x);
        float yp = 1 - (y - label.origin.y) / (label.size.y);
        texCoords.x = xp * textTexture.get_width();
        texCoords.y = yp * textTexture.get_height();
        
        // Aspect fit
        float scaleX = label.size.x * texture.get_width() / textTexture.get_width();
        float scaleY = label.size.y * texture.get_height() / textTexture.get_height();

        if (scaleX < scaleY) {
            scaleY = scaleX / scaleY;
            scaleX = 1.0;
        } else {
            scaleX = scaleY / scaleX;
            scaleY = 1.0;
        }
        texCoords.x /= scaleX;
        texCoords.y /= scaleY;
        //
        
        float4 backgroundColor = float4(label.backgroundColor) / 255;
        float4 textTextureColor = textTexture.read(texCoords);
        
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
                     array<texture2d<float, access::read>, 96> textTextures [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    if (uniforms.alpha == 0) {
        return;
    }
    
    float4 resultColor = float4(0);
    
    for (int i = 0; i < buttonCount; i++) {
        int ti = buttons[i].textureIndex;
        auto textTexture = textTextures[ti];
        
        float4 color = button_color(buttons[i], gid, output, textTexture);
        if (color.a > 0) {
            resultColor = color;
            break;
        }
    }
    
    for (int i = 0; i < labelCount; i++) {
        int ti = labels[i].textureIndex;
        auto textTexture = textTextures[ti];
        
        float4 color = label_color(labels[i], gid, output, textTexture);
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
