#ifndef DEFAULT_PASS_INCLUDED
#define DEFAULT_PASS_INCLUDED

//#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/BSDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Noise.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"
#include "../../ShaderLibrary/ColorFunction.hlsl"

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

	if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _HeightMode) == 0) {
		input.positionOS.x += getHeight(input.baseUV).x;
		input.positionOS.y += getHeight(input.baseUV).y;
	}

	output.color = input.color;
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);

	output.baseUV = TransformBaseUV(input.baseUV);
	output.detailUV = TransformDetailUV(input.baseUV);

	return output;
}

/*Lighting*/
float3 mergeLighting(Surface surface, BRDF brdf, Light light) {
	//To edit the BRDF template used just change the field below : *DirectBSDF*
	return IncomingLight(surface, light) * DirectBSDF(surface, brdf, light, surface.ior);
}

float3 getDirectLighting(Surface surfaceWS, BRDF brdf, GI gi) {
	float3 color = float3(0, 0, 0);

	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += mergeLighting(surfaceWS, brdf, light);
	}
	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += mergeLighting(surfaceWS, brdf, light);
	}

	return color;
}
/*End Lighting*/

TEXTURE2D(_RedMap);
SAMPLER(sampler_RedMap);

TEXTURE2D(_GreenMap);
SAMPLER(sampler_GreenMap);

TEXTURE2D(_BlueMap);
SAMPLER(sampler_BlueMap);

TEXTURE2D(_SmoothnessNormal);
SAMPLER(sampler_SmoothnessNormal);

float4 LitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);

    Surface surface = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);

	surface.color = lerp(getBase(input.baseUV),SAMPLE_TEXTURE2D(_RedMap, sampler_RedMap, input.baseUV).rgb, input.color.r) *
		lerp(getBase(input.baseUV), SAMPLE_TEXTURE2D(_GreenMap, sampler_GreenMap, input.baseUV).rgb, input.color.g) *
		lerp(getBase(input.baseUV), SAMPLE_TEXTURE2D(_BlueMap, sampler_BlueMap, input.baseUV).rgb, input.color.b);

	surface.metallic = 1.0f;
	surface.smoothness = 1 - input.color.a;

	float _SmoothnessNMapScale = max(0, min(1, (1 - input.color.a)));
	float4 _SmoothnessNMap = SAMPLE_TEXTURE2D(_SmoothnessNormal, sampler_SmoothnessNormal, input.baseUV);
	float3 _SmoothnessNormal = DecodeNormal(_SmoothnessNMap, _SmoothnessNMapScale);
	
	float3 normal = getNormal(input.baseUV);

	if (input.color.a != 1)
	normal = BlendNormalRNM(normal, _SmoothnessNormal);
	
	surface.normal = NormalTangentToWorld(normal, input.normalWS, input.tangentWS);

	#if defined(_CLIPPING)
		clip(surface.alpha - max(getCutoff(), surface.alpha));
	#endif

	ClipLOD(input.positionCS.xy, unity_LODFade.x);
	clip(SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, input.baseUV).r - 0.1);

	//Get BRDF structure
	BRDF brdf = getBRDF(surface);

	/*GI*/
	GI gi = getGI(GI_FRAGMENT_DATA(input), surface, brdf);
	/*End GI*/

	float3 color = getDirectLighting(surface, brdf, gi);
	color += getLighting(surface, brdf, gi);
	
	if (UseClearCoat() == 1)
		color += ClearCoat(surface.clearCoatRoughness, surface, gi, brdf) * getClearCoat();

	return float4(color , surface.alpha);
}

#endif