#ifndef UNITY_MAGICBYTE_COMMON_LIGHTING_INCLUDED
#define UNITY_MAGICBYTE_COMMON_LIGHTING_INCLUDED

#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (disable : 3205) // conversion of larger type to smaller
#endif

// Ligthing convention
// Light direction is oriented backward (-Z). i.e in shader code, light direction is -lightData.forward

//-----------------------------------------------------------------------------
// Helper functions
//-----------------------------------------------------------------------------

// Performs the mapping of the vector 'v' centered within the axis-aligned cube
// of dimensions [-1, 1]^3 to a vector centered within the unit sphere.
// The function expects 'v' to be within the cube (possibly unexpected results otherwise).
// Ref: http://mathproofs.blogspot.com/2005/07/mapping-cube-to-sphere.html
float3 MapCubeToSphere(float3 v)
{
    float3 v2 = v * v;
    float2 vr3 = v2.xy * rcp(3.0);
    return v * sqrt((float3)1.0 - 0.5 * v2.yzx - 0.5 * v2.zxy + vr3.yxx * v2.zzy);
}

// Computes the squared magnitude of the vector computed by MapCubeToSphere().
float ComputeCubeToSphereMapSqMagnitude(float3 v)
{
    float3 v2 = v * v;
    // Note: dot(v, v) is often computed before this function is called,
    // so the compiler should optimize and use the precomputed result here.
    return dot(v, v) - v2.x * v2.y - v2.y * v2.z - v2.z * v2.x + v2.x * v2.y * v2.z;
}

// texelArea = 4.0 / (resolution * resolution).
// Ref: http://bpeers.com/blog/?itemid=1017
// This version is less accurate, but much faster than this one:
// http://www.rorydriscoll.com/2012/01/15/cubemap-texel-solid-angle/
float ComputeCubemapTexelSolidAngle(float3 L, float texelArea)
{
    // Stretch 'L' by (1/d) so that it points at a side of a [-1, 1]^2 cube.
    float d = Max3(abs(L.x), abs(L.y), abs(L.z));
    // Since 'L' is a unit vector, we can directly compute its
    // new (inverse) length without dividing 'L' by 'd' first.
    float invDist = d;

    // dw = dA * cosTheta / (dist * dist), cosTheta = 1.0 / dist,
    // where 'dA' is the area of the cube map texel.
    return texelArea * invDist * invDist * invDist;
}

// Only makes sense for Monte-Carlo integration.
// Normalize by dividing by the total weight (or the number of samples) in the end.
// Integrate[6*(u^2+v^2+1)^(-3/2), {u,-1,1},{v,-1,1}] = 4 * Pi
// Ref: "Stupid Spherical Harmonics Tricks", p. 9.
float ComputeCubemapTexelSolidAngle(float2 uv)
{
    float u = uv.x, v = uv.y;
    return pow(1 + u * u + v * v, -1.5);
}

float ConvertEvToLuminance(float ev)
{
    return exp2(ev - 3.0);
}

float ConvertLuminanceToEv(float luminance)
{
    float k = 12.5f;

    return log2((luminance * 100.0) / k);
}

//-----------------------------------------------------------------------------
// Attenuation functions
//-----------------------------------------------------------------------------

// Ref: Moving Frostbite to PBR.

// Non physically based hack to limit light influence to attenuationRadius.
// Square the result to smoothen the function.
float DistanceWindowing(float distSquare, float rangeAttenuationScale, float rangeAttenuationBias)
{
    // If (range attenuation is enabled)
    //   rangeAttenuationScale = 1 / r^2
    //   rangeAttenuationBias  = 1
    // Else
    //   rangeAttenuationScale = 2^12 / r^2
    //   rangeAttenuationBias  = 2^24
    return saturate(rangeAttenuationBias - Sq(distSquare * rangeAttenuationScale));
}

float SmoothDistanceWindowing(float distSquare, float rangeAttenuationScale, float rangeAttenuationBias)
{
    float factor = DistanceWindowing(distSquare, rangeAttenuationScale, rangeAttenuationBias);
    return Sq(factor);
}

#define PUNCTUAL_LIGHT_THRESHOLD 0.01 // 1cm (in Unity 1 is 1m)

// Return physically based quadratic attenuation + influence limit to reach 0 at attenuationRadius
float SmoothWindowedDistanceAttenuation(float distSquare, float distRcp, float rangeAttenuationScale, float rangeAttenuationBias)
{
    float attenuation = min(distRcp, 1.0 / PUNCTUAL_LIGHT_THRESHOLD);
    attenuation *= DistanceWindowing(distSquare, rangeAttenuationScale, rangeAttenuationBias);

    // Effectively results in (distRcp)^2 * SmoothDistanceWindowing(...).
    return Sq(attenuation);
}

// Square the result to smoothen the function.
float AngleAttenuation(float cosFwd, float lightAngleScale, float lightAngleOffset)
{
    return saturate(cosFwd * lightAngleScale + lightAngleOffset);
}

float SmoothAngleAttenuation(float cosFwd, float lightAngleScale, float lightAngleOffset)
{
    float attenuation = AngleAttenuation(cosFwd, lightAngleScale, lightAngleOffset);
    return Sq(attenuation);
}

// Combines SmoothWindowedDistanceAttenuation() and SmoothAngleAttenuation() in an efficient manner.
// distances = {d, d^2, 1/d, d_proj}, where d_proj = dot(lightToSample, lightData.forward).
float PunctualLightAttenuation(float4 distances, float rangeAttenuationScale, float rangeAttenuationBias,
                              float lightAngleScale, float lightAngleOffset)
{
    float distSq   = distances.y;
    float distRcp  = distances.z;
    float distProj = distances.w;
    float cosFwd   = distProj * distRcp;

    float attenuation = min(distRcp, 1.0 / PUNCTUAL_LIGHT_THRESHOLD);
    attenuation *= DistanceWindowing(distSq, rangeAttenuationScale, rangeAttenuationBias);
    attenuation *= AngleAttenuation(cosFwd, lightAngleScale, lightAngleOffset);

    // Effectively results in SmoothWindowedDistanceAttenuation(...) * SmoothAngleAttenuation(...).
    return Sq(attenuation);
}

// Applies SmoothDistanceWindowing() after transforming the attenuation ellipsoid into a sphere.
// If r = rsqrt(invSqRadius), then the ellipsoid is defined s.t. r1 = r / invAspectRatio, r2 = r3 = r.
// The transformation is performed along the major axis of the ellipsoid (corresponding to 'r1').
// Both the ellipsoid (e.i. 'axis') and 'unL' should be in the same coordinate system.
// 'unL' should be computed from the center of the ellipsoid.
float EllipsoidalDistanceAttenuation(float3 unL, float3 axis, float invAspectRatio,
                                    float rangeAttenuationScale, float rangeAttenuationBias)
{
    // Project the unnormalized light vector onto the axis.
    float projL = dot(unL, axis);

    // Transform the light vector so that we can work with
    // with the ellipsoid as if it was a sphere with the radius of light's range.
    float diff = projL - projL * invAspectRatio;
    unL -= diff * axis;

    float sqDist = dot(unL, unL);
    return SmoothDistanceWindowing(sqDist, rangeAttenuationScale, rangeAttenuationBias);
}

// Applies SmoothDistanceWindowing() using the axis-aligned ellipsoid of the given dimensions.
// Both the ellipsoid and 'unL' should be in the same coordinate system.
// 'unL' should be computed from the center of the ellipsoid.
float EllipsoidalDistanceAttenuation(float3 unL, float3 invHalfDim,
                                    float rangeAttenuationScale, float rangeAttenuationBias)
{
    // Transform the light vector so that we can work with
    // with the ellipsoid as if it was a unit sphere.
    unL *= invHalfDim;

    float sqDist = dot(unL, unL);
    return SmoothDistanceWindowing(sqDist, rangeAttenuationScale, rangeAttenuationBias);
}

// Applies SmoothDistanceWindowing() after mapping the axis-aligned box to a sphere.
// If the diagonal of the box is 'd', invHalfDim = rcp(0.5 * d).
// Both the box and 'unL' should be in the same coordinate system.
// 'unL' should be computed from the center of the box.
float BoxDistanceAttenuation(float3 unL, float3 invHalfDim,
                            float rangeAttenuationScale, float rangeAttenuationBias)
{
    float attenuation = 0.0;

    // Transform the light vector so that we can work with
    // with the box as if it was a [-1, 1]^2 cube.
    unL *= invHalfDim;

    // Our algorithm expects the input vector to be within the cube.
    if (!(Max3(abs(unL.x), abs(unL.y), abs(unL.z)) > 1.0))
    {
        float sqDist = ComputeCubeToSphereMapSqMagnitude(unL);
        attenuation = SmoothDistanceWindowing(sqDist, rangeAttenuationScale, rangeAttenuationBias);
    }
    return attenuation;
}

//-----------------------------------------------------------------------------
// IES Helper
//-----------------------------------------------------------------------------

float2 GetIESTextureCoordinate(float3x3 lightToWord, float3 L)
{
    // IES need to be sample in light space
    float3 dir = mul(lightToWord, -L); // Using matrix on left side do a transpose

    // convert to spherical coordinate
    float2 sphericalCoord; // .x is theta, .y is phi
    // Texture is encoded with cos(phi), scale from -1..1 to 0..1
    sphericalCoord.y = (dir.z * 0.5) + 0.5;
    float theta = atan2(dir.y, dir.x);
    sphericalCoord.x = theta * INV_TWO_PI;

    return sphericalCoord;
}

//-----------------------------------------------------------------------------
// Lighting functions
//-----------------------------------------------------------------------------

// Ref: Horizon Occlusion for Normal Mapped Reflections: http://marmosetco.tumblr.com/post/81245981087
float GetHorizonOcclusion(float3 V, float3 normalWS, float3 vertexNormal, float horizonFade)
{
    float3 R = reflect(-V, normalWS);
    float specularOcclusion = saturate(1.0 + horizonFade * dot(R, vertexNormal));
    // smooth it
    return specularOcclusion * specularOcclusion;
}

// Ref: Moving Frostbite to PBR - Gotanda siggraph 2011
// Return specular occlusion based on ambient occlusion (usually get from SSAO) and view/roughness info
float GetSpecularOcclusionFromAmbientOcclusion(float NdotV, float ambientOcclusion, float roughness)
{
    return saturate(PositivePow(NdotV + ambientOcclusion, exp2(-16.0 * roughness - 1.0)) - 1.0 + ambientOcclusion);
}

// ref: Practical floattime Strategies for Accurate Indirect Occlusion
// Update ambient occlusion to colored ambient occlusion based on statitics of how light is bouncing in an object and with the albedo of the object
float3 GTAOMultiBounce(float visibility, float3 albedo)
{
    float3 a =  2.0404 * albedo - 0.3324;
    float3 b = -4.7951 * albedo + 0.6417;
    float3 c =  2.7552 * albedo + 0.6903;

    float x = visibility;
    return max(x, ((x * a + b) * x + c) * x);
}

// Based on Oat and Sander's 2007 technique
// Area/solidAngle of intersection of two cone
float SphericalCapIntersectionSolidArea(float cosC1, float cosC2, float cosB)
{
    float r1 = FastACos(cosC1);
    float r2 = FastACos(cosC2);
    float rd = FastACos(cosB);
    float area = 0.0;

    if (rd <= max(r1, r2) - min(r1, r2))
    {
        // One cap is completely inside the other
        area = TWO_PI - TWO_PI * max(cosC1, cosC2);
    }
    else if (rd >= r1 + r2)
    {
        // No intersection exists
        area = 0.0;
    }
    else
    {
        float diff = abs(r1 - r2);
        float den = r1 + r2 - diff;
        float x = 1.0 - saturate((rd - diff) / max(den, 0.0001));
        area = smoothstep(0.0, 1.0, x);
        area *= TWO_PI - TWO_PI * max(cosC1, cosC2);
    }

    return area;
}

// ref: Practical floattime Strategies for Accurate Indirect Occlusion
// http://blog.selfshadow.com/publications/s2016-shading-course/#course_content
// Original Cone-Cone method with cosine weighted assumption (p129 s2016_pbs_activision_occlusion)
float GetSpecularOcclusionFromBentAO_ConeCone(float3 V, float3 bentNormalWS, float3 normalWS, float ambientOcclusion, float roughness)
{
    // Retrieve cone angle
    // Ambient occlusion is cosine weighted, thus use following equation. See slide 129
    float cosAv = sqrt(1.0 - ambientOcclusion);
    roughness = max(roughness, 0.01); // Clamp to 0.01 to avoid edge cases
    float cosAs = exp2((-log(10.0) / log(2.0)) * Sq(roughness));
    float cosB = dot(bentNormalWS, reflect(-V, normalWS));
    return SphericalCapIntersectionSolidArea(cosAv, cosAs, cosB) / (TWO_PI * (1.0 - cosAs));
}

float GetSpecularOcclusionFromBentAO(float3 V, float3 bentNormalWS, float3 normalWS, float ambientOcclusion, float roughness)
{
    // Pseudo code:
    //SphericalGaussian NDF = WarpedGGXDistribution(normalWS, roughness, V);
    //SphericalGaussian Visibility = VisibilityConeSG(bentNormalWS, ambientOcclusion);
    //SphericalGaussian UpperHemisphere = UpperHemisphereSG(normalWS);
    //return saturate( InnerProduct(NDF, Visibility) / InnerProduct(NDF, UpperHemisphere) );

    // 1. Approximate visibility cone with a spherical gaussian of amplitude A=1
    // For a cone angle X, we can determine sharpness so that all point inside the cone have a value > Y
    // sharpness = (log(Y) - log(A)) / (cos(X) - 1)
    // For AO cone, cos(X) = sqrt(1 - ambientOcclusion)
    // -> for Y = 0.1, sharpness = -1.0 / (sqrt(1-ao) - 1)
    float vs = -1.0f / min(sqrt(1.0f - ambientOcclusion) - 1.0f, -0.001f);

    // 2. Approximate upper hemisphere with sharpness = 0.8 and amplitude = 1
    float us = 0.8f;

    // 3. Compute warped SG Axis of GGX distribution
    // Ref: All-Frequency Rendering of Dynamic, Spatially-Varying Reflectance
    // https://www.microsoft.com/en-us/research/wp-content/uploads/2009/12/sg.pdf
    float NoV = dot(V, normalWS);
    float3 NDFAxis = (2 * NoV * normalWS - V) * (0.5f / max(roughness * roughness * NoV, 0.001f));

    float umLength1 = length(NDFAxis + vs * bentNormalWS);
    float umLength2 = length(NDFAxis + us * normalWS);
    float d1 = 1 - exp(-2 * umLength1);
    float d2 = 1 - exp(-2 * umLength2);

    float expFactor1 = exp(umLength1 - umLength2 + us - vs);

    return saturate(expFactor1 * (d1 * umLength2) / (d2 * umLength1));
}

// Ref: Steve McAuley - Energy-Conserving Wrapped Diffuse
float ComputeWrappedDiffuseLighting(float NdotL, float w)
{
    return saturate((NdotL + w) / ((1.0 + w) * (1.0 + w)));
}

// Jimenez variant for eye
float ComputeWrappedPowerDiffuseLighting(float NdotL, float w, float p)
{
    return pow(saturate((NdotL + w) / (1.0 + w)), p) * (p + 1) / (w * 2.0 + 2.0);
}

// Ref: The Technical Art of Uncharted 4 - Brinck and Maximov 2016
float ComputeMicroShadowing(float AO, float NdotL, float opacity)
{
    float aperture = 2.0 * AO * AO;
    float microshadow = saturate(NdotL + aperture - 1.0);
    return lerp(1.0, microshadow, opacity);
}

float3 ComputeShadowColor(float shadow, float3 shadowTint, float penumbraFlag)
{
    // The origin expression is
    // lerp(float3(1.0, 1.0, 1.0) - ((1.0 - shadow) * (float3(1.0, 1.0, 1.0) - shadowTint))
    //            , shadow * lerp(shadowTint, lerp(shadowTint, float3(1.0, 1.0, 1.0), shadow), shadow)
    //            , penumbraFlag);
    // it has been simplified to this
    float3 invTint = float3(1.0, 1.0, 1.0) - shadowTint;
    float shadow3 = shadow * shadow * shadow;
    return lerp(float3(1.0, 1.0, 1.0) - ((1.0 - shadow) * invTint)
                , shadow3 * invTint + shadow * shadowTint,
                penumbraFlag);

}

// This is the same method as the one above. Simply the shadow is a float3 to support colored shadows.
float3 ComputeShadowColor(float3 shadow, float3 shadowTint, float penumbraFlag)
{
    // The origin expression is
    // lerp(float3(1.0, 1.0, 1.0) - ((1.0 - shadow) * (float3(1.0, 1.0, 1.0) - shadowTint))
    //            , shadow * lerp(shadowTint, lerp(shadowTint, float3(1.0, 1.0, 1.0), shadow), shadow)
    //            , penumbraFlag);
    // it has been simplified to this
    float3 invTint = float3(1.0, 1.0, 1.0) - shadowTint;
    float3 shadow3 = shadow * shadow * shadow;
    return lerp(float3(1.0, 1.0, 1.0) - ((1.0 - shadow) * invTint)
                , shadow3 * invTint + shadow * shadowTint,
                penumbraFlag);

}

//-----------------------------------------------------------------------------
// Helper functions
//--------------------------------------------------------------------------- --

// Ref: "Crafting a Next-Gen Material Pipeline for The Order: 1886".
float ClampNdotV(float NdotV)
{
    return max(NdotV, 0.0001); // Approximately 0.0057 degree bias
}

// Helper function to return a set of common angle used when evaluating BSDF
// NdotL and NdotV are unclamped
void GetBSDFAngle(float3 V, float3 L, float NdotL, float NdotV,
                  out float LdotV, out float NdotH, out float LdotH, out float invLenLV)
{
    // Optimized math. Ref: PBR Diffuse Lighting for GGX + Smith Microsurfaces (slide 114), assuming |L|=1 and |V|=1
    LdotV = dot(L, V);
    invLenLV = rsqrt(max(2.0 * LdotV + 2.0, FLT_EPS));    // invLenLV = rcp(length(L + V)), clamp to avoid rsqrt(0) = inf, inf * 0 = NaN
    NdotH = saturate((NdotL + NdotV) * invLenLV);
    LdotH = saturate(invLenLV * LdotV + invLenLV);
}

// Inputs:    normalized normal and view vectors.
// Outputs:   front-facing normal, and the new non-negative value of the cosine of the view angle.
// Important: call Orthonormalize() on the tangent and recompute the bitangent afterwards.
float3 GetViewReflectedNormal(float3 N, float3 V, out float NdotV)
{
    // Fragments of front-facing geometry can have back-facing normals due to interpolation,
    // normal mapping and decals. This can cause visible artifacts from both direct (negative or
    // extremely high values) and indirect (incorrect lookup direction) lighting.
    // There are several ways to avoid this problem. To list a few:
    //
    // 1. Setting { NdotV = max(<N,V>, SMALL_VALUE) }. This effectively removes normal mapping
    // from the affected fragments, making the surface appear flat.
    //
    // 2. Setting { NdotV = abs(<N,V>) }. This effectively reverses the convexity of the surface.
    // It also reduces light leaking from non-shadow-casting lights. Note that 'NdotV' can still
    // be 0 in this case.
    //
    // It's important to understand that simply changing the value of the cosine is insufficient.
    // For one, it does not solve the incorrect lookup direction problem, since the normal itself
    // is not modified. There is a more insidious issue, however. 'NdotV' is a constituent element
    // of the mathematical system describing the relationships between different vectors - and
    // not just normal and view vectors, but also light vectors, half vectors, tangent vectors, etc.
    // Changing only one angle (or its cosine) leaves the system in an inconsistent state, where
    // certain relationships can take on different values depending on whether 'NdotV' is used
    // in the calculation or not. Therefore, it is important to change the normal (or another
    // vector) in order to leave the system in a consistent state.
    //
    // We choose to follow the conceptual approach (2) by reflecting the normal around the
    // (<N,V> = 0) boundary if necessary, as it allows us to preserve some normal mapping details.

    NdotV = dot(N, V);

    // N = (NdotV >= 0.0) ? N : (N - 2.0 * NdotV * V);
    N += (2.0 * saturate(-NdotV)) * V;
    NdotV = abs(NdotV);

    return N;
}

// Generates an orthonormal (row-major) basis from a unit vector. TODO: make it column-major.
// The resulting rotation matrix has the determinant of +1.
// Ref: 'ortho_basis_pixar_r2' from http://marc-b-reynolds.github.io/quaternions/2016/07/06/Orthonormal.html
float3x3 GetLocalFrame(float3 localZ)
{
    float x  = localZ.x;
    float y  = localZ.y;
    float z  = localZ.z;
    float sz = FastSign(z);
    float a  = 1 / (sz + z);
    float ya = y * a;
    float b  = x * ya;
    float c  = x * sz;

    float3 localX = float3(c * x * a - 1, sz * b, c);
    float3 localY = float3(b, y * ya - sz, y);

    // Note: due to the quaternion formulation, the generated frame is rotated by 180 degrees,
    // s.t. if localZ = {0, 0, 1}, then localX = {-1, 0, 0} and localY = {0, -1, 0}.
    return float3x3(localX, localY, localZ);
}

// Generates an orthonormal (row-major) basis from a unit vector. TODO: make it column-major.
// The resulting rotation matrix has the determinant of +1.
float3x3 GetLocalFrame(float3 localZ, float3 localX)
{
    float3 localY = cross(localZ, localX);

    return float3x3(localX, localY, localZ);
}

// Construct a right-handed view-dependent orthogonal basis around the normal:
// b0-b2 is the view-normal aka reflection plane.
float3x3 GetOrthoBasisViewNormal(float3 V, float3 N, float unclampedNdotV, bool testSingularity = false)
{
    float3x3 orthoBasisViewNormal;
    if (testSingularity && (abs(1.0 - unclampedNdotV) <= FLT_EPS))
    {
        // In this case N == V, and azimuth orientation around N shouldn't matter for the caller,
        // we can use any quaternion-based method, like Frisvad or Reynold's (Pixar):
        orthoBasisViewNormal = GetLocalFrame(N);
    }
    else
    {
        orthoBasisViewNormal[0] = normalize(V - N * unclampedNdotV);
        orthoBasisViewNormal[2] = N;
        orthoBasisViewNormal[1] = cross(orthoBasisViewNormal[2], orthoBasisViewNormal[0]);
    }
    return orthoBasisViewNormal;
}

// Move this here since it's used by both LightLoop.hlsl and RaytracingLightLoop.hlsl
bool IsMatchingLightLayer(uint lightLayers, uint renderingLayers)
{
    return (lightLayers & renderingLayers) != 0;
}

#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (enable : 3205) // conversion of larger type to smaller
#endif

#endif // UNITY_COMMON_LIGHTING_INCLUDED
