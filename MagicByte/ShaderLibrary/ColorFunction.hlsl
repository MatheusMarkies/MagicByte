#ifndef COLORFUNCTION_INCLUDED
#define COLORFUNCTION_INCLUDED

#include "../ShaderLibrary/Common.hlsl"

static const half3x3 LIN_2_LMS_MAT = {
3.90405e-1, 5.49941e-1, 8.92632e-3,
7.08416e-2, 9.63172e-1, 1.35775e-3,
2.31082e-2, 1.28021e-1, 9.36245e-1
};

static const half3x3 LMS_2_LIN_MAT = {
2.85847e+0, -1.62879e+0, -2.48910e-2,
-2.10182e-1,  1.15820e+0,  3.24281e-4,
-4.18120e-2, -1.18169e-1,  1.06867e+0
};

//https://www.alanzucconi.com/2017/07/15/improving-the-rainbow/
float3 ZucconiGradientFunction(float l)
{
	float r = 0.0, g = 0.0, b = 0.0;
	if ((l >= 400.0) && (l < 410.0)) {
		float t = (l - 400.0) / (410.0 - 400.0);
		r = +(0.33 * t) - (0.20 * t * t);
	}
	else if ((l >= 410.0) && (l < 475.0)) {
		float t = (l - 410.0) / (475.0 - 410.0);
		r = 0.14 - (0.13 * t * t);
	}
	else if ((l >= 545.0) && (l < 595.0)) {
		float t = (l - 545.0) / (595.0 - 545.0);
		r = +(1.98 * t) - (t * t);
	}
	else if ((l >= 595.0) && (l < 650.0)) {
		float t = (l - 595.0) / (650.0 - 595.0);
		r = 0.98 + (0.06 * t) - (0.40 * t * t);
	}
	else if ((l >= 650.0) && (l < 700.0)) {
		float t = (l - 650.0) / (700.0 - 650.0);
		r = 0.65 - (0.84 * t) + (0.20 * t * t);
	}
	if ((l >= 415.0) && (l < 475.0)) {
		float t = (l - 415.0) / (475.0 - 415.0);
		g = +(0.80 * t * t);
	}
	else if ((l >= 475.0) && (l < 590.0)) {
		float t = (l - 475.0) / (590.0 - 475.0);
		g = 0.8 + (0.76 * t) - (0.80 * t * t);
	}
	else if ((l >= 585.0) && (l < 639.0)) {
		float t = (l - 585.0) / (639.0 - 585.0);
		g = 0.82 - (0.80 * t);
	}
	if ((l >= 400.0) && (l < 475.0)) {
		float t = (l - 400.0) / (475.0 - 400.0);
		b = +(2.20 * t) - (1.50 * t * t);
	}
	else if ((l >= 475.0) && (l < 560.0)) {
		float t = (l - 475.0) / (560.0 - 475.0);
		b = 0.7 - (t)+(0.30 * t * t);
	}

	return float3(r, g, b);
}

float3 RodriguesRotation(float3 t, float3 u) {

	float3 coss = cos(t);
	float3 sen = sin(t);

	float3 Uc = cross(u, normalize(float3(1, 1, 1)));
	float3 Ud = dot(u, normalize(float3(1, 1, 1)));

	return (u * Ud * (coss * -1)) + (sen * Uc) + (u * coss);

}

half3 RGBtoHSV(half3 c)
{
    half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
    half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));
    half d = q.x - min(q.w, q.y);
    half e = 1.0e-4;
    return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

half3 HSVtoRGB(half3 c)
{
    half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

inline half gmod(half x, half y)
{
    return x - y * floor(x / y);
}

half3 ToCIE(half3 color)
{
    // http://www.w3.org/Graphics/Color/sRGB
    half3x3 RGB2XYZ = { 0.5141364, 0.3238786, 0.16036376, 0.265068, 0.67023428, 0.06409157, 0.0241188, 0.1228178, 0.84442666 };
    half3 XYZ = mul(RGB2XYZ, color.rgb);

    // XYZ -> Yxy conversion
    half3 Yxy;
    Yxy.r = XYZ.g;
    half temp = dot(half3(1.0, 1.0, 1.0), XYZ.rgb);
    Yxy.gb = XYZ.rg / temp;
    return Yxy;
}

half3 FromCIE(half3 Yxy)
{
    // Yxy -> XYZ conversion
    half3 XYZ;
    XYZ.r = Yxy.r * Yxy.g / Yxy.b;
    XYZ.g = Yxy.r;

    XYZ.b = Yxy.r * (1 - Yxy.g - Yxy.b) / Yxy.b;

    half3x3 XYZ2RGB = { 2.5651, -1.1665, -0.3986, -1.0217, 1.9777, 0.0439, 0.0753, -0.2543, 1.1892 };
    return mul(XYZ2RGB, XYZ);
}

#endif