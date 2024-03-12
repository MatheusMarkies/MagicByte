#ifndef LIT_PASS_INCLUDED
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
float _UseRefraction;
float _ClearCoat;
float4 LitPassFragment (Varyings input) : SV_TARGET {
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
	GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf, getClearCoatRoughness());
	Light light = GetDirectionalLightIndex(0);
	float3 color = GetLighting(surface, brdf, gi);
	
	color += color*Fresnel(IORtoF0(surface.ior), surface.normal, surface.viewDirection);

	color += getEmission(input.baseUV);

	if (_UseRefraction == 1) {
		color += gi.refract;
	}
	/*if (UseRefraction() == 2) {
	BRDF brdf = GetBRDF(surface, true);
	}*/

	//float4 noiseTexture = SAMPLE_TEXTURE2D(_MicroFlakes, sampler_BaseMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile) + float2(sin(_Time.y * -UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed)), sin(_Time.y * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed))));
	//float4 noiseTexture2 = SAMPLE_TEXTURE2D(_MicroFlakes, sampler_BaseMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesTile) + float2(sin(_Time.y * -UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed)), sin(_Time.y * -UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MicroFlakesSpeed))));

	if (UseClearCoat() == 1) {
		color += ClearCoat(getClearCoatRoughness(), surface, gi, light, brdf) * _ClearCoat; + Iridescence(surface, light, _IridescenceTile) * _IridescenceThickness;
	}
	else
		color += Iridescence(surface, light, _IridescenceTile)* _IridescenceThickness;

	return float4(color, surface.alpha);
}

#endif