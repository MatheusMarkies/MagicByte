#ifndef BLOOM_PASS
#define BLOOM_PASS

#include "../../../ShaderLibrary/UnityInput.hlsl"
#include "../../../ShaderLibrary/Core RP/ShaderDependencies/Filtering.hlsl"

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_PostFXSource);
SAMPLER(sampler_linear_clamp);

TEXTURE2D(_OldPostFXSource);
SAMPLER(sampler_OldPostFXSource);

TEXTURE2D(_OldBloomSource);
SAMPLER(sampler_OldBloomSource);

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

float Brightness(float3 c)
{
    return max(max(c.r, c.g), c.b);
}

float3 Median(float3 a, float3 b, float3 c)
{
    return a + b + c - min(min(a, b), c) - max(max(a, b), c);
}

half3 SafeHDR(half3 c) { return min(c, 65000); }
half4 SafeHDR(half4 c) { return min(c, 65000); }

half4 EncodeHDR(float3 rgb)
{
#if USE_RGBM
    rgb *= 1.0 / 8;
    float m = max(max(rgb.r, rgb.g), max(rgb.b, 1e-6));
    m = ceil(m * 255) / 255;
    return half4(rgb / m, m);
#else
    return half4(rgb, 0);
#endif
}

float3 DecodeHDR(half4 rgba)
{
#if USE_RGBM
    return rgba.rgb * rgba.a * 8;
#else
    return rgba.rgb;
#endif
}

float4 GetSource(float2 fxUV) {
    return SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, fxUV);
}

float4 GetSourceTexelSize() {
    return _PostFXSource_TexelSize;
}

half3 SampleBox(float2 uv) {
    float4 o = GetSourceTexelSize().xyxy * float2(-1, 1).xxyy;
    half3 s =
        GetSource(uv + o.xy) 
        + GetSource(uv + o.zy) +
        GetSource(uv + o.xw) 
        + GetSource(uv + o.zw);
    return s * 0.25f;
}

float4 _BloomThreshold;
float _BloomIntensity;
float _BloomScattering;
float _BloomFog;

float3 ApplyBloomThreshold(float3 color, float2 fxUV) {
    float brightness = Max3(color.r, color.g, color.b);
    float soft = brightness + _BloomThreshold.y;
    soft = clamp(soft, 0.0, _BloomThreshold.z);
    soft = soft * soft * _BloomThreshold.w;
    float contribution = max(soft, brightness - _BloomThreshold.x);
    contribution /= max(brightness, 0.00001);

    float2 uv = fxUV + _PostFXSource_TexelSize.xy * 1;

float3 d = _PostFXSource_TexelSize.xyx * float3(1, 1, 0);
half4 s0 = SafeHDR(GetSource(uv));
half3 s1 = SafeHDR(GetSource(uv - d.xz).rgb);
half3 s2 = SafeHDR(GetSource(uv + d.xz).rgb);
half3 s3 = SafeHDR(GetSource(uv - d.zy).rgb);
half3 s4 = SafeHDR(GetSource(uv + d.zy).rgb);

half3 m = Median(Median(s0.rgb, s1, s2), s3, s4);

    return m * contribution;
}

float4 PreFilter(Varyings i) : SV_TARGET{
    float3 color = pow(saturate(ApplyBloomThreshold(GetSource(i.fxUV).rgb,i.fxUV)),3);

    return EncodeHDR(color);
}

int _Levels;

float4 FragBox(Varyings i) : SV_Target
{
    return float4(SampleBox(i.fxUV),1);
}

static const float gaussian[14] = {
    0.00598,	0.060626,	0.241843,	0.383103,	0.241843,	0.060626,	0.00598,
    0.02400,	0.0160125,	0.741843,	0.455653,	0.296803,	0.189060,	0.18406
};

float4 FragHBlur(Varyings i) : SV_Target
{
    float4 color;
    float2 o = float2(GetSourceTexelSize().x, 0);
    for (int idx = -3; idx <= 3; idx++) {
        float4 tColor = float4(DecodeHDR(GetSource(i.fxUV + idx * o)),1);
        color += tColor * gaussian[idx + 3];
    }
    return float4(color.rgb, 1 / _Levels);
}

float4 FragVBlur(Varyings i) : SV_Target
{
    float4 color;
    float2 o = float2(0, GetSourceTexelSize().y);
    for (int idx = -3; idx <= 3; idx++) {
        float4 tColor = float4(DecodeHDR(GetSource(i.fxUV + idx * o)), 1);
        color += tColor * gaussian[idx + 3];
    }
    return float4(color.rgb, 1 / _Levels);
}

float4 GetSourceBicubic(float2 uv) {
    return SampleTexture2DBicubic(
        TEXTURE2D_ARGS(_PostFXSource, sampler_linear_clamp), uv,
        _PostFXSource_TexelSize.zwxy, 1.0, 0.0
    );
}

float4 Additive(Varyings i) : SV_Target
{
    float4 color;
    float4 oldColor = SAMPLE_TEXTURE2D(_OldBloomSource, sampler_OldBloomSource, i.fxUV);
    //oldColor.rgb = oldColor.rgb - ApplyBloomThreshold(oldColor.rgb);
    color = lerp(float4(oldColor.rgb, 1),float4(DecodeHDR(GetSourceBicubic(i.fxUV)), 1),_BloomScattering);

    return float4(color.rgb, 1);
}

float4 Composite(Varyings i) : SV_TARGET{
    float4 color = float4(DecodeHDR(GetSource(i.fxUV)),1) * _BloomIntensity + SAMPLE_TEXTURE2D(_OldPostFXSource, sampler_OldPostFXSource, i.fxUV);
    return color;
}

#endif