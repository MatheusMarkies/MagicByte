#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

float4 _Time;
float _Refract;

//TEXTURE2D(_Emission);
//SAMPLER(sampler_Emission);
//
//TEXTURE2D(_Normal);
//SAMPLER(sampler_Normal);
//
//TEXTURE2D(_NormalSecond);
//SAMPLER(sampler_NormalSecond);

TEXTURE2D(_RefractionMask);
SAMPLER(sampler_RefractionMask);

//TEXTURE2D(_BaseMap);
//SAMPLER(sampler_BaseMap);
//
//TEXTURE2D(_OcclusionMap);
//SAMPLER(sampler_OcclusionMap);
//
//TEXTURE2D(_SmoothnessMap);
//SAMPLER(sampler_SmoothnessMap);
//
//TEXTURE2D(_MetalMap);
//SAMPLER(sampler_MetalMap);
//
//UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
////UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
////UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
////UNITY_DEFINE_INSTANCED_PROP(float, _NormalStrength)
////UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
////UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
////UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
////UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
////
////UNITY_DEFINE_INSTANCED_PROP(float, _NormalDetailStrength)
float _DetailNormalUV;
//UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

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

float3 GetLightingGlass(Surface surfaceWS, BRDF brdf, GI gi) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;
	float fresnel = Fresnel(IORtoF0(surfaceWS.ior), surfaceWS.normal, surfaceWS.viewDirection);
	float3 color = lerp(gi.refract, IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular), fresnel);
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
	
Surface crystal = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);;


BRDF brdf = GetBRDF(crystal);
GI gi = GetGlassGI(GI_FRAGMENT_DATA(input), crystal, brdf, _IOR, _Refract);
Light light = GetDirectionalLightIndex(0);
finalColor = GetLightingGlass(crystal, brdf, gi) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor).a;

float4 EmissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.baseUV);
float4 Ecolor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
finalColor += (EmissionMap.r * Fresnel(IORtoF0(crystal.ior), crystal.normal, crystal.viewDirection))* IORtoF0(crystal.ior) * Ecolor.rgb + EmissionMap.r*Ecolor.rgb;

return float4(finalColor, 1);
}

#endif