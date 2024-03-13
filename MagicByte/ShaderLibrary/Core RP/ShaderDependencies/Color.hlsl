#ifndef UNITY_MAGICBYTE_COLOR_INCLUDED
#define UNITY_MAGICBYTE_COLOR_INCLUDED

#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (disable : 3205) // conversion of larger type to smaller
#endif

#include "ACES.hlsl"

//-----------------------------------------------------------------------------
// Gamma space - Assume positive values
//-----------------------------------------------------------------------------

// Gamma20
float Gamma20ToLinear(float c)
{
    return c * c;
}

float3 Gamma20ToLinear(float3 c)
{
    return c.rgb * c.rgb;
}

float4 Gamma20ToLinear(float4 c)
{
    return float4(Gamma20ToLinear(c.rgb), c.a);
}

float LinearToGamma20(float c)
{
    return sqrt(c);
}

float3 LinearToGamma20(float3 c)
{
    return sqrt(c.rgb);
}

float4 LinearToGamma20(float4 c)
{
    return float4(LinearToGamma20(c.rgb), c.a);
}

// Gamma22
float Gamma22ToLinear(float c)
{
    return PositivePow(c, 2.2);
}

float3 Gamma22ToLinear(float3 c)
{
    return PositivePow(c.rgb, float3(2.2, 2.2, 2.2));
}

float4 Gamma22ToLinear(float4 c)
{
    return float4(Gamma22ToLinear(c.rgb), c.a);
}

float LinearToGamma22(float c)
{
    return PositivePow(c, 0.454545454545455);
}

float3 LinearToGamma22(float3 c)
{
    return PositivePow(c.rgb, float3(0.454545454545455, 0.454545454545455, 0.454545454545455));
}

float4 LinearToGamma22(float4 c)
{
    return float4(LinearToGamma22(c.rgb), c.a);
}

// sRGB
float SRGBToLinear(float c)
{
#if defined(UNITY_COLORSPACE_GAMMA) && float_IS_HALF
    c = min(c, 100.0); // Make sure not to exceed HALF_MAX after the pow() below
#endif
    float linearRGBLo  = c / 12.92;
    float linearRGBHi  = PositivePow((c + 0.055) / 1.055, 2.4);
    float linearRGB    = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
    return linearRGB;
}

float2 SRGBToLinear(float2 c)
{
#if defined(UNITY_COLORSPACE_GAMMA) && float_IS_HALF
    c = min(c, 100.0); // Make sure not to exceed HALF_MAX after the pow() below
#endif
    float2 linearRGBLo  = c / 12.92;
    float2 linearRGBHi  = PositivePow((c + 0.055) / 1.055, float2(2.4, 2.4));
    float2 linearRGB    = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
    return linearRGB;
}

float3 SRGBToLinear(float3 c)
{
#if defined(UNITY_COLORSPACE_GAMMA) && float_IS_HALF
    c = min(c, 100.0); // Make sure not to exceed HALF_MAX after the pow() below
#endif
    float3 linearRGBLo  = c / 12.92;
    float3 linearRGBHi  = PositivePow((c + 0.055) / 1.055, float3(2.4, 2.4, 2.4));
    float3 linearRGB    = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
    return linearRGB;
}

float4 SRGBToLinear(float4 c)
{
    return float4(SRGBToLinear(c.rgb), c.a);
}

float LinearToSRGB(float c)
{
    float sRGBLo = c * 12.92;
    float sRGBHi = (PositivePow(c, 1.0/2.4) * 1.055) - 0.055;
    float sRGB   = (c <= 0.0031308) ? sRGBLo : sRGBHi;
    return sRGB;
}

float2 LinearToSRGB(float2 c)
{
    float2 sRGBLo = c * 12.92;
    float2 sRGBHi = (PositivePow(c, float2(1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
    float2 sRGB   = (c <= 0.0031308) ? sRGBLo : sRGBHi;
    return sRGB;
}

float3 LinearToSRGB(float3 c)
{
    float3 sRGBLo = c * 12.92;
    float3 sRGBHi = (PositivePow(c, float3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
    float3 sRGB   = (c <= 0.0031308) ? sRGBLo : sRGBHi;
    return sRGB;
}

float4 LinearToSRGB(float4 c)
{
    return float4(LinearToSRGB(c.rgb), c.a);
}

// TODO: Seb - To verify and refit!
// Ref: http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
float FastSRGBToLinear(float c)
{
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

float2 FastSRGBToLinear(float2 c)
{
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

float3 FastSRGBToLinear(float3 c)
{
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

float4 FastSRGBToLinear(float4 c)
{
    return float4(FastSRGBToLinear(c.rgb), c.a);
}

float FastLinearToSRGB(float c)
{
    return saturate(1.055 * PositivePow(c, 0.416666667) - 0.055);
}

float2 FastLinearToSRGB(float2 c)
{
    return saturate(1.055 * PositivePow(c, 0.416666667) - 0.055);
}

float3 FastLinearToSRGB(float3 c)
{
    return saturate(1.055 * PositivePow(c, 0.416666667) - 0.055);
}

float4 FastLinearToSRGB(float4 c)
{
    return float4(FastLinearToSRGB(c.rgb), c.a);
}

//-----------------------------------------------------------------------------
// Color space
//-----------------------------------------------------------------------------

// Convert rgb to luminance
// with rgb in linear space with sRGB primaries and D65 white point
#ifndef BUILTIN_TARGET_API
float Luminance(float3 linearRgb)
{
    return dot(linearRgb, float3(0.2126729, 0.7151522, 0.0721750));
}
#endif

float Luminance(float4 linearRgba)
{
    return Luminance(linearRgba.rgb);
}

float AcesLuminance(float3 linearRgb)
{
    return dot(linearRgb, AP1_RGB2Y);
}

float AcesLuminance(float4 linearRgba)
{
    return AcesLuminance(linearRgba.rgb);
}

// Scotopic luminance approximation - input is in XYZ space
// Note: the range of values returned is approximately [0;4]
// "A spatial postprocessing algorithm for images of night scenes"
// William B. Thompson, Peter Shirley, and James A. Ferwerda
float ScotopicLuminance(float3 xyzRgb)
{
    float X = xyzRgb.x;
    float Y = xyzRgb.y;
    float Z = xyzRgb.z;
    return Y * (1.33 * (1.0 + (Y + Z) / X) - 1.68);
}

float ScotopicLuminance(float4 xyzRgba)
{
    return ScotopicLuminance(xyzRgba.rgb);
}

// This function take a rgb color (best is to provide color in sRGB space)
// and return a YCoCg color in [0..1] space for 8bit (An offset is apply in the function)
// Ref: http://www.nvidia.com/object/float-time-ycocg-dxt-compression.html
#define YCOCG_CHROMA_BIAS (128.0 / 255.0)
float3 RGBToYCoCg(float3 rgb)
{
    float3 YCoCg;
    YCoCg.x = dot(rgb, float3(0.25, 0.5, 0.25));
    YCoCg.y = dot(rgb, float3(0.5, 0.0, -0.5)) + YCOCG_CHROMA_BIAS;
    YCoCg.z = dot(rgb, float3(-0.25, 0.5, -0.25)) + YCOCG_CHROMA_BIAS;

    return YCoCg;
}

float3 YCoCgToRGB(float3 YCoCg)
{
    float Y = YCoCg.x;
    float Co = YCoCg.y - YCOCG_CHROMA_BIAS;
    float Cg = YCoCg.z - YCOCG_CHROMA_BIAS;

    float3 rgb;
    rgb.r = Y + Co - Cg;
    rgb.g = Y + Cg;
    rgb.b = Y - Co - Cg;

    return rgb;
}

// Following function can be use to reconstruct chroma component for a checkboard YCoCg pattern
// Reference: The Compact YCoCg Frame Buffer
float YCoCgCheckBoardEdgeFilter(float centerLum, float2 a0, float2 a1, float2 a2, float2 a3)
{
    float4 lum = float4(a0.x, a1.x, a2.x, a3.x);
    // Optimize: float4 w = 1.0 - step(30.0 / 255.0, abs(lum - centerLum));
    float4 w = 1.0 - saturate((abs(lum.xxxx - centerLum) - 30.0 / 255.0) * HALF_MAX);
    float W = w.x + w.y + w.z + w.w;
    // handle the special case where all the weights are zero.
    return  (W == 0.0) ? a0.y : (w.x * a0.y + w.y* a1.y + w.z* a2.y + w.w * a3.y) / W;
}

// Converts linear RGB to LMS
// Full float precision to avoid precision artefact when using ACES tonemapping
float3 LinearToLMS(float3 x)
{
    const float3x3 LIN_2_LMS_MAT = {
        3.90405e-1, 5.49941e-1, 8.92632e-3,
        7.08416e-2, 9.63172e-1, 1.35775e-3,
        2.31082e-2, 1.28021e-1, 9.36245e-1
    };

    return mul(LIN_2_LMS_MAT, x);
}

// Full float precision to avoid precision artefact when using ACES tonemapping
float3 LMSToLinear(float3 x)
{
    const float3x3 LMS_2_LIN_MAT = {
        2.85847e+0, -1.62879e+0, -2.48910e-2,
        -2.10182e-1,  1.15820e+0,  3.24281e-4,
        -4.18120e-2, -1.18169e-1,  1.06867e+0
    };

    return mul(LMS_2_LIN_MAT, x);
}

// Hue, Saturation, Value
// Ranges:
//  Hue [0.0, 1.0]
//  Sat [0.0, 1.0]
//  Lum [0.0, HALF_MAX]
float3 RgbToHsv(float3 c)
{
    const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    const float e = 1.0e-4;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HsvToRgb(float3 c)
{
    const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float RotateHue(float value, float low, float hi)
{
    return (value < low)
            ? value + hi
            : (value > hi)
                ? value - hi
                : value;
}

// Soft-light blending mode use for split-toning. Works in HDR as long as `blend` is [0;1] which is
// fine for our use case.
float3 SoftLight(float3 base, float3 blend)
{
    float3 r1 = 2.0 * base * blend + base * base * (1.0 - 2.0 * blend);
    float3 r2 = sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend);
    float3 t = step(0.5, blend);
    return r2 * t + (1.0 - t) * r1;
}

// SMPTE ST.2084 (PQ) transfer functions
// 1.0 = 100nits, 100.0 = 10knits
#define DEFAULT_MAX_PQ 100.0

struct ParamsPQ
{
    float N, M;
    float C1, C2, C3;
};

static const ParamsPQ PQ =
{
    2610.0 / 4096.0 / 4.0,   // N
    2523.0 / 4096.0 * 128.0, // M
    3424.0 / 4096.0,         // C1
    2413.0 / 4096.0 * 32.0,  // C2
    2392.0 / 4096.0 * 32.0,  // C3
};

float3 LinearToPQ(float3 x, float maxPQValue)
{
    x = PositivePow(x / maxPQValue, PQ.N);
    float3 nd = (PQ.C1 + PQ.C2 * x) / (1.0 + PQ.C3 * x);
    return PositivePow(nd, PQ.M);
}

float3 LinearToPQ(float3 x)
{
    return LinearToPQ(x, DEFAULT_MAX_PQ);
}

float3 PQToLinear(float3 x, float maxPQValue)
{
    x = PositivePow(x, rcp(PQ.M));
    float3 nd = max(x - PQ.C1, 0.0) / (PQ.C2 - (PQ.C3 * x));
    return PositivePow(nd, rcp(PQ.N)) * maxPQValue;
}

float3 PQToLinear(float3 x)
{
    return PQToLinear(x, DEFAULT_MAX_PQ);
}

// Alexa LogC converters (El 1000)
// See http://www.vocas.nl/webfm_send/964
// Max range is ~58.85666

// Set to 1 to use more precise but more expensive log/linear conversions. I haven't found a proper
// use case for the high precision version yet so I'm leaving this to 0.
#define USE_PRECISE_LOGC 0

struct ParamsLogC
{
    float cut;
    float a, b, c, d, e, f;
};

static const ParamsLogC LogC =
{
    0.011361, // cut
    5.555556, // a
    0.047996, // b
    0.244161, // c
    0.386036, // d
    5.301883, // e
    0.092819  // f
};

float LinearToLogC_Precise(float x)
{
    float o;
    if (x > LogC.cut)
        o = LogC.c * log10(max(LogC.a * x + LogC.b, 0.0)) + LogC.d;
    else
        o = LogC.e * x + LogC.f;
    return o;
}

// Full float precision to avoid precision artefact when using ACES tonemapping
float3 LinearToLogC(float3 x)
{
#if USE_PRECISE_LOGC
    return float3(
        LinearToLogC_Precise(x.x),
        LinearToLogC_Precise(x.y),
        LinearToLogC_Precise(x.z)
    );
#else
    return LogC.c * log10(max(LogC.a * x + LogC.b, 0.0)) + LogC.d;
#endif
}

float LogCToLinear_Precise(float x)
{
    float o;
    if (x > LogC.e * LogC.cut + LogC.f)
        o = (pow(10.0, (x - LogC.d) / LogC.c) - LogC.b) / LogC.a;
    else
        o = (x - LogC.f) / LogC.e;
    return o;
}

// Full float precision to avoid precision artefact when using ACES tonemapping
float3 LogCToLinear(float3 x)
{
#if USE_PRECISE_LOGC
    return float3(
        LogCToLinear_Precise(x.x),
        LogCToLinear_Precise(x.y),
        LogCToLinear_Precise(x.z)
    );
#else
    return (pow(10.0, (x - LogC.d) / LogC.c) - LogC.b) / LogC.a;
#endif
}

//-----------------------------------------------------------------------------
// Utilities
//-----------------------------------------------------------------------------

float3 Desaturate(float3 value, float saturation)
{
    // Saturation = Colorfulness / Brightness.
    // https://munsell.com/color-blog/difference-chroma-saturation/
    float  mean = Avg3(value.r, value.g, value.b);
    float3 dev  = value - mean;

    return mean + dev * saturation;
}

// Fast reversible tonemapper
// http://gpuopen.com/optimized-reversible-tonemapper-for-resolve/
float FastTonemapPerChannel(float c)
{
    return c * rcp(c + 1.0);
}

float2 FastTonemapPerChannel(float2 c)
{
    return c * rcp(c + 1.0);
}

float3 FastTonemap(float3 c)
{
    return c * rcp(Max3(c.r, c.g, c.b) + 1.0);
}

float4 FastTonemap(float4 c)
{
    return float4(FastTonemap(c.rgb), c.a);
}

float3 FastTonemap(float3 c, float w)
{
    return c * (w * rcp(Max3(c.r, c.g, c.b) + 1.0));
}

float4 FastTonemap(float4 c, float w)
{
    return float4(FastTonemap(c.rgb, w), c.a);
}

float FastTonemapPerChannelInvert(float c)
{
    return c * rcp(1.0 - c);
}

float2 FastTonemapPerChannelInvert(float2 c)
{
    return c * rcp(1.0 - c);
}

float3 FastTonemapInvert(float3 c)
{
    return c * rcp(1.0 - Max3(c.r, c.g, c.b));
}

float4 FastTonemapInvert(float4 c)
{
    return float4(FastTonemapInvert(c.rgb), c.a);
}

#ifndef SHADER_API_GLES
// 3D LUT grading
// scaleOffset = (1 / lut_size, lut_size - 1)
float3 ApplyLut3D(TEXTURE3D_PARAM(tex, samplerTex), float3 uvw, float2 scaleOffset)
{
    uvw.xyz = uvw.xyz * scaleOffset.yyy * scaleOffset.xxx + scaleOffset.xxx * 0.5;
    return SAMPLE_TEXTURE3D_LOD(tex, samplerTex, uvw, 0.0).rgb;
}
#endif

// 2D LUT grading
// scaleOffset = (1 / lut_width, 1 / lut_height, lut_height - 1)
float3 ApplyLut2D(TEXTURE2D_PARAM(tex, samplerTex), float3 uvw, float3 scaleOffset)
{
    // Strip format where `height = sqrt(width)`
    uvw.z *= scaleOffset.z;
    float shift = floor(uvw.z);
    uvw.xy = uvw.xy * scaleOffset.z * scaleOffset.xy + scaleOffset.xy * 0.5;
    uvw.x += shift * scaleOffset.y;
    uvw.xyz = lerp(
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy, 0.0).rgb,
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy + float2(scaleOffset.y, 0.0), 0.0).rgb,
        uvw.z - shift
    );
    return uvw;
}

// Returns the default value for a given position on a 2D strip-format color lookup table
// params = (lut_height, 0.5 / lut_width, 0.5 / lut_height, lut_height / lut_height - 1)
float3 GetLutStripValue(float2 uv, float4 params)
{
    uv -= params.yz;
    float3 color;
    color.r = frac(uv.x * params.x);
    color.b = uv.x - color.r / params.x;
    color.g = uv.y;
    return color * params.w;
}

// Neutral tonemapping (Hable/Hejl/Frostbite)
// Input is linear RGB
// More accuracy to avoid NaN on extremely high values.
float3 NeutralCurve(float3 x, float a, float b, float c, float d, float e, float f)
{
    return ((x * (a * x + c * b) + d * e) / (x * (a * x + b) + d * f)) - e / f;
}

#define TONEMAPPING_CLAMP_MAX 435.18712 //(-b + sqrt(b * b - 4 * a * (HALF_MAX - d * f))) / (2 * a * whiteScale)
//Extremely high values cause NaN output when using fp16, we clamp to avoid the performace hit of switching to fp32
//The overflow happens in (x * (a * x + b) + d * f) of the NeutralCurve, highest value that avoids fp16 precision errors is ~571.56873
//Since whiteScale is constant (~1.31338) max input is ~435.18712

float3 NeutralTonemap(float3 x)
{
    // Tonemap
    const float a = 0.2;
    const float b = 0.29;
    const float c = 0.24;
    const float d = 0.272;
    const float e = 0.02;
    const float f = 0.3;
    const float whiteLevel = 5.3;
    const float whiteClip = 1.0;

#if defined(SHADER_API_MOBILE)
    x = min(x, TONEMAPPING_CLAMP_MAX);
#endif

    float3 whiteScale = (1.0).xxx / NeutralCurve(whiteLevel, a, b, c, d, e, f);
    x = NeutralCurve(x * whiteScale, a, b, c, d, e, f);
    x *= whiteScale;

    // Post-curve white point adjustment
    x /= whiteClip.xxx;

    return x;
}

// Raw, unoptimized version of John Hable's artist-friendly tone curve
// Input is linear RGB
float EvalCustomSegment(float x, float4 segmentA, float2 segmentB)
{
    const float kOffsetX = segmentA.x;
    const float kOffsetY = segmentA.y;
    const float kScaleX  = segmentA.z;
    const float kScaleY  = segmentA.w;
    const float kLnA     = segmentB.x;
    const float kB       = segmentB.y;

    float x0 = (x - kOffsetX) * kScaleX;
    float y0 = (x0 > 0.0) ? exp(kLnA + kB * log(x0)) : 0.0;
    return y0 * kScaleY + kOffsetY;
}

float EvalCustomCurve(float x, float3 curve, float4 toeSegmentA, float2 toeSegmentB, float4 midSegmentA, float2 midSegmentB, float4 shoSegmentA, float2 shoSegmentB)
{
    float4 segmentA;
    float2 segmentB;

    if (x < curve.y)
    {
        segmentA = toeSegmentA;
        segmentB = toeSegmentB;
    }
    else if (x < curve.z)
    {
        segmentA = midSegmentA;
        segmentB = midSegmentB;
    }
    else
    {
        segmentA = shoSegmentA;
        segmentB = shoSegmentB;
    }

    return EvalCustomSegment(x, segmentA, segmentB);
}

// curve: x: inverseWhitePoint, y: x0, z: x1
float3 CustomTonemap(float3 x, float3 curve, float4 toeSegmentA, float2 toeSegmentB, float4 midSegmentA, float2 midSegmentB, float4 shoSegmentA, float2 shoSegmentB)
{
    float3 normX = x * curve.x;
    float3 ret;
    ret.x = EvalCustomCurve(normX.x, curve, toeSegmentA, toeSegmentB, midSegmentA, midSegmentB, shoSegmentA, shoSegmentB);
    ret.y = EvalCustomCurve(normX.y, curve, toeSegmentA, toeSegmentB, midSegmentA, midSegmentB, shoSegmentA, shoSegmentB);
    ret.z = EvalCustomCurve(normX.z, curve, toeSegmentA, toeSegmentB, midSegmentA, midSegmentB, shoSegmentA, shoSegmentB);
    return ret;
}

// Coming from STP, to replace when STP lands. 
#define SAT 8.0f
float3 InvertibleTonemap(float3 x)
{
    float y = rcp(float(SAT) + Max3(x.r, x.g, x.b));
    return saturate(x * float(y));
}

float3 InvertibleTonemapInverse(float3 x)
{
    float y = rcp(max(float(1.0 / 32768.0), saturate(float(1.0 / SAT) - Max3(x.r, x.g, x.b) * float(1.0 / SAT))));
    return x * y;
}

// Filmic tonemapping (ACES fitting, unless TONEMAPPING_USE_FULL_ACES is set to 1)
// Input is ACES2065-1 (AP0 w/ linear encoding)
#define TONEMAPPING_USE_FULL_ACES 0

float3 AcesTonemap(float3 aces)
{
#if TONEMAPPING_USE_FULL_ACES

    float3 oces = RRT(aces);
    float3 odt = ODT_RGBmonitor_100nits_dim(oces);
    return odt;

#else

    // --- Glow module --- //
    float saturation = rgb_2_saturation(aces);
    float ycIn = rgb_2_yc(aces);
    float s = sigmoid_shaper((saturation - 0.4) / 0.2);
    float addedGlow = 1.0 + glow_fwd(ycIn, RRT_GLOW_GAIN * s, RRT_GLOW_MID);
    aces *= addedGlow;

    // --- Red modifier --- //
    float hue = rgb_2_hue(aces);
    float centeredHue = center_hue(hue, RRT_RED_HUE);
    float hueWeight;
    {
        //hueWeight = cubic_basis_shaper(centeredHue, RRT_RED_WIDTH);
        hueWeight = smoothstep(0.0, 1.0, 1.0 - abs(2.0 * centeredHue / RRT_RED_WIDTH));
        hueWeight *= hueWeight;
    }

    aces.r += hueWeight * saturation * (RRT_RED_PIVOT - aces.r) * (1.0 - RRT_RED_SCALE);

    // --- ACES to RGB rendering space --- //
    float3 acescg = max(0.0, ACES_to_ACEScg(aces));

    // --- Global desaturation --- //
    //acescg = mul(RRT_SAT_MAT, acescg);
    acescg = lerp(dot(acescg, AP1_RGB2Y).xxx, acescg, RRT_SAT_FACTOR.xxx);

    // Luminance fitting of *RRT.a1.0.3 + ODT.Academy.RGBmonitor_100nits_dim.a1.0.3*.
    // https://github.com/colour-science/colour-unity/blob/master/Assets/Colour/Notebooks/CIECAM02_Unity.ipynb
    // RMSE: 0.0012846272106
#if defined(SHADER_API_SWITCH) // Fix floating point overflow on extremely large values.
    const float a = 2.785085 * 0.01;
    const float b = 0.107772 * 0.01;
    const float c = 2.936045 * 0.01;
    const float d = 0.887122 * 0.01;
    const float e = 0.806889 * 0.01;
    float3 x = acescg;
    float3 rgbPost = ((a * x + b)) / ((c * x + d) + e/(x + FLT_MIN));
#else
    const float a = 2.785085;
    const float b = 0.107772;
    const float c = 2.936045;
    const float d = 0.887122;
    const float e = 0.806889;
    float3 x = acescg;
    float3 rgbPost = (x * (a * x + b)) / (x * (c * x + d) + e);
#endif

    // Scale luminance to linear code value
    // float3 linearCV = Y_2_linCV(rgbPost, CINEMA_WHITE, CINEMA_BLACK);

    // Apply gamma adjustment to compensate for dim surround
    float3 linearCV = darkSurround_to_dimSurround(rgbPost);

    // Apply desaturation to compensate for luminance difference
    //linearCV = mul(ODT_SAT_MAT, color);
    linearCV = lerp(dot(linearCV, AP1_RGB2Y).xxx, linearCV, ODT_SAT_FACTOR.xxx);

    // Convert to display primary encoding
    // Rendering space RGB to XYZ
    float3 XYZ = mul(AP1_2_XYZ_MAT, linearCV);

    // Apply CAT from ACES white point to assumed observer adapted white point
    XYZ = mul(D60_2_D65_CAT, XYZ);

    // CIE XYZ to display primaries
    linearCV = mul(XYZ_2_REC709_MAT, XYZ);

    return linearCV;

#endif
}

// RGBM encode/decode
static const float kRGBMRange = 8.0;

half4 EncodeRGBM(half3 color)
{
    color *= 1.0 / kRGBMRange;
    half m = max(max(color.x, color.y), max(color.z, 1e-5));
    m = ceil(m * 255) / 255;
    return half4(color / m, m);
}

half3 DecodeRGBM(half4 rgbm)
{
    return rgbm.xyz * rgbm.w * kRGBMRange;
}

#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (enable : 3205) // conversion of larger type to smaller
#endif

#endif // UNITY_COLOR_INCLUDED
