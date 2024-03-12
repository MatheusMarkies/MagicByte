#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/Simplex3D.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

float4 _Time;

TEXTURE2D(_FurColor);
SAMPLER(sampler_FurColor);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float, _FurThinness)
UNITY_DEFINE_INSTANCED_PROP(float3, _Gravity)
//UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 baseUV : TEXCOORD0;
	float2 lightmapUV: TEXCOORD1;
	float2 dynamicLightmapUV : TEXCOORD2;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS : VAR_NORMAL;
	float4 tangentWS : VAR_TANGENT;
	float2 baseUV : VAR_BASE_UV;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex (Attributes input) {
UNITY_SETUP_INSTANCE_ID(input);
	Varyings output;

	float3 P = float3(0,0,0);
	float d = FurShell;
	P += input.positionOS + (input.normalOS * d);

	//float3 Gravity = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Gravity);

	//float k = pow(1, 3);

	//Gravity = TransformObjectToWorld(Gravity);
	//P = P + Gravity * k;

	output.positionWS = TransformObjectToWorld(float4(P, 1.0f));
	//output.positionCS = mul(mul(output.positionWS,normalize(_WorldSpaceCameraPos - output.positionWS)), _ProjectionParams);
	output.positionCS = TransformWorldToHClip(float4(output.positionWS,1));
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
	output.baseUV = input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FurThinness);

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

	//float4 finalColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FurColor);
	float4 FurColour = SAMPLE_TEXTURE2D(_FurColor, sampler_FurColor, input.baseUV);

	clip(FurColour.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));

return float4(FurColour);
}

#endif