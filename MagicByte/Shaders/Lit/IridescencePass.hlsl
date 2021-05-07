﻿#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"
#include "../../ShaderLibrary/Iridescence.hlsl"

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
	float2 detailUV : VAR_DETAIL_UV;
	GI_VARYINGS_DATA
		UNITY_VERTEX_INPUT_INSTANCE_ID
};

float _IridescenceThickness;
float _IridescenceTile;

Varyings LitPassVertex (Attributes input) {
	Varyings output;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
	output.baseUV = TransformBaseUV(input.baseUV);
	output.detailUV = TransformDetailUV(input.baseUV);
	return output;
}
float4 _Time;

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
	float fresnel = Fresnel(surfaceWS.fresnelStrength, surfaceWS.normal, surfaceWS.viewDirection);
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

float4 LitPassFragment (Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);

	float4 base = GetBase(input.baseUV, input.detailUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif

	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	Surface surface;
	surface.position = input.positionWS;
	surface.normal = NormalTangentToWorld(GetNormalTS(input.baseUV, input.detailUV), input.normalWS, input.tangentWS);
	surface.interpolatedNormal = input.normalWS;
	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.depth = -TransformWorldToView(input.positionWS).z;
	surface.tangent = input.tangentWS;
	surface.binormal = cross(NormalTangentToWorld(GetNormalTS(input.baseUV, input.detailUV), input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;
	surface.color = base.rgb;
	surface.alpha = base.a;

	surface.metallic = GetMetallic(input.baseUV);
	if(UseRoughness() == 0)
	surface.smoothness = GetSmoothness(input.baseUV);
	else
	surface.smoothness = PerceptualRoughnessToPerceptualSmoothness(GetSmoothness(input.baseUV));

	surface.occlusion = GetOcclusion(input.baseUV);

	surface.fresnelStrength = GetFresnel();
	surface.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

	surface.anisotropic = 0;// GetAnisotropicX();

	#if defined(_PREMULTIPLY_ALPHA)
		BRDF brdf = GetBRDF(surface, true);
	#else
		BRDF brdf = GetBRDF(surface);
	#endif
	GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf, GetClearCoatRoughness());
	Light light = GetDirectionalLightIndex(0);
	float3 color = GetLighting(surface, brdf, gi);
	
	color += color*Fresnel(surface.fresnelStrength, surface.normal, surface.viewDirection);

	color += GetEmission(input.baseUV);

	if (UseRefraction() == 1) {
		color += gi.refract;
	}
	/*if (UseRefraction() == 2) {
	BRDF brdf = GetBRDF(surface, true);
	}*/

	//float4 noiseTexture = SAMPLE_TEXTURE2D(_MicroFlakes, sampler_BaseMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile) + float2(sin(_Time.y * -UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed)), sin(_Time.y * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed))));
	//float4 noiseTexture2 = SAMPLE_TEXTURE2D(_MicroFlakes, sampler_BaseMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile) + float2(sin(_Time.y * -UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed)), sin(_Time.y * -UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed))));

	float4 micro = float4(Sparkles(surface.viewDirection, surface.position, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAnim), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAmount) * 100, _Time), Sparkles(surface.viewDirection, surface.position, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAnim), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAmount) * 100, _Time), Sparkles(surface.viewDirection, surface.position, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAnim), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesAmount) * 100, _Time),1);
	micro *= UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesColor);

	if (UseClearCoat() == 1) {
		color += getSurfaceClearCoat(micro, GetClearCoat(), GetClearCoatRoughness(), surface, gi, light) * GetClearCoat() + Iridescence(surface, light, _IridescenceTile) * _IridescenceThickness;
	}
	else
		color += Iridescence(surface, light, _IridescenceTile)* _IridescenceThickness;

	return float4(color, surface.alpha);
}

#endif