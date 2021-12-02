#ifndef STANDARD_PASS
#define STANDARD_PASS

#include "../../../ShaderLibrary/UnityInput.hlsl"

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_PostFXSource);
SAMPLER(sampler_linear_clamp);

float4 _PostFXSource_TexelSize;

float _Attenuation;
float4 _Direction;
float _Offset;

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

float4 frag(Varyings i) : SV_Target
{
      float4 color = GetSource(i.fxUV);

      float2 dx = GetSourceTexelSize().xy;

      float attenuationSquared = _Attenuation * _Attenuation;
      float attenuationCubed = _Attenuation * _Attenuation * _Attenuation;

      return color + _Attenuation * GetSource(i.fxUV + _Offset * _Direction.xy * dx) + attenuationSquared * GetSource(i.fxUV + 2 * _Offset * _Direction.xy * dx) + attenuationCubed * GetSource(i.fxUV + 3 * _Offset * _Direction.xy * dx);
}

#endif