#ifndef RAINY_INCLUDED
#define RAINY_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

float4 _Time;
float _Distortion;
float _Blur;
float _Size;
float _T;
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

float _IOR;

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

float N21(float2 p) {
	p = frac(p * float2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return frac(p.x * p.y);
}

float3 Layer(float2 UV, float t) {

	float2 aspect = float2(2, 1);
	float2 uv = UV * _Size * aspect;
	uv.y += t * .25;

	float2 gv = frac(uv) - .5;
	float2 id = floor(uv);

	float n = N21(id);
	t += n * 6.2831;

	float w = UV.y * 10;
	float x = (n - 0.5) * 0.8;
	x += (0.4 - abs(x)) * sin(3 * w) * pow(sin(w), 6) * 0.45;

	float y = -sin(t + sin(t + sin(t) * .5)) * 0.45;

	y -= (gv.x - x) * (gv.x - x);

	float2 dropPos = (gv - float2(x, y)) / aspect;
	float drop = smoothstep(.05, .03, length(dropPos));

	float2 trailPos = (gv - float2(x, t * .25)) / aspect;
	trailPos.y = (frac(trailPos.y * 8) - .5) / 8;
	float trail = smoothstep(.03, .01, length(trailPos));
	float fogTrail = smoothstep(-0.05, .05, dropPos.y);
	fogTrail *= smoothstep(.5, y, gv.y);
	trail *= fogTrail;
	fogTrail *= smoothstep(.05, 0.04, abs(dropPos.x));

	//col += fogTrail * .5;
	//col += trail;
	//col += drop;

	float2 offSet = drop * dropPos + trail * trailPos;
	//if (gv.x > .48 || gv.y > .49)
	//	col = float4(1, 0, 0, 1);

	return float3(offSet, fogTrail);
}

float4 LitPassFragment(Varyings input) : SV_TARGET{
UNITY_SETUP_INSTANCE_ID(input);

float3 finalColor = (0, 0, 0);
	
Surface rainy;

rainy.position = input.positionWS;

float t = fmod(_Time.y + _T, 7200);

float3 Drops = Layer((input.baseUV), t);
Drops += Layer((input.baseUV) * 1.35 + 1.54, t);


float2 NormalUV = (input.baseUV + Drops.xy * _Distortion);
float2 NormalSecUV = (input.baseUV + Drops.xy * _Distortion) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalUV);

float4 Nmap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, NormalUV);
float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalStrength);
float3 normalMain = DecodeNormal(Nmap, scale);

float4 NmapSec = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, NormalSecUV);
float scaleSec = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalStrength);
float3 normalSec = DecodeNormal(NmapSec, scaleSec);

rainy.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic) * SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, input.baseUV).r;
rainy.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness) * SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, input.baseUV).r;

float3 normal = BlendNormalRNM(normalMain, normalSec);

rainy.normal = NormalTangentToWorld(normal, input.normalWS, input.tangentWS);
rainy.viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);

rainy.fresnelStrength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Fresnel);
rainy.color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, (input.baseUV + Drops.xy * _Distortion)) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);

rainy.interpolatedNormal = input.normalWS;

rainy.depth = -TransformWorldToView(input.positionWS).z;
rainy.tangent = input.tangentWS;
rainy.binormal = cross(NormalTangentToWorld(normal, input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;

rainy.anisotropic = 0;

float4 ao = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.baseUV);
ao = (ao.r + ao.g + ao.b) / 3;
ao = 1 - ao * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Occlusion);

rainy.occlusion = 1 - ao;
rainy.dither = 1;

BRDF brdf = GetBRDF(rainy);
GI gi = GetRainyGI(GI_FRAGMENT_DATA(input), rainy, brdf, _IOR, _Refract, _Blur + (1 - Drops.z), (input.baseUV + Drops.xy * _Distortion));
Light light = GetDirectionalLightIndex(0);
finalColor = GetLighting(rainy, brdf, gi) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor).a;

finalColor += (gi.refract);

float4 EmissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.baseUV);
float4 Ecolor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
finalColor += (EmissionMap.r * Fresnel(rainy.fresnelStrength, rainy.normal, rainy.viewDirection))* rainy.fresnelStrength * Ecolor.rgb + EmissionMap.r*Ecolor.rgb;

return float4(finalColor,0);
}

#endif