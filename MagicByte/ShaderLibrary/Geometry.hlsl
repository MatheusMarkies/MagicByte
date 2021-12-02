#ifndef GEOMETRY_INCLUDED
#define GEOMETRY_INCLUDED

#include "../../ShaderLibrary/UnityInput.hlsl"

float3 GetViewDirection(float3 WorldSpacePosition) {
    return normalize(_WorldSpaceCameraPos - WorldSpacePosition);
}

float3 GetTriangleNormal(float3 a, float3 b, float3 c) {
    return normalize(cross(b - a, c - a));
}

float3 CalculateTriangleBarycenter(float3 a, float3 b, float3 c) {
    return (a + b + c) / 3;
}
float2 CalculateTriangleBarycenter(float2 a, float2 b, float2 c) {
    return (a + b + c) / 3;
}

#endif