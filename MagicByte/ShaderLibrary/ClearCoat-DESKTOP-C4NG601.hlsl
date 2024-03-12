#ifndef CLEARCOAT_INCLUDED
#define CLEARCOAT_INCLUDED

#include "../ShaderLibrary/Simplex3D.hlsl"
#include "../ShaderLibrary/Common.hlsl"
#include "../../ShaderLibrary/Light.hlsl"

float3 ClearCoat(float clearCoatRoughness,Surface surface,GI gi, BRDF brdf){

float NoV = dot(surface.normal, surface.viewDirection);
float3 coatReflection = surface.normal * NoV - surface.viewDirection;

float3 envMap = gi.clearCoatReflect;
float envContribution = 1.0 - 0.5 * NoV;

float3 Color = float3(0,0,0);

ShadowData shadowData = GetShadowData(surface);
shadowData.shadowMask = gi.shadowMask;

for (int i = 0; i < GetDirectionalLightCount(); i++) {
	Light light = GetDirectionalLight(0, surface, shadowData);

	float3 h = SafeNormalize(light.direction + surface.viewDirection);

	float fresnel = FresnelBRDF(IORtoF0(surface.ior), dot(h, surface.viewDirection));
	float fresnelSqr = fresnel * fresnel;

	float3 paintColor = fresnel * (fresnelSqr + pow(fresnel, 16));

	Color += paintColor;
}

for (int j = 0; j < GetOtherLightCount(); j++) {
	Light light = GetOtherLight(j, surface, shadowData);

	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float fresnel = FresnelBRDF(IORtoF0(surface.ior), dot(h, surface.viewDirection));

	float fresnelSqr = fresnel * fresnel;

	float3 paintColor = fresnel * (fresnelSqr + pow(fresnel, 16));

	Color += paintColor;
}

return pow(Color, _Gamma) + (envMap * clearCoatRoughness * envContribution);
}

#endif