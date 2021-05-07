#include "../../ShaderLibrary/UnityInput.hlsl"
#include "../../ShaderLibrary/ColorFunction.hlsl"
#include "../../ShaderLibrary/Simplex3D.hlsl"

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_PostFXSource);
SAMPLER(sampler_linear_clamp);

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct Varyings {
    float4 positionCS : SV_POSITION;
    float2 fxUV : VAR_FX_UV;
};

Varyings DefaultPassVertex(uint vertexID: SV_VertexID) {
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

float _Threshold;

float3 Threshold(float3 color) {
    float brightness = (color.r + color.g+color.b)/3;
    brightness = pow(brightness, _Threshold);
    return brightness;
}
float4 GetSource(float2 fxUV) {
    return SAMPLE_TEXTURE2D(_PostFXSource, sampler_PostFXSource, fxUV);
}

float4 Thresholder(Varyings i) : SV_Target
{
    return float4(Threshold(GetSource(i.fxUV)),1);
}

static const float ghosts[9] = {
    0.05870,
    0.176548,
    -0.0954567,
    0.208574,
    0.303365,
    -0.32452345,
    -0.2345414,
    -0.1677848,
    0.1156776,
};
float4 ChromaticAberration(float2 chromaticAberration, float2 uv) {
    float colR = GetSource(float2(uv.x - chromaticAberration.x, uv.y - chromaticAberration.x)).r;
    float colG = GetSource(float2(uv)).g;
    float colB = GetSource(float2(uv.x + chromaticAberration.x, uv.y + chromaticAberration.x)).b;

    return float4(lerp(float3(lerp(colR, colG, uv.x * 0.3), lerp(colG, colB, uv.x * 0.3), lerp(colR, colB, uv.x * 0.3)), GetSource(uv), 0.25), 1);
}
float4 ghostPass(Varyings i) : SV_Target{

    float4 color = GetSource(i.fxUV);
    float4 colorChannel = GetSource(i.fxUV);

    float2 ghost = (float2(0.5, 0.5) - i.fxUV) * 0.4;

    float4 result = float4(0, 0, 0, 0);
    float2 fxUV = i.fxUV;
    float2 uv = i.fxUV - 0.5;
    for (int i = 0; i < 6; i++) {
        float t_p = ghosts[i];
        result.rgb += float3(ChromaticAberration(float2(0.0009, 0.005), uv * 1 * t_p + 0.5).r, ChromaticAberration(float2(0.0009, 0.005), uv * 1 * t_p + 0.5).g, ChromaticAberration(float2(0.0009, 0.005), uv * 1 * t_p + 0.5).b) * (t_p * t_p);

    }

    float2 haloUv = normalize(uv) * -0.5;
    result.rgb += ((color * 0.005) + max(float3(ChromaticAberration(float2(0.0009, 0.005), fxUV + haloUv).r, ChromaticAberration(float2(0.0009, 0.005), fxUV + haloUv).g, ChromaticAberration(float2(0.0009, 0.005), fxUV + haloUv).b) - 0.0, 0) * length(uv) * 0.0025);

 return float4(colorChannel.rgb + result, color.a);

}
