#ifndef SCATTERING_PASS_INCLUDED
#define SCATTERING_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

float4 _Time;

//TEXTURE2D(_BaseMap);
//SAMPLER(sampler_BaseMap);
//
//TEXTURE2D(_Normal);
//SAMPLER(sampler_Normal);
//
TEXTURE2D(_ScatteringMask);
SAMPLER(sampler_ScatteringMask);
//
//TEXTURE2D(_NormalSecond);
//SAMPLER(sampler_NormalSecond);
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
//UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)

float _ScatteringMode;
float _ScatteringAmplitude;
float _ScatteringScale;
//
//UNITY_DEFINE_INSTANCED_PROP(float, _NormalStrength)
//UNITY_DEFINE_INSTANCED_PROP(float, _NormalDetailStrength)
//
//UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
float _DetailNormalUV;
//UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
//UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
//UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
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

float4 LitPassFragment(Varyings input) : SV_TARGET{
UNITY_SETUP_INSTANCE_ID(input);

float3 finalColor = (0, 0, 0);
	
Surface Scattering = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);

BRDF brdf = GetBRDF(Scattering);
GI gi = GetGI(GI_FRAGMENT_DATA(input), Scattering, brdf);

//if(_ScatteringMode == 0)
//finalColor = GetLightingScattering(Scattering, brdf, gi,1);
//if (_ScatteringMode == 1)
//finalColor = GetLightingScattering(Scattering, brdf, gi, 1, SAMPLE_TEXTURE2D(_ScatteringMask, sampler_ScatteringMask, input.baseUV).r);
//if (_ScatteringMode == 2)
//finalColor = GetLightingScattering(Scattering, brdf, gi, 1, _ScatteringAmplitude, _ScatteringScale);

finalColor = GetLightingScattering(Scattering, brdf, gi, 1, _ScatteringAmplitude, _ScatteringScale, SAMPLE_TEXTURE2D(_ScatteringMask, sampler_ScatteringMask, input.baseUV).r);

return float4(finalColor, 1);
}

#endif