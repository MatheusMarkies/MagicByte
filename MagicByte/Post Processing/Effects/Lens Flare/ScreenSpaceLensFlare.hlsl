#include "../../../ShaderLibrary/UnityInput.hlsl"
#include "../../../ShaderLibrary/ColorFunction.hlsl"
#include "../../../ShaderLibrary/Simplex3D.hlsl"

float _Gamma;

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_PostFXSource);
SAMPLER(sampler_linear_clamp);

TEXTURE2D(_OldPostFXSource);
SAMPLER(sampler_OldPostFXSource);

TEXTURE2D(_RadialFXSource);
SAMPLER(sampler_RadialFXSource);

TEXTURE2D(_StarBrush);
SAMPLER(sampler_StarBrush);

TEXTURE2D(_LensDirty);
SAMPLER(sampler_LensDirty);

float4 _PostFXSource_TexelSize;

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

float4 GetSourceTexelSize() {
    return _PostFXSource_TexelSize;
}

float4 GetSource(float2 fxUV) {
    return SAMPLE_TEXTURE2D(_PostFXSource, sampler_PostFXSource, fxUV);
}

float _Bias = 1;
float _GhostIntensity = 6;
float _HaloIntensity = 6; 
float _HaloWidth = 6;
float _DirtyIntensity = 0.6f;
float _Delta;
float _DirtyOffset;
float _Distortion;

float4 Threshold(Varyings i) : SV_Target
{
    float gray = (GetSource(i.fxUV).r + GetSource(i.fxUV).g + GetSource(i.fxUV).b) / 3;
    float4 grayImage = float4(gray, gray, gray, 1);
    return saturate(pow(grayImage, _Bias.x));
}

float4 SampleBox(float2 uv, float delta)
{
    float4 o = GetSourceTexelSize().xyxy * float4(-delta, -delta, delta, delta);
    return (GetSource(uv + o.xy)
        + GetSource(uv + o.zy)
        + GetSource(uv + o.xw)
        + GetSource(uv + o.zw)) * 0.25;
}

float4 FragBox(Varyings i) : SV_Target
{
    return SampleBox(i.fxUV, _Delta);
}

static const float gaussian[7] = {
    0.00598,	0.060626,	0.241843,	0.383103,	0.241843,	0.060626,	0.00598
};

float4 FragHBlur(Varyings i) : SV_Target
{
    float4 color;
    float2 o = float2(GetSourceTexelSize().x, 0);
    for (int idx = -3; idx <= 3; idx++) {
        float4 tColor = GetSource(i.fxUV + idx * o);
        color += tColor * gaussian[idx + 3];
    }
    return color;
}

float4 FragVBlur(Varyings i) : SV_Target
{
    float4 color;
    float2 o = float2(0, GetSourceTexelSize().y);
    for (int idx = -3; idx <= 3; idx++) {
        float4 tColor = GetSource(i.fxUV + idx * o);
        color += tColor * gaussian[idx + 3];
    }
    return color;
}

float3 ChromaticAberration(float2 uv, float2 direction, float3 distortion)
{
    return float3(
        GetSource(uv + direction * distortion.r).r,
        GetSource(uv + direction * distortion.g).g,
        GetSource(uv + direction * distortion.b).b);
}

float4 FragRadialWarp(Varyings i) : SV_Target
{
    float2 ghostVec = i.fxUV - 0.5;

    float2 haloVec = normalize(ghostVec) * _HaloWidth;
    float weight = length(float2(0.5, 0.5) - frac(i.fxUV + haloVec)) / length(float2(0.5, 0.5));
    weight = pow(1.0 - _HaloIntensity, 9.0);

    float4 starBrush = pow(SAMPLE_TEXTURE2D(_StarBrush, sampler_StarBrush, i.fxUV * _DirtyOffset), _Gamma);
    float4 lensDirty = pow(SAMPLE_TEXTURE2D(_LensDirty, sampler_LensDirty, i.fxUV * _DirtyOffset), _Gamma);

    float4 comp = GetSource(i.fxUV + haloVec) * _HaloIntensity * lerp(float4(1, 1, 1, 1), (starBrush + lensDirty), _DirtyIntensity) * 0.5f;

    return float4(comp.rgb,1);
}

static const float ghosts[9] = {
    0.625,	0.390625,	0.24414,	0.15258,    -0.625,	-0.390625,	-0.24414,	-0.15258,   -0.09536,
};

float4 FragGhost(Varyings i) : SV_Target
{
    float4 color = float4(0, 0, 0, 0);
    float2 uv = i.fxUV;
    for (int i = 0; i < 9; i++) {
        float t_p = ghosts[i];
        color += GetSource((uv - 0.5) * t_p + 0.5) * (t_p * t_p);
    }
    float4 comp = color * _GhostIntensity + SAMPLE_TEXTURE2D(_RadialFXSource, sampler_RadialFXSource, uv);
    return float4(comp.rgb,1);
}

float4 ChromaticAberrationRadial(float2 uv) {
    float ss = 400 + (230 * length(uv - 0.5) * 1.7f);
    float3 color = ZucconiGradientFunction(ss);
    color = lerp(color, float3(1, 1, 1), 0.4);
    return float4(color,1);
}

float4 Composite(Varyings i) : SV_Target
{
    float3 distortion = float3(-GetSourceTexelSize().x * _Distortion, 0.0, GetSourceTexelSize().x * _Distortion);
    float2 direction = normalize(i.fxUV - 0.5);
    float3 Chromatic = ChromaticAberration(i.fxUV, direction, distortion);

    float4 color = float4(Chromatic, 1) + SAMPLE_TEXTURE2D(_OldPostFXSource, sampler_OldPostFXSource, i.fxUV);

    return float4(max(float3(0.1, 0.1, 0.1),color.rgb),1);
}