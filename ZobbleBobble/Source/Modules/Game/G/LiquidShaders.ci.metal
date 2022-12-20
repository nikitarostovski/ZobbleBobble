//
//  LiquidShaders.ci.metal
//  ZobbleBobble
//
//  Created by Rost on 26.11.2022.
//

#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h>

#define CLAMP(v, min, max) \
    if (v < min) { \
        v = min; \
    } else if (v > max) { \
        v = max; \
    }

extern "C" {
    namespace coreimage {
        struct Droplet
        {
            float x;
            float y;
        };
        
        
        float Lerp (float A, float B, float t) {
            return A * (1.0f - t) + B * t;
        }
        
        float4 addColor(sampler source1, sampler source2, coreimage::destination destination) {
            float4 c1 = sample(source1, samplerTransform(source1, destination.coord()));
            float4 c2 = sample(source2, samplerTransform(source2, destination.coord()));
            return c1 + c2;
        }
        
        float4 multiplyColor(sampler source, float value, coreimage::destination destination) {
            float4 c1 = sample(source, samplerTransform(source, destination.coord()));
            c1 *= value;
            c1.a = 1;
            return c1;
        }
        
        float4 sampleBilinear(sampler source, float u, float v) {
            float x = u;
            int xint = int(x);
            float xfract = x - floor(x);
            
            float y = v;
            int yint = int(y);
            float yfract = y - floor(y);
            
            auto p00 = sample(source, samplerTransform(source, float2(xint + 0, yint + 0)));
            auto p10 = sample(source, samplerTransform(source, float2(xint + 1, yint + 0)));
            auto p01 = sample(source, samplerTransform(source, float2(xint + 0, yint + 1)));
            auto p11 = sample(source, samplerTransform(source, float2(xint + 1, yint + 1)));
            
            float4 ret;
            for (int i = 0; i < 4; ++i)
            {
                float col0 = Lerp(p00[i], p10[i], xfract);
                float col1 = Lerp(p01[i], p11[i], xfract);
                float value = Lerp(col0, col1, yfract);
                CLAMP(value, 0.0, 1.0);
                ret[i] = value;
            }
            return ret;
        }
        
        
        float4 debugRender(constant Droplet *droplets, int dropletCount, float radius, coreimage::destination destination) {
            float minDist = MAXFLOAT;
            for (int i = 0; i < dropletCount; i++)
            {
                Droplet d = droplets[i];
                float2 p = float2(d.x, d.y);
                
                float dist = distance(destination.coord(), p);
                minDist = min(minDist, dist);
            }
            
            
            
            if (minDist <= radius)
            {
                return float4(1);
            }
            
            return float4(0);
        }
        
        float4 render(constant Droplet *droplets, int dropletCount, float radius, coreimage::destination destination) {
            float minDist = MAXFLOAT;
            for (int i = 0; i < dropletCount; i++)
            {
                Droplet d = droplets[i];
                float2 p = float2(d.x, d.y);
                
                float dist = distance(destination.coord(), p);
                minDist = min(minDist, dist);
            }
            float luminance = (2 * radius) / minDist;
            CLAMP(luminance, 0.0, 1.0)
            
            return float4(luminance, luminance, luminance, 1);
        }
        
        float4 renderFinal(sampler source, int sourceWidth, int sourceHeight, int targetWidth, int targetHeight, coreimage::destination destination) {
            
            float x = destination.coord().x * sourceWidth / targetWidth;
            float y = destination.coord().y * sourceHeight / targetHeight;
            
            float4 color = sampleBilinear(source, x, y);
            
            float4 col1 = float4(153.0 / 255.0, 179.0 / 255.0, 179.0 / 255.0, 1.0);
            float4 col2 = float4(124.0 / 255.0, 156.0 / 255.0, 142.0 / 255.0, 1.0);
            
            float threshold1 = 0.75;
            float threshold2 = 0.9;
            
            if (color.r > threshold2) {
                return col2;
            }
            if (color.r > threshold1) {
                return col1;
            }
            return float4(0);
        }
    }
}
