#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

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

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_PostFXSource);

float Kd;
float Ks;
float ior;
bool useFresnel;

float sqr(float x) { return x * x; }

float GGX(float NdotH, float alphaG)
{
	return alphaG * alphaG / (PI * sqr(NdotH * NdotH * (alphaG * alphaG - 1) + 1));
}

float smithG_GGX(float Ndotv, float alphaG)
{
	return 2 / (1 + sqrt(1 + alphaG * alphaG * (1 - Ndotv * Ndotv) / (Ndotv * Ndotv)));
}

float3 BRDF_Walter(Surface surface, BRDF brdf, Light light)
{

	float NdotL = dot(surface.normal, light.direction);
	float NdotV = dot(surface.normal, surface.viewDirection);
	if (NdotL < 0 || NdotV < 0) return float3(0,0,0);

	float3 H = normalize(light.direction + surface.viewDirection);
	float NdotH = dot(surface.normal, H);
	float VdotH = dot(surface.viewDirection, H);
	float a = NdotH * brdf.roughness;
	float D = GGX(NdotH, a);
	float G = smithG_GGX(NdotL, a) * smithG_GGX(NdotV, a);

	// fresnel
	float c = VdotH;
	float g = sqrt(ior * ior + c * c - 1);
	float F = useFresnel ? 0.5 * pow(g - c, 2) / pow(g + c, 2) * (1 + pow(c * (g + c) - 1, 2) / pow(c * (g - c) + 1, 2)) : 1.0;

	float val = Kd / PI + Ks * D * G * F / (4 * NdotL * NdotV);
	return float3(val, val, val)* brdf.specular;
}


float3 GetLighting(Surface surface, BRDF brdf, Light light) {
	return IncomingLight(surface, light) * BRDF_Walter(surface, brdf, light);
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

float4 _Time;
float _UseRefraction;
float _ClearCoat;
float4 LitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);

	float4 base = getBase(input.baseUV, input.detailUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif

	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	Surface surface = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);
	
	#if defined(_PREMULTIPLY_ALPHA)
		BRDF brdf = GetBRDF(surface, true);
	#else
		BRDF brdf = GetBRDF(surface);
	#endif
	GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf);//, GetClearCoatRoughness()
	Light light = GetDirectionalLightIndex(0);
	float3 color = float3(0, 0, 0);
	if (_UseRefraction == 1)
	color = GetLightingGlass(surface, brdf, gi) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor).a;
	if (_UseRefraction == 0)
	color = GetLighting(surface, brdf, gi);
	
	//color += color * Fresnel(surface.fresnelStrength, surface.normal, surface.viewDirection);

	color += getEmission(input.baseUV);

	if (UseClearCoat() == 1)
		color += ClearCoat(getClearCoatRoughness(), surface, gi, light, brdf) * _ClearCoat;
	return float4(color, SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, input.baseUV).r);
}

#endif