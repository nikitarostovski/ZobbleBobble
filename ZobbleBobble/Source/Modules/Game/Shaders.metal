//
//  Shaders.metal
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

#include <metal_stdlib>
using namespace metal;

struct FragmentUniforms {
    float scaleX;
    float scaleY;
    float particleRadius;
};

struct VertexOutTriangle {
    float4 position [[position]];
    uchar4 color;
};

struct VertexOutLiquid {
    float4 position [[position]];
    float radius [[point_size]];
    uchar4 color;
};

struct VertexOutPoint {
    float4 position [[position]];
    float radius [[point_size]];
    uchar4 color;
};

vertex VertexOutTriangle vertex_triangle(constant FragmentUniforms &uniforms [[buffer(0)]],
                                         device float2 const* positions [[buffer(1)]],
                                         device uchar4 const* colors [[buffer(2)]],
                                         
                                         uint vertexID [[vertex_id]])
{
    float2 position = positions[vertexID];
    position.x *= uniforms.scaleX * 2;
    position.y *= uniforms.scaleY * 2;
    position.y *= -1;
    
    VertexOutTriangle out {
        .position = float4(position, 0.0, 1.0),
        .color = colors[vertexID]
    };
    return out;
}

fragment float4 fragment_triangle(VertexOutTriangle v [[stage_in]]) {
    return float4((float)v.color.x, (float)v.color.y, (float)v.color.z, (float)v.color.w);
}

vertex VertexOutLiquid vertex_liquid(constant FragmentUniforms &uniforms [[buffer(0)]],
                                    constant float2 *positions [[buffer(1)]],
                                    constant uchar4 *color [[buffer(2)]],
                                    
                                    uint vertexID [[vertex_id]])
{
    float2 pos = positions[vertexID];
    pos.x *= uniforms.scaleX * 2;
    pos.y *= uniforms.scaleY * 2;
    pos.y *= -1;
    
    float r = uniforms.particleRadius * 8;
    
    VertexOutLiquid out {
        .position = float4(pos, 0.0, 1.0),
        .radius = r,
        .color = *color
    };
    return out;
}

fragment float4 fragment_liquid(VertexOutLiquid fragData [[stage_in]],
                                float2 pointCoord  [[point_coord]])
{
    if (length(pointCoord - float2(0.5)) > 0.5) {
        discard_fragment();
    }
    return float4(fragData.color);
}

vertex VertexOutPoint vertex_point(constant FragmentUniforms &uniforms [[buffer(0)]],
                                   constant float2 *positions [[buffer(1)]],
                                   constant float *radii [[buffer(2)]],
                                   constant uchar4 *color [[buffer(3)]],
                                   
                                   uint vertexID [[vertex_id]])
{
    float2 pos = positions[vertexID];
    pos.x *= uniforms.scaleX * 2;
    pos.y *= uniforms.scaleY * 2;
    pos.y *= -1;
    
    float r = radii[vertexID] * 8;
    
    VertexOutPoint out {
        .position = float4(pos, 0.0, 1.0),
        .radius = r,
        .color = *color
    };
    return out;
}

fragment float4 fragment_point(VertexOutPoint fragData [[stage_in]],
                               float2 pointCoord  [[point_coord]])
{
    if (length(pointCoord - float2(0.5)) > 0.5) {
        discard_fragment();
    }
    return float4(fragData.color);
}








///////



struct metaballData {
    float x;
    float y;
    float r;
    float g;
    float b;
};

kernel void
    drawMetaballs(texture2d<float, access::write> outTexture[[texture(0)]],
                  constant float *edgesBuffer[[buffer(1)]],
                  constant metaballData *metaballBuffer[[buffer(0)]],
                  uint2 gid[[thread_position_in_grid]]) {

    char numberOfMetaballs = metaballBuffer[0].x - 1;

    float sum = 0;
    float3 colorSum = float3(0, 0, 0);
    float colorAccumulation = 0;
    float3 colorSumLink = float3(0, 0, 0);

    char x, y;

    float metaballDistances[10];
    float2 metaballDirections[10];
    float3 metaballColors[10];

    for (x = 1; x <= numberOfMetaballs; x += 1) {
        metaballData metaball = metaballBuffer[x];
        float2 metaballPosition = float2(metaball.x, metaball.y);
        float2 vector = float2(metaballPosition.x - gid.x,
                               metaballPosition.y - gid.y);
        float dotProduct = dot(vector, vector);
        float squaredDistance = dotProduct > 0 ? dotProduct : 1;
        float realDistance = sqrt(squaredDistance);
        metaballDistances[x - 1] = squaredDistance;
        metaballDirections[x - 1] = vector / realDistance;
        metaballColors[x - 1] = float3(metaball.r, metaball.g, metaball.b);
    }

    float bendClose = 0.0;
    float bendCloseCount = 0.0;
    float ball = 0.0;

    for (x = 0; x < numberOfMetaballs; x += 1) {
        float distance1 = metaballDistances[x];
        float value1 = 1500 / distance1;
        float2 direction1 = metaballDirections[x];

        float colorContribution = 1 / distance1;
        colorAccumulation += colorContribution;
        colorSum += metaballColors[x] * colorContribution;

        for (y = x + 1; y < numberOfMetaballs; y += 1) {
            float distance2 = metaballDistances[y];
            float value2 = 1500 / distance2;
            float2 direction2 = metaballDirections[y];

            float v = value1 + value2;
            float weightedValue = 0.5 * v;

            char edgeIndex = y * numberOfMetaballs + x;
            float edgeWeight = edgesBuffer[edgeIndex];
            float cosine = dot(direction1, direction2);
            float link = pow(((1 - cosine) * 0.5), 100);
            float weightedLink = 0.6 * link * edgeWeight;

            float result = weightedValue + weightedLink;

            ball += step(0.4, weightedValue);

            float metaballValue = step(0.5, weightedValue + weightedLink);

            if (metaballValue > 0.0) {
                colorSumLink = float3(0.0, 0.0, 0.0);
                colorSumLink += metaballColors[x] / distance1;
                colorSumLink += metaballColors[y] / distance2;
                colorSumLink /= (1 / distance1) + (1 / distance2);
            }

            if (result > 0.4) {
                bendClose += result;
                bendCloseCount += 1.0;
            }

            sum += metaballValue;
        }
    }

    //    bendClose = bendClose / bendCloseCount;

    if (bendClose != 0.0) {
        bendClose = (bendClose - 0.4) * (1 / (0.6 - 0.4));
    } else {
        bendClose = 0.0;
    }


    float result = step(0.4, sum);
    result = clamp(result, 0.0, 1.0);

    colorSum = colorSum / colorAccumulation;

    if (result > 0.0 && ball < 1.0) {
        colorSum = colorSumLink;
    }

    colorSum *= result;

    if (colorSum.r == 0 && colorSum.g == 0 && colorSum.b == 0) {
        colorSum = float3(1, 1, 1);
    }

    outTexture.write(float4(colorSum.bgr, 1), gid);
}

