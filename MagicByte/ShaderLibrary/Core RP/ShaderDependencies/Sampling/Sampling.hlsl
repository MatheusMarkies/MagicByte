#ifndef UNITY_MAGICBYTE_SAMPLING_INCLUDED
#define UNITY_MAGICBYTE_SAMPLING_INCLUDED

#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (disable : 3205) // conversion of larger type to smaller
#endif

//-----------------------------------------------------------------------------
// Sample generator
//-----------------------------------------------------------------------------

#include "../Sampling/Fibonacci.hlsl"
#include "../Sampling/Hammersley.hlsl"

//-----------------------------------------------------------------------------
// Coordinate system conversion
//-----------------------------------------------------------------------------

// Transforms the unit vector from the spherical to the Cartesian (right-handed, Z up) coordinate.
float3 SphericalToCartesian(float cosPhi, float sinPhi, float cosTheta)
{
    float sinTheta = SinFromCos(cosTheta);

    return float3(float2(cosPhi, sinPhi) * sinTheta, cosTheta);
}

float3 SphericalToCartesian(float phi, float cosTheta)
{
    float sinPhi, cosPhi;
    sincos(phi, sinPhi, cosPhi);

    return SphericalToCartesian(cosPhi, sinPhi, cosTheta);
}

// Converts Cartesian coordinates given in the right-handed coordinate system
// with Z pointing upwards (OpenGL style) to the coordinates in the left-handed
// coordinate system with Y pointing up and Z facing forward (DirectX style).
float3 TransformGLtoDX(float3 v)
{
    return v.xzy;
}

// Performs conversion from equiafloat map coordinates to Cartesian (DirectX cubemap) ones.
float3 ConvertEquiafloatToCubemap(float u, float v)
{
    float phi      = TWO_PI - TWO_PI * u;
    float cosTheta = 1.0 - 2.0 * v;

    return TransformGLtoDX(SphericalToCartesian(phi, cosTheta));
}

// Convert a texel position into normalized position [-1..1]x[-1..1]
float2 CubemapTexelToNVC(uint2 unPositionTXS, uint cubemapSize)
{
    return 2.0 * float2(unPositionTXS) / float(max(cubemapSize - 1, 1)) - 1.0;
}

// Map cubemap face to world vector basis
static const float3 CUBEMAP_FACE_BASIS_MAPPING[6][3] =
{
    //XPOS face
    {
        float3(0.0, 0.0, -1.0),
        float3(0.0, -1.0, 0.0),
        float3(1.0, 0.0, 0.0)
    },
    //XNEG face
    {
        float3(0.0, 0.0, 1.0),
        float3(0.0, -1.0, 0.0),
        float3(-1.0, 0.0, 0.0)
    },
    //YPOS face
    {
        float3(1.0, 0.0, 0.0),
        float3(0.0, 0.0, 1.0),
        float3(0.0, 1.0, 0.0)
    },
    //YNEG face
    {
        float3(1.0, 0.0, 0.0),
        float3(0.0, 0.0, -1.0),
        float3(0.0, -1.0, 0.0)
    },
    //ZPOS face
    {
        float3(1.0, 0.0, 0.0),
        float3(0.0, -1.0, 0.0),
        float3(0.0, 0.0, 1.0)
    },
    //ZNEG face
    {
        float3(-1.0, 0.0, 0.0),
        float3(0.0, -1.0, 0.0),
        float3(0.0, 0.0, -1.0)
    }
};

// Convert a normalized cubemap face position into a direction
float3 CubemapTexelToDirection(float2 positionNVC, uint faceId)
{
    float3 dir = CUBEMAP_FACE_BASIS_MAPPING[faceId][0] * positionNVC.x
               + CUBEMAP_FACE_BASIS_MAPPING[faceId][1] * positionNVC.y
               + CUBEMAP_FACE_BASIS_MAPPING[faceId][2];

    return normalize(dir);
}

//-----------------------------------------------------------------------------
// Sampling function
// Reference : http://www.cs.virginia.edu/~jdl/bib/globillum/mis/shirley96.pdf + PBRT
//-----------------------------------------------------------------------------

// Performs uniform sampling of the unit disk.
// Ref: PBRT v3, p. 777.
float2 SampleDiskUniform(float u1, float u2)
{
    float r   = sqrt(u1);
    float phi = TWO_PI * u2;

    float sinPhi, cosPhi;
    sincos(phi, sinPhi, cosPhi);

    return r * float2(cosPhi, sinPhi);
}

// Performs cubic sampling of the unit disk.
float2 SampleDiskCubic(float u1, float u2)
{
    float r   = u1;
    float phi = TWO_PI * u2;

    float sinPhi, cosPhi;
    sincos(phi, sinPhi, cosPhi);

    return r * float2(cosPhi, sinPhi);
}

float3 SampleConeUniform(float u1, float u2, float cos_theta)
{
    float r0 = cos_theta + u1 * (1.0f - cos_theta);
    float r = sqrt(max(0.0, 1.0 - r0 * r0));
    float phi = TWO_PI * u2;
    return float3(r * cos(phi), r * sin(phi), r0);
}

float3 SampleSphereUniform(float u1, float u2)
{
    float phi      = TWO_PI * u2;
    float cosTheta = 1.0 - 2.0 * u1;

    return SphericalToCartesian(phi, cosTheta);
}

// Performs cosine-weighted sampling of the hemisphere.
// Ref: PBRT v3, p. 780.
float3 SampleHemisphereCosine(float u1, float u2)
{
    float3 localL;

    // Since we don't floatly care about the area distortion,
    // we substitute uniform disk sampling for the concentric one.
    localL.xy = SampleDiskUniform(u1, u2);

    // Project the point from the disk onto the hemisphere.
    localL.z = sqrt(1.0 - u1);

    return localL;
}

// Cosine-weighted sampling without the tangent frame.
// Ref: http://www.amietia.com/lambertnotangent.html
float3 SampleHemisphereCosine(float u1, float u2, float3 normal)
{
    // This function needs to used safenormalize because there is a probability
    // that the generated direction is the exact opposite of the normal and that would lead
    // to a nan vector otheriwse.
    float3 pointOnSphere = SampleSphereUniform(u1, u2);
    return SafeNormalize(normal + pointOnSphere);
}

float3 SampleHemisphereUniform(float u1, float u2)
{
    float phi      = TWO_PI * u2;
    float cosTheta = 1.0 - u1;

    return SphericalToCartesian(phi, cosTheta);
}

void SampleSphere(float2   u,
                  float4x4 localToWorld,
                  float    radius,
              out float    lightPdf,
              out float3   P,
              out float3   Ns)
{
    float u1 = u.x;
    float u2 = u.y;

    Ns = SampleSphereUniform(u1, u2);

    // Transform from unit sphere to world space
    P = radius * Ns + localToWorld[3].xyz;

    // pdf is inverse of area
    lightPdf = 1.0 / (FOUR_PI * radius * radius);
}

void SampleHemisphere(float2   u,
                      float4x4 localToWorld,
                      float    radius,
                  out float    lightPdf,
                  out float3   P,
                  out float3   Ns)
{
    float u1 = u.x;
    float u2 = u.y;

    // Random point at hemisphere surface
    Ns = -SampleHemisphereUniform(u1, u2); // We want the y down hemisphere
    P = radius * Ns;

    // Transform to world space
    P = mul(float4(P, 1.0), localToWorld).xyz;
    Ns = mul(Ns, (float3x3)(localToWorld));

    // pdf is inverse of area
    lightPdf = 1.0 / (TWO_PI * radius * radius);
}

// Note: The cylinder has no end caps (i.e. no disk on the side)
void SampleCylinder(float2   u,
                    float4x4 localToWorld,
                    float    radius,
                    float    width,
                out float    lightPdf,
                out float3   P,
                out float3   Ns)
{
    float u1 = u.x;
    float u2 = u.y;

    // Random point at cylinder surface
    float t = (u1 - 0.5) * width;
    float theta = 2.0 * PI * u2;
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);

    // Cylinder are align on the right axis
    P = float3(t, radius * cosTheta, radius * sinTheta);
    Ns = normalize(float3(0.0, cosTheta, sinTheta));

    // Transform to world space
    P = mul(float4(P, 1.0), localToWorld).xyz;
    Ns = mul(Ns, (float3x3)(localToWorld));

    // pdf is inverse of area
    lightPdf = 1.0 / (TWO_PI * radius * width);
}

void SampleRectangle(float2   u,
                     float4x4 localToWorld,
                     float    width,
                     float    height,
                 out float    lightPdf,
                 out float3   P,
                 out float3   Ns)
{
    // Random point at rectangle surface
    P = float3((u.x - 0.5) * width, (u.y - 0.5) * height, 0);
    Ns = float3(0, 0, -1); // Light down (-Z)

    // Transform to world space
    P = mul(float4(P, 1.0), localToWorld).xyz;
    Ns = mul(Ns, (float3x3)(localToWorld));

    // pdf is inverse of area
    lightPdf = 1.0 / (width * height);
}

void SampleDisk(float2   u,
                float4x4 localToWorld,
                float    radius,
            out float    lightPdf,
            out float3   P,
            out float3   Ns)
{
    // Random point at disk surface
    P  = float3(radius * SampleDiskUniform(u.x, u.y), 0);
    Ns = float3(0.0, 0.0, -1.0); // Light down (-Z)

    // Transform to world space
    P = mul(float4(P, 1.0), localToWorld).xyz;
    Ns = mul(Ns, (float3x3)(localToWorld));

    // pdf is inverse of area
    lightPdf = 1.0 / (PI * radius * radius);
}

// Solid angle cone sampling.
// Takes the cosine of the aperture as an input.
void SampleCone(float2 u, float cosHalfAngle,
                out float3 dir, out float rcpPdf)
{
    float cosTheta = lerp(1, cosHalfAngle, u.x);
    float phi      = TWO_PI * u.y;

    dir    = SphericalToCartesian(phi, cosTheta);
    rcpPdf = TWO_PI * (1 - cosHalfAngle);
}

// Returns uniformly distributed sample vectors in a cone using
// "golden angle spiral method" described here: http://blog.marmakoide.org/?p=1
// note: the first sample is always [0, 0, 1]
float3 SampleConeStrata(uint sampleIdx, float rcpSampleCount, float cosHalfApexAngle)
{
    float z = 1.0f - ((1.0f - cosHalfApexAngle) * sampleIdx) * rcpSampleCount;
    float r = sqrt(1.0f - z * z);
    float a = sampleIdx * 2.3999632297286f; // pi*(3-sqrt(5))
    float sphi = sin(a);
    float cphi = cos(a);
    return float3(r * cphi, r * sphi, z);
}

#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (enable : 3205) // conversion of larger type to smaller
#endif

#endif // UNITY_SAMPLING_INCLUDED
