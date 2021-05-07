#ifndef METALLIC_PASS_INCLUDED
#define METALLIC_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

float4 _Time;

TEXTURE2D(_AnisoTex);
SAMPLER(sampler_AnisoTex);

UNITY_DEFINE_INSTANCED_PROP(float, _UseAnisotropicNormal)
float _DetailNormalUV;
float _Anisotropic;

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 baseUV : TEXCOORD0;
	GI_ATTRIBUTE_DATA
		UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS : VAR_NORMAL;
	float4 tangentWS : VAR_TANGENT;
	float2 baseUV : VAR_BASE_UV;
	GI_VARYINGS_DATA
		UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex (Attributes input) {
UNITY_SETUP_INSTANCE_ID(input);
	Varyings output;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
	output.baseUV = input.baseUV;

	return output;
}

float3 GetLighting(Surface surface, BRDF brdf, Light light) {
	return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

float3 AnisoBRDF(Surface metal, Light light, BRDF brdf, float2 uv)
{
	float3 h = normalize(normalize(light.direction) + normalize(metal.viewDirection));
	float NoL = saturate(dot(metal.normal, light.direction));
	float NoV = saturate(dot(metal.normal, metal.viewDirection));
	float LoH = saturate(dot(light.direction, h));
	float HoA = dot(normalize(metal.normal + SAMPLE_TEXTURE2D(_AnisoTex, sampler_AnisoTex, uv).rgb), h);
	float aniso = max(0, sin(radians((HoA) * 180)));

	float spec = saturate(dot(metal.normal, h));
	spec = saturate(pow(lerp(spec, aniso, SAMPLE_TEXTURE2D(_AnisoTex, sampler_AnisoTex, uv).a), SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, uv).g * 128) * SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, uv).r);

	float3 energyCompensation = 1.0 + NoL * (1.0 / (1.1 - brdf.roughness) - 1.0);

	float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(metal.smoothness);
	float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

	float  energyBias = lerp(0, 0.7, roughness);
	float  energyFactor = lerp(1.0, 1.0 / 1.51, roughness);
	float  fd90 = energyBias + 1.0 * LoH * LoH * roughness;
	float f0 = 1.0f;
	float lightScatter = FresnelTransmissionBRDF(f0, fd90, NoL);
	float viewScatter = FresnelTransmissionBRDF(f0, fd90, NoV);
	return  lightScatter * viewScatter * energyFactor;

	return spec * energyCompensation + metal.color;
}

float3 GetLightingAniso(Surface surfaceWS, BRDF brdf, GI gi) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, light);
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, light);
	}

	return color;
}

float3 GetLighting(Surface surfaceWS, BRDF brdf, GI gi) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}

	return color;
}

float4 LitPassFragment(Varyings input) : SV_TARGET{
UNITY_SETUP_INSTANCE_ID(input);

float3 finalColor = (0, 0, 0);
	
Surface metal;

metal.position = input.positionWS;

float2 NormalUV = input.baseUV;
float2 NormalSecUV = input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalUV);

float4 Nmap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, NormalUV);
float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalStrength);
float3 normalMain = DecodeNormal(Nmap, scale);

float4 NmapSec = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, NormalSecUV);
float scaleSec = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalStrength);
float3 normalSec = DecodeNormal(NmapSec, scaleSec);

metal.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic) * pow(abs(SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, input.baseUV).r), 2.2);
metal.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness) * pow(abs(SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, input.baseUV).r), 2.2);

if (UseRoughness() == 0)
metal.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness) * pow(abs(SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, input.baseUV).r), 2.2);
else
metal.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness) * PerceptualRoughnessToPerceptualSmoothness(pow(abs(SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, input.baseUV).r), 2.2));

float3 normal = BlendNormalRNM(normalMain, normalSec);

metal.normal = NormalTangentToWorld(normal, input.normalWS, input.tangentWS);
metal.viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);

metal.fresnelStrength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Fresnel);
metal.color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV).rgb * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);

metal.interpolatedNormal = input.normalWS;

metal.depth = -TransformWorldToView(input.positionWS).z;
metal.tangent = input.tangentWS;
metal.binormal = cross(NormalTangentToWorld(normal, input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;

metal.anisotropic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Anisotropic);

float strength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Occlusion);
float occlusion = pow(abs(SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.baseUV).r), 2.2);
occlusion = lerp(occlusion, 1.0, 1 - strength);

metal.occlusion = occlusion;

metal.dither = 1;

Light light = GetDirectionalLightIndex(0);

BRDF brdf = GetBRDF(metal);
GI gi = GetGIAnistropic(GI_FRAGMENT_DATA(input), metal, brdf, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _clearCoatRoughness), metal.anisotropic);

if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _UseAnisotropicNormal) == 1) {
	finalColor = GetLightingAniso(metal, brdf, gi);
	finalColor *= AnisoBRDF(metal, light, brdf, input.baseUV);
}
else {
	finalColor = GetLighting(metal, brdf, gi);
}

float4 micro = float4(
	Sparkles(metal.viewDirection, metal.position, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAnim), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAmount) * 100, _Time)
	, Sparkles(metal.viewDirection, metal.position, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAnim), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAmount) * 100, _Time)
	, Sparkles(metal.viewDirection, metal.position, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAnim), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAmount) * 100, _Time), 1);
micro *= UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesColor);

if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _UseClearCoat) == 1)
finalColor += getSurfaceClearCoat(micro, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ClearCoat), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _clearCoatRoughness), metal, gi, light) * GetClearCoat();

float4 EmissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.baseUV);
float4 Ecolor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
finalColor += EmissionMap * Ecolor;
finalColor += Fresnel(metal.fresnelStrength, metal.normal, metal.viewDirection)* metal.fresnelStrength * metal.color;

return float4(finalColor, 1);
}

#endif