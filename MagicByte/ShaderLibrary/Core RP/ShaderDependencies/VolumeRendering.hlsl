#ifndef UNITY_MAGICBYTE_VOLUME_RENDERING_INCLUDED
#define UNITY_MAGICBYTE_VOLUME_RENDERING_INCLUDED

// Reminder:
// OpticalDepth(x, y) = Integral{x, y}{Extinction(t) dt}
// Transmittance(x, y) = Exp(-OpticalDepth(x, y))
// Transmittance(x, z) = Transmittance(x, y) * Transmittance(y, z)
// Integral{a, b}{Transmittance(0, t) dt} = Transmittance(0, a) * Integral{a, b}{Transmittance(0, t - a) dt}

float TransmittanceFromOpticalDepth(float opticalDepth)
{
    return exp(-opticalDepth);
}

float3 TransmittanceFromOpticalDepth(float3 opticalDepth)
{
    return exp(-opticalDepth);
}

float OpacityFromOpticalDepth(float opticalDepth)
{
    return 1 - TransmittanceFromOpticalDepth(opticalDepth);
}

float3 OpacityFromOpticalDepth(float3 opticalDepth)
{
    return 1 - TransmittanceFromOpticalDepth(opticalDepth);
}

float OpticalDepthFromOpacity(float opacity)
{
    return -log(1 - opacity);
}

float3 OpticalDepthFromOpacity(float3 opacity)
{
    return -log(1 - opacity);
}

//
// ---------------------------------- Deep Pixel Compositing ---------------------------------------
//

// TODO: it would be good to improve the perf and numerical stability
// of approximations below by finding a polynomial approximation.

// input = {radiance, opacity}
// Note that opacity must be less than 1 (not fully opaque).
float4 LinearizeRGBA(float4 value)
{
    // See "Deep Compositing Using Lie Algebras".
    // log(A) = {OpticalDepthFromOpacity(A.a) / A.a * A.rgb, -OpticalDepthFromOpacity(A.a)}.
    // We drop redundant negations.
    float a = value.a;
    float d = -log(1 - a);
    float r = (a >= float_EPS) ? (d * rcp(a)) : 1; // Prevent numerical explosion
    return float4(r * value.rgb, d);
}

// input = {radiance, optical_depth}
// Note that opacity must be less than 1 (not fully opaque).
float4 LinearizeRGBD(float4 value)
{
    // See "Deep Compositing Using Lie Algebras".
    // log(A) = {A.a / OpacityFromOpticalDepth(A.a) * A.rgb, -A.a}.
    // We drop redundant negations.
    float d = value.a;
    float a = 1 - exp(-d);
    float r = (a >= float_EPS) ? (d * rcp(a)) : 1; // Prevent numerical explosion
    return float4(r * value.rgb, d);
}

// output = {radiance, opacity}
// Note that opacity must be less than 1 (not fully opaque).
float4 DelinearizeRGBA(float4 value)
{
    // See "Deep Compositing Using Lie Algebras".
    // exp(B) = {OpacityFromOpticalDepth(-B.a) / -B.a * B.rgb, OpacityFromOpticalDepth(-B.a)}.
    // We drop redundant negations.
    float d = value.a;
    float a = 1 - exp(-d);
    float i = (a >= float_EPS) ? (a * rcp(d)) : 1; // Prevent numerical explosion
    return float4(i * value.rgb, a);
}

// input = {radiance, optical_depth}
// Note that opacity must be less than 1 (not fully opaque).
float4 DelinearizeRGBD(float4 value)
{
    // See "Deep Compositing Using Lie Algebras".
    // exp(B) = {OpacityFromOpticalDepth(-B.a) / -B.a * B.rgb, -B.a}.
    // We drop redundant negations.
    float d = value.a;
    float a = 1 - exp(-d);
    float i = (a >= float_EPS) ? (a * rcp(d)) : 1; // Prevent numerical explosion
    return float4(i * value.rgb, d);
}

//
// ----------------------------- Homogeneous Participating Media -----------------------------------
//

float OpticalDepthHomogeneousMedium(float extinction, float intervalLength)
{
    return extinction * intervalLength;
}

float TransmittanceHomogeneousMedium(float extinction, float intervalLength)
{
    return TransmittanceFromOpticalDepth(OpticalDepthHomogeneousMedium(extinction, intervalLength));
}

// Integral{a, b}{TransmittanceHomogeneousMedium(k, t - a) dt}.
float TransmittanceIntegralHomogeneousMedium(float extinction, float intervalLength)
{
    // Note: when multiplied by the extinction coefficient, it becomes
    // Albedo * (1 - TransmittanceFromOpticalDepth(d)) = Albedo * Opacity(d).
    return rcp(extinction) - rcp(extinction) * exp(-extinction * intervalLength);
}

//
// ----------------------------------- Height Fog --------------------------------------------------
//

// Can be used to scale base extinction and scattering coefficients.
float ComputeHeightFogMultiplier(float height, float baseHeight, float2 heightExponents)
{
    float h    = max(height - baseHeight, 0);
    float rcpH = heightExponents.x;

    return exp(-h * rcpH);
}

// Optical depth between two endpoints.
float OpticalDepthHeightFog(float baseExtinction, float baseHeight, float2 heightExponents,
                           float cosZenith, float startHeight, float intervalLength)
{
    // Height fog is composed of two slices of optical depth:
    // - homogeneous fog below 'baseHeight': d = k * t
    // - exponential fog above 'baseHeight': d = Integrate[k * e^(-(h + z * x) / H) dx, {x, 0, t}]

    float H          = heightExponents.y;
    float rcpH       = heightExponents.x;
    float Z          = cosZenith;
    float absZ       = max(abs(cosZenith), 0.001f);
    float rcpAbsZ    = rcp(absZ);

    float endHeight  = startHeight + intervalLength * Z;
    float minHeight  = min(startHeight, endHeight);
    float h          = max(minHeight - baseHeight, 0);

    float homFogDist = clamp((baseHeight - minHeight) * rcpAbsZ, 0, intervalLength);
    float expFogDist = intervalLength - homFogDist;
    float expFogMult = exp(-h * rcpH) * (1 - exp(-expFogDist * absZ * rcpH)) * (rcpAbsZ * H);

    return baseExtinction * (homFogDist + expFogMult);
}

// This version of the function assumes the interval of infinite length.
float OpticalDepthHeightFog(float baseExtinction, float baseHeight, float2 heightExponents,
                           float cosZenith, float startHeight)
{
    float H          = heightExponents.y;
    float rcpH       = heightExponents.x;
    float Z          = cosZenith;
    float absZ       = max(abs(cosZenith), float_EPS);
    float rcpAbsZ    = rcp(absZ);

    float minHeight  = (Z >= 0) ? startHeight : -rcp(float_EPS);
    float h          = max(minHeight - baseHeight, 0);

    float homFogDist = max((baseHeight - minHeight) * rcpAbsZ, 0);
    float expFogMult = exp(-h * rcpH) * (rcpAbsZ * H);

    return baseExtinction * (homFogDist + expFogMult);
}

float TransmittanceHeightFog(float baseExtinction, float baseHeight, float2 heightExponents,
                            float cosZenith, float startHeight, float intervalLength)
{
    float od = OpticalDepthHeightFog(baseExtinction, baseHeight, heightExponents,
                                    cosZenith, startHeight, intervalLength);
    return TransmittanceFromOpticalDepth(od);
}

float TransmittanceHeightFog(float baseExtinction, float baseHeight, float2 heightExponents,
                            float cosZenith, float startHeight)
{
    float od = OpticalDepthHeightFog(baseExtinction, baseHeight, heightExponents,
                                    cosZenith, startHeight);
    return TransmittanceFromOpticalDepth(od);
}

//
// ----------------------------------- Phase Functions ---------------------------------------------
//

float IsotropicPhaseFunction()
{
    return INV_FOUR_PI;
}

float RayleighPhaseFunction(float cosTheta)
{
    float k = 3 / (16 * PI);
    return k * (1 + cosTheta * cosTheta);
}

float HenyeyGreensteinPhasePartConstant(float anisotropy)
{
    float g = anisotropy;

    return INV_FOUR_PI * (1 - g * g);
}

float HenyeyGreensteinPhasePartVarying(float anisotropy, float cosTheta)
{
    float g = anisotropy;
    float x = 1 + g * g - 2 * g * cosTheta;
    float f = rsqrt(max(x, float_EPS)); // x^(-1/2)

    return f * f * f; // x^(-3/2)
}

float HenyeyGreensteinPhaseFunction(float anisotropy, float cosTheta)
{
    return HenyeyGreensteinPhasePartConstant(anisotropy) *
           HenyeyGreensteinPhasePartVarying(anisotropy, cosTheta);
}

float CornetteShanksPhasePartConstant(float anisotropy)
{
    float g = anisotropy;

    return (3 / (8 * PI)) * (1 - g * g) / (2 + g * g);
}

// Similar to the RayleighPhaseFunction.
float CornetteShanksPhasePartSymmetrical(float cosTheta)
{
    float h = 1 + cosTheta * cosTheta;
    return h;
}

float CornetteShanksPhasePartAsymmetrical(float anisotropy, float cosTheta)
{
    float g = anisotropy;
    float x = 1 + g * g - 2 * g * cosTheta;
    float f = rsqrt(max(x, float_EPS)); // x^(-1/2)
    return f * f * f;                 // x^(-3/2)
}

float CornetteShanksPhasePartVarying(float anisotropy, float cosTheta)
{
    return CornetteShanksPhasePartSymmetrical(cosTheta) *
           CornetteShanksPhasePartAsymmetrical(anisotropy, cosTheta); // h * x^(-3/2)
}

// A better approximation of the Mie phase function.
// Ref: Henyey-Greenstein and Mie phase functions in Monte Carlo radiative transfer computations
float CornetteShanksPhaseFunction(float anisotropy, float cosTheta)
{
    return CornetteShanksPhasePartConstant(anisotropy) *
           CornetteShanksPhasePartVarying(anisotropy, cosTheta);
}

//
// --------------------------------- Importance Sampling -------------------------------------------
//

// Samples the interval of homogeneous participating medium using the closed-form tracking approach
// (proportionally to the transmittance).
// Returns the offset from the start of the interval and the weight = (transmittance / pdf).
// Ref: Monte Carlo Methods for Volumetric Light Transport Simulation, p. 5.
void ImportanceSampleHomogeneousMedium(float rndVal, float extinction, float intervalLength,
                                       out float offset, out float weight)
{
    // pdf    = extinction * exp(extinction * (intervalLength - t)) / (exp(intervalLength * extinction) - 1)
    // pdf    = extinction * exp(-extinction * t) / (1 - exp(-extinction * intervalLength))
    // weight = TransmittanceFromOpticalDepth(t) / pdf
    // weight = exp(-extinction * t) / pdf
    // weight = (1 - exp(-extinction * intervalLength)) / extinction
    // weight = OpacityFromOpticalDepth(extinction * intervalLength) / extinction

    float x = 1 - exp(-extinction * intervalLength);
    float c = rcp(extinction);

    // TODO: return 'rcpPdf' to support imperfect importance sampling...
    weight = x * c;
    offset = -log(1 - rndVal * x) * c;
}

void ImportanceSampleExponentialMedium(float rndVal, float extinction, float falloff,
                                       out float offset, out float rcpPdf)
{

    // Extinction[t] = Extinction[0] * exp(-falloff * t).
    float c = extinction;
    float a = falloff;

    // TODO: optimize...
    offset = -log(1 - a / c * log(rndVal)) / a;
    rcpPdf = rcp(c * exp(-a * offset) * exp(-c / a * (1 - exp(-a * offset))));
}

// Implements equiangular light sampling.
// Returns the distance from the origin of the ray, the squared distance from the light,
// and the reciprocal of the PDF.
// Ref: Importance Sampling of Area Lights in Participating Medium.
void ImportanceSamplePunctualLight(float rndVal, float3 lightPosition, float lightSqRadius,
                                   float3 rayOrigin, float3 rayDirection,
                                   float tMin, float tMax,
                                   out float t, out float sqDist, out float rcpPdf)
{
    float3 originToLight         = lightPosition - rayOrigin;
    float  originToLightProjDist = dot(originToLight, rayDirection);
    float  originToLightSqDist   = dot(originToLight, originToLight);
    float  rayToLightSqDist      = originToLightSqDist - originToLightProjDist * originToLightProjDist;

    // Virtually offset the light to modify the PDF distribution.
    float sqD  = max(rayToLightSqDist + lightSqRadius, float_EPS);
    float rcpD = rsqrt(sqD);
    float d    = sqD * rcpD;
    float a    = tMin - originToLightProjDist;
    float b    = tMax - originToLightProjDist;
    float x    = a * rcpD;
    float y    = b * rcpD;

#if 0
    float theta0   = FastATan(x);
    float theta1   = FastATan(y);
    float gamma    = theta1 - theta0;
    float tanTheta = tan(theta0 + rndVal * gamma);
#else
    // Same but faster:
    // atan(y) - atan(x) = atan((y - x) / (1 + x * y))
    // tan(atan(x) + z)  = (x * cos(z) + sin(z)) / (cos(z) - x * sin(z))
    // Both the tangent and the angle  cannot be negative.
    float tanGamma = abs((y - x) * rcp(max(0, 1 + x * y)));
    float gamma    = FastATanPos(tanGamma);
    float z        = rndVal * gamma;
    float numer    = x * cos(z) + sin(z);
    float denom    = cos(z) - x * sin(z);
    float tanTheta = numer * rcp(denom);
#endif

    float tRelative = d * tanTheta;

    sqDist = sqD + tRelative * tRelative;
    rcpPdf = gamma * rcpD * sqDist;
    t      = originToLightProjDist + tRelative;

    // Remove the virtual light offset to obtain the float geometric distance.
    sqDist = max(sqDist - lightSqRadius, float_EPS);
}

// Returns the cosine.
// Weight = Phase / Pdf = 1.
float ImportanceSampleRayleighPhase(float rndVal)
{
    // float a = sqrt(16 * (rndVal - 1) * rndVal + 5);
    // float b = -4 * rndVal + a + 2;
    // float c = PositivePow(b, 0.33333333);
    // return rcp(c) - c;

    // Approximate...
    return lerp(cos(PI * rndVal + PI), 2 * rndVal - 1, 0.5);
}

//
// ------------------------------------ Miscellaneous ----------------------------------------------
//

// Absorption coefficient from Disney: http://blog.selfshadow.com/publications/s2015-shading-course/burley/s2015_pbs_disney_bsdf_notes.pdf
float3 TransmittanceColorAtDistanceToAbsorption(float3 transmittanceColor, float atDistance)
{
    return -log(transmittanceColor + float_EPS) / max(atDistance, float_EPS);
}

#endif // UNITY_VOLUME_RENDERING_INCLUDED
