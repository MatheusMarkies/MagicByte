#ifndef CUSTOM_LIT_INPUT_INCLUDED
#define CUSTOM_LIT_INPUT_INCLUDED

//#include "ShadowCasterPass.hlsl"

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

TEXTURE2D (_DetailMap);
SAMPLER (sampler_DetailMap);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_DetailNormalMap);
SAMPLER(sampler_DetailNormalMap);

TEXTURE2D(_OcclusionMap);
SAMPLER(sampler_OcclusionMap);

TEXTURE2D(_SmoothnessMap);
SAMPLER(sampler_SmoothnessMap);

TEXTURE2D(_MetalMap);
SAMPLER(sampler_MetalMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
	UNITY_DEFINE_INSTANCED_PROP(float4, _DetailMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float, _DetailAlbedo)
	UNITY_DEFINE_INSTANCED_PROP(float, _DetailSmoothness)
	UNITY_DEFINE_INSTANCED_PROP(float, _NormalStrength)
	UNITY_DEFINE_INSTANCED_PROP(float, _DetailNormalStrength)
	UNITY_DEFINE_INSTANCED_PROP(float, _MicroFlakesTile)
	UNITY_DEFINE_INSTANCED_PROP(float, _ClearCoat)
	UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
	UNITY_DEFINE_INSTANCED_PROP(float, _UseClearCoat)
	UNITY_DEFINE_INSTANCED_PROP(float, _clearCoatRoughness)
	UNITY_DEFINE_INSTANCED_PROP(float, _MicroFlakesAnim)
	UNITY_DEFINE_INSTANCED_PROP(int, _MicroFlakesAmount)
	UNITY_DEFINE_INSTANCED_PROP(float4, _MicroFlakesColor)
	UNITY_DEFINE_INSTANCED_PROP(int, _UseRefraction)
	UNITY_DEFINE_INSTANCED_PROP(float, _UseRoughness)
	//UNITY_DEFINE_INSTANCED_PROP(float, _Scattering)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float2 TransformBaseUV (float2 baseUV) {
	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	return baseUV * baseST.xy + baseST.zw;
}

float2 TransformDetailUV (float2 detailUV) {
	float4 detailST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailMap_ST);
	return detailUV * detailST.xy + detailST.zw;
}

float4 GetDetail (float2 detailUV) {
	float4 map = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, detailUV);
	return map * 2.0 - 1.0;;
}

float3 GetNormalTS (float2 baseUV, float2 detailUV = 0.0) {
	float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, baseUV);
	float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalStrength);
	float3 normal = DecodeNormal(map, scale);

	map = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUV);
	scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalStrength);
	float3 detail = DecodeNormal(map, scale);
	normal = BlendNormalRNM(normal, detail);

	return normal;
}

float3 Gamma2Linear(float3 color) {
	return float3(pow(color.r, 2.2f), pow(color.g, 2.2f), pow(color.b, 2.2f));
}

float4 GetBase (float2 baseUV, float2 detailUV = 0.0) {
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);

	float detail = GetDetail(detailUV).r * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailAlbedo);
	float mask = saturate(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailMap, detailUV));
	map.rgb = lerp(sqrt(map.rgb), detail < 0.0 ? 0.0 : 1.0, abs(detail)* mask);
	map.rgb *= map.rgb;

	return float4(Gamma2Linear((map * color).rgb), map.a);
}

//float4 GetBase(float2 baseUV) {
//	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
//	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
//
//	map.rgb *= map.rgb;
//
//	return map * color;
//}

float3 GetEmission (float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, baseUV);
	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
	return map.r * color.rgb;
}

float GetOcclusion (float2 baseUV) {
	float strength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Occlusion);
	float occlusion =  pow(abs(SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, baseUV).r), 2.2);
	occlusion = lerp(occlusion, 1.0, 1-strength);
	return occlusion;
}

float GetFresnel () {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Fresnel);
}

float GetCutoff (float2 baseUV) {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

float GetMetallic (float2 baseUV) {
	float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
	metallic *= pow(abs(SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, baseUV).r), 2.2);
	return metallic;
}

float GetSmoothness (float2 baseUV) {
	float smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
	smoothness *= pow(abs(SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, baseUV).r), 2.2);

	/*float detail = GetDetail(detailUV).b * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailSmoothness);
	float mask = SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, detailUV).r;
	smoothness = lerp(smoothness, detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask);*/
	
	return smoothness;
}
//float GetAnisotropicX() {

//	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _AnisotropicX);
//}
//float GetAnisotropicY() {

//	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _AnisotropicY);
//}

float UseClearCoat() {

	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _UseClearCoat);
}
float GetClearCoatRoughness () {
	
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_clearCoatRoughness);
}
float GetClearCoat() {

	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ClearCoat);
}

int UseRefraction() {
   return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _UseRefraction);
}

float UseRoughness() {

	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _UseRoughness);
}

#endif