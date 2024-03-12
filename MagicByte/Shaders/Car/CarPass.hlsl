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

TEXTURE2D(_FlakesMap);
SAMPLER(sampler_FlakesMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float, _FresnelPower)
UNITY_DEFINE_INSTANCED_PROP(float4, _FresnelColor)
UNITY_DEFINE_INSTANCED_PROP(float, _FlakesStrength)
UNITY_DEFINE_INSTANCED_PROP(float4, _TillingFlakes)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

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

	//if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _HeightMode) == 0) {
		//input.positionOS.x += getHeight(input.baseUV).x;
		//input.positionOS.y += getHeight(input.baseUV).y;
	//}

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

float4 LitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);

    Surface surface = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);

	float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(Props, _TillingNormal));
	float scale = UNITY_ACCESS_INSTANCED_PROP(Props, _NormalStrength);
	float3 normal = DecodeNormal(map, scale);

	map = SAMPLE_TEXTURE2D(_FlakesMap, sampler_FlakesMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TillingFlakes));
	scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FlakesStrength);
	float3 second = DecodeNormal(map, scale);

	float3 normalMap = BlendNormalRNM(normal, second);

	surface.normal = NormalTangentToWorld(normalMap, input.normalWS, input.tangentWS);
	surface.interpolatedNormal = input.normalWS;
	surface.binormal = cross(NormalTangentToWorld(surface.normal, input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;

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
	
	float fresnel = 1.0 - max(dot(normalize(surface.viewDirection.xyz), surface.normal), 0.0);
	fresnel = pow(fresnel, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FresnelPower));
	color = lerp(color, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FresnelColor).xyz, fresnel);

	color += ClearCoat(surface.clearCoatRoughness, surface, gi, brdf) * getClearCoat();

	return float4(color , surface.alpha);
}

#endif