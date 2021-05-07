#ifndef WATER_PASS_INCLUDED
#define WATER_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

TEXTURE2D(_Emission);
TEXTURE2D(_Normal);
SAMPLER(sampler_Normal);
SAMPLER(sampler_Emission);
TEXTURE2D(_NormalSecond);
SAMPLER(sampler_NormalSecond);

sampler2D _HeightMap;

float4 _Time;

float _NormalSecondSize;
float _NormalSize;

float4 _WaterBlendColor;
float4 _WaterDistanceColor;
float2 _NormalSpeed;
//float _NormalSecondStrength;
float2 _NormalSecondSpeed;

//UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
//
//	//UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
//	UNITY_DEFINE_INSTANCED_PROP(float4, _WaterBlendColor)
//	UNITY_DEFINE_INSTANCED_PROP(float4, _WaterDistanceColor)
//	UNITY_DEFINE_INSTANCED_PROP(float2, _NormalSpeed)
//	UNITY_DEFINE_INSTANCED_PROP(float, _NormalSecondStrength)
//	UNITY_DEFINE_INSTANCED_PROP(float2, _NormalSecondSpeed)
//
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

	float2 WaveSpeed = float2(2,0) * (_Time.y / 20 * -1);
	float2 WaveUV = input.baseUV;
	WaveUV += WaveSpeed.xy;

	float4 heightMap = tex2Dlod(_HeightMap, float4(WaveUV, 0, 0));

	input.positionOS.y = 0.5 * heightMap.b * abs(sin((90 * input.baseUV.y * 2))) * abs(sin((90 * input.baseUV.x * 2)));

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
	output.baseUV = input.baseUV;
	return output;
}

float _Refraction;

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

float4 LitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);

	////float4 base = GetBase(input.baseUV);
	//#if defined(_CLIPPING)
	//	clip(base.a - GetCutoff(input.baseUV));
	//#endif

	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	float2 normalSpeed = _NormalSpeed.xy * (_Time.y / 20 * -1);
	float2 normalSecSpeed = _NormalSecondSpeed.xy * (_Time.y / 20 * -1);

	float2 NormalUV = input.baseUV;
	NormalUV += normalSpeed.xy;

	float2 NormalSecUV = input.baseUV;
	NormalSecUV += normalSecSpeed.xy;

	float4 Nmap = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, NormalUV * _NormalSize);
	float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalStrength);
	float3 normalMain = DecodeNormal(Nmap, scale);

	float4 NmapSec = SAMPLE_TEXTURE2D(_NormalSecond, sampler_NormalSecond, NormalSecUV * _NormalSecondSize);
	float scaleSec = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalStrength);
	float3 normalSec = DecodeNormal(NmapSec, scaleSec);

	float3 normal = BlendNormalRNM(normalMain, normalSec);

	Surface water;
	water.position = input.positionWS;
	water.normal = NormalTangentToWorld(normal, input.normalWS, input.tangentWS);
	water.interpolatedNormal = input.normalWS;
	water.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	water.depth = -TransformWorldToView(input.positionWS).z;
	water.tangent = input.tangentWS;
	water.binormal = cross(NormalTangentToWorld(normal, input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;
	water.color = lerp(lerp(UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor), _WaterBlendColor, input.baseUV.x), _WaterDistanceColor, Fresnel(GetFresnel(), water.normal, water.viewDirection));
	water.alpha = 1;

	water.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
	water.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);

	water.occlusion = 1;

	water.fresnelStrength = GetFresnel();
	water.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

	water.anisotropic = 0;

	BRDF brdf = GetBRDF(water);
	GI gi = GetGlassGI(GI_FRAGMENT_DATA(input), water, brdf, 0.97, _Refraction);
	float3 color = GetLightingGlass(water, brdf,gi) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor).a;

	float3 uvw = reflect(-water.viewDirection, water.normal);
	float4 EmissionMap = SAMPLE_TEXTURE2D(_Emission, sampler_Emission, uvw);
	float4 Ecolor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor) * Fresnel(water.fresnelStrength, water.normal, water.viewDirection);
	//color += (EmissionMap.rgb * Ecolor.rgb) * saturate(water.normal.x);

	return float4(color, water.alpha);
}

#endif