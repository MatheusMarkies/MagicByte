#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

TEXTURE2D(_RedMap);
SAMPLER(sampler_RedMap);

TEXTURE2D(_GreenMap);
SAMPLER(sampler_GreenMap);

TEXTURE2D(_BlueMap);
SAMPLER(sampler_BlueMap);

TEXTURE2D(_SmoothnessNormal);
SAMPLER(sampler_SmoothnessNormal);

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float4 color : COLOR;
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
	float4 color : COLOR;
	GI_VARYINGS_DATA
		UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex (Attributes input) {
	Varyings output;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);

	output.color = input.color;
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
	output.baseUV = TransformBaseUV(input.baseUV);
	output.detailUV = TransformDetailUV(input.baseUV);
	return output;
}

float2 _NormalSpeed = (-1.3, 0);
float2 _NormalSecondSpeed = (1,0);

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

float4 _Time;
float4 LitPassFragment (Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);

	float4 base = GetBase(input.baseUV, input.detailUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif

	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	float2 normalSpeed = _NormalSpeed.xy * _Time.y;
	float2 normalSecSpeed = _NormalSecondSpeed.xy * _Time.y;

	float2 NormalUV = input.baseUV * 10;
	NormalUV += normalSpeed.xy;

	float2 NormalSecUV = input.baseUV * 10;
	NormalSecUV += normalSecSpeed.xy;

	float4 Nmap = SAMPLE_TEXTURE2D(_SmoothnessNormal, sampler_SmoothnessNormal, NormalUV);
	float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, 0.7);
	float3 normalMain = DecodeNormal(Nmap, scale);

	float4 NmapSec = SAMPLE_TEXTURE2D(_SmoothnessNormal, sampler_SmoothnessNormal, NormalSecUV);
	float scaleSec = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, 0.7);
	float3 normalSec = DecodeNormal(NmapSec, scaleSec);

	float3 normal = BlendNormalRNM(normalMain, normalSec);

	Surface surface;
	surface.position = input.positionWS;
	surface.normal = NormalTangentToWorld(GetNormalTS(input.baseUV, input.detailUV), input.normalWS, input.tangentWS) + (normal * (1 - input.color.a));
	surface.interpolatedNormal = input.normalWS;
	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.depth = -TransformWorldToView(input.positionWS).z;
	surface.tangent = input.tangentWS;
	surface.binormal = cross(NormalTangentToWorld(GetNormalTS(input.baseUV, input.detailUV), input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;
	surface.color = lerp(SAMPLE_TEXTURE2D(_RedMap, sampler_RedMap, input.baseUV).rgb,base.rgb,input.color.r) + lerp(SAMPLE_TEXTURE2D(_GreenMap, sampler_GreenMap, input.baseUV).rgb, base.rgb, input.color.g)+ lerp(SAMPLE_TEXTURE2D(_BlueMap, sampler_BlueMap, input.baseUV).rgb, base.rgb, input.color.b);
	surface.alpha = base.a;

	surface.metallic = (1 - input.color.a)/2;
	surface.smoothness = (1 - input.color.a);

	surface.occlusion = GetOcclusion(input.baseUV);

	surface.fresnelStrength = 0;
	surface.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

	surface.anisotropic = 0;

	#if defined(_PREMULTIPLY_ALPHA)
		BRDF brdf = GetBRDF(surface, true);
	#else
		BRDF brdf = GetBRDF(surface);
	#endif
	GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf, GetClearCoatRoughness());
	Light light = GetDirectionalLightIndex(0);
	float3 color = GetLighting(surface, brdf,gi);///
	
	color += color*Fresnel(surface.fresnelStrength, surface.normal, surface.viewDirection);

	color += GetEmission(input.baseUV);

	return float4(color, surface.alpha);
}

#endif