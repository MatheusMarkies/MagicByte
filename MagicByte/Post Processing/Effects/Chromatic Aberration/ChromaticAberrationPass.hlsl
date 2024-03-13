#ifndef STANDARD_PASS
#define STANDARD_PASS

#include "../../../ShaderLibrary/UnityInput.hlsl"

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_PostFXSource);
SAMPLER(sampler_linear_clamp);

float4 _PostFXSource_TexelSize;
float _Distortion = 10;

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct Varyings {
    float4 positionCS : SV_POSITION;
    float2 fxUV : VAR_FX_UV;
};

Varyings DefaultPassVertex(uint vertexID : SV_VertexID) {
    Varyings output;
    output.positionCS = float4(
        vertexID <= 1 ? -1.0 : 3.0,
        vertexID == 1 ? 3.0 : -1.0,
        0.0, 1.0
        );
    output.fxUV = float2(
        vertexID <= 1 ? 0.0 : 2.0,
        vertexID == 1 ? 2.0 : 0.0
        );
    if (_ProjectionParams.x < 0.0) {
        output.fxUV.y = 1.0 - output.fxUV.y;
    }
    return output;
}

float4 GetSource(float2 fxUV) {
    return SAMPLE_TEXTURE2D(_PostFXSource, sampler_PostFXSource, fxUV);
}

float4 GetSourceTexelSize() {
    return _PostFXSource_TexelSize;
}

float3 ChromaticAberration(float2 uv, float2 direction, float3 distortion)
{
    return float3(
        GetSource(uv + direction * distortion.r).r,
        GetSource(uv + direction * distortion.g).g,
        GetSource(uv + direction * distortion.b).b);
}

float4 frag(Varyings i) : SV_Target
{
   float4 color = GetSource(i.fxUV);

   float3 distortion = float3(-GetSourceTexelSize().x * _Distortion, 0.0, GetSourceTexelSize().x * _Distortion);
   float2 direction = normalize(i.fxUV - 0.5);

   return float4(ChromaticAberration(i.fxUV, direction, distortion),1);
}

#endif