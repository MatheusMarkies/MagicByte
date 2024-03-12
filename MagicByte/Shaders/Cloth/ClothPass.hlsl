#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDFCloth.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

TEXTURE2D(_ScatteringMask);
SAMPLER(sampler_ScatteringMask);

float _Scattering;

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
float _DetailNormalTile;

//TEXTURE2D(_AlphaMap);
//SAMPLER(sampler_AlphaMap);

float3 GetLighting(Surface surface, BRDF brdf, Light light) {
	return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

float3 GetLighting(Surface surfaceWS, BRDF brdf, GI gi) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		float3 lightDir = light.direction + surfaceWS.normal;
		float3 translucency = (pow(saturate(dot(surfaceWS.viewDirection, -lightDir)), 1.25f) * 3 + gi.diffuse * 1) *light.attenuation * _Scattering; //* light.distanceAttenuation;
		// color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
		color += surfaceWS.color * light.color * translucency;
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		float3 lightDir = light.direction + surfaceWS.normal;
		float3 translucency = (pow(saturate(dot(surfaceWS.viewDirection, -lightDir)), 1.25f) * 3 + gi.diffuse * 1) *light.attenuation * _Scattering; //* light.distanceAttenuation;
		// color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
		color += surfaceWS.color * light.color * translucency;
	}

	return color;
}

float4 LitPassFragment (Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);

	Surface surface = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);

	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	#if defined(_PREMULTIPLY_ALPHA)
		BRDF brdf = GetBRDF(surface, true);
	#else
		BRDF brdf = GetBRDF(surface);
	#endif

	GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf);

	float3 color = (0, 0, 0);

	color = GetLighting(surface, brdf, gi);

	return float4(color, surface.alpha);
}

#endif