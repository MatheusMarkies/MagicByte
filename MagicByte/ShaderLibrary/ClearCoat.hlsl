#ifndef CLEARCOAT_INCLUDED
#define CLEARCOAT_INCLUDED
#include "../ShaderLibrary/Simplex3D.hlsl"
#include "../ShaderLibrary/Common.hlsl"

float3 ClearCoat(float clearCoatRoughness,Surface surface,GI gi,Light light, BRDF brdf){

float NoV = dot(surface.normal, surface.viewDirection);
float3 coatReflection = 2 * surface.normal * NoV - surface.viewDirection;

float3 h = SafeNormalize(light.direction + surface.viewDirection);
float LoV = dot(light.direction, surface.viewDirection);
float f90 = 0.5 + (brdf.perceptualRoughness + brdf.perceptualRoughness * LoV);

float3 envMap = gi.reflect;
float fresnel = FresnelBRDF(IORtoF0(surface.ior), dot(h, surface.viewDirection));

float fresnelSqr = fresnel * fresnel;

float3 paintColor = fresnel * (fresnelSqr + pow(fresnel, 16));

float envContribution = 1.0 - 0.5 * NoV;

return (envMap * clearCoatRoughness * envContribution) + paintColor;
}

#endif