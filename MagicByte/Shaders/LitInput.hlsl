#ifndef INPUT_INCLUDED
#define INPUT_INCLUDED

//#include "ShadowCasterPass.hlsl"
#include "../../ShaderLibrary/Surface.hlsl"

float _Gamma = 2.2f;

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_DetailNormalMap);
SAMPLER(sampler_DetailNormalMap);

TEXTURE2D(_DetailMap);
SAMPLER(sampler_DetailMap);

TEXTURE2D(_AlphaMap);
SAMPLER(sampler_AlphaMap);

TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_SmoothnessMap);
SAMPLER(sampler_SmoothnessMap);

TEXTURE2D(_MetalMap);
SAMPLER(sampler_MetalMap);

TEXTURE2D(_OcclusionMap);
SAMPLER(sampler_OcclusionMap);

sampler2D _HeightMap;

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _DetailMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _SubSurfaceColor)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _AlphaMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _MetalMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float, _UseRoughness)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _SmoothnessMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _OcclusionMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float, _HeightMode)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Height)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Sheen)//
	UNITY_DEFINE_INSTANCED_PROP(float, _SheenTint)//
	UNITY_DEFINE_INSTANCED_PROP(float, _SubSurface)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Anisotropic)//
	UNITY_DEFINE_INSTANCED_PROP(float, _Transmission)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)//
	UNITY_DEFINE_INSTANCED_PROP(float4, _NormalMap_ST)//
	UNITY_DEFINE_INSTANCED_PROP(float, _NormalStrength)//
	UNITY_DEFINE_INSTANCED_PROP(float, _IOR)//
	UNITY_DEFINE_INSTANCED_PROP(float, _ScatteringScale)//
	UNITY_DEFINE_INSTANCED_PROP(float, _UseClearCoat)//
	UNITY_DEFINE_INSTANCED_PROP(float, _ClearCoatRoughness)//
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float GrayScale(float3 map) {
	return (map.r + map.g + map.b) / 3;
}

float3 GammaToLinear(float3 color) {
	return float3(pow(color.r, 2.2f), pow(color.g, 2.2f), pow(color.b, 2.2f));
}

float2 TransformBaseUV (float2 baseUV) {
	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	return baseUV * baseST.xy + baseST.zw;
}

float2 TransformDetailUV (float2 detailUV) {
	float4 detailST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailMap_ST);
	return detailUV * detailST.xy + detailST.zw;
}

float4 getDetail (float2 detailUV) {
	float4 map = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, detailUV);
	return map * 2.0 - 1.0;;
}

float3 getNormal (float2 baseUV, float2 detailUV = 0.0) {
	float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, baseUV);
	float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalStrength);
	float3 normal = DecodeNormal(map, scale);

	//map = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUV);
	//scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalStrength);
	//float3 detail = DecodeNormal(map, scale);
	//normal = BlendNormalRNM(normal, detail);

	return normal;
}

float3 getSubSurfaceColor() {
	return GammaToLinear(UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SubSurfaceColor));
}

float3 getScatteringScale() {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ScatteringScale);
}

float4 getBase (float2 baseUV, float2 detailUV = 0.0) {
	float4 base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);

	//float detail = getDetail(detailUV).r * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailAlbedo);
	//float mask = saturate(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailMap, detailUV));

	//base.rgb = lerp(sqrt(base.rgb), detail < 0.0 ? 0.0 : 1.0, abs(detail)* mask);

	return float4(GammaToLinear((base * color).rgb), base.a);
}

float3 getEmission (float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, baseUV);
	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
	return GammaToLinear(map.r * color.rgb);
}

float getOcclusion (float2 baseUV) {
	float strength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Occlusion);
	float occlusion =  abs(GammaToLinear(SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, baseUV)).r);
	occlusion = lerp(occlusion, 1.0, 1-strength);
	return occlusion;
}

float getIOR () {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _IOR);
}

float getSheen() {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Sheen);
}

float getTransmission() {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Transmission);
}

float getSheenTint() {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SheenTint);
}
float getSubSurface() {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SubSurface);
}
float getAnisotropic() {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Anisotropic);
}
float getAlpha(float2 baseUV) {
	return GrayScale(SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, baseUV)) * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor).a;
}

float getCutoff () {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

float2 getHeight(float2 baseUV) {
	float2 height = float2(UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Height), UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Height));
	height *= abs(GammaToLinear(tex2Dlod(_HeightMap, float4(baseUV, 0, 0))));
	return height;
}

float getMetallic (float2 baseUV) {
	float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
	metallic *= abs(GammaToLinear(SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, baseUV)).r);
	return metallic;
}

float getSmoothness (float2 baseUV) {
	float smoothness = 1-UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
	smoothness *= abs(GammaToLinear(SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, baseUV)).r);

	return smoothness;
}

bool UseClearCoat() {
	if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _UseClearCoat) == 1)
		return true;
	return false;
}
float getClearCoatRoughness () {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ClearCoatRoughness);
}

bool isUseRoughness() {
	if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _UseRoughness) == 1)
		return true;
	return false;
}

float2 ParallaxOffset(float h, float height, float3 viewDir)
{
	h = h * height - height / 2.0;
	float3 v = normalize(viewDir);
	v.z += 0.42;
	return h * (v.xy / v.z);
}

Surface getSurface(float2 baseUV,float3 positionWS, float4 positionCS,float3 normalWS,float4 tangentWS) {
	Surface surface;

	surface.position = positionWS;
	surface.normal = NormalTangentToWorld(getNormal(baseUV), normalWS, tangentWS);
	surface.interpolatedNormal = normalWS;
	surface.viewDirection = normalize(_WorldSpaceCameraPos - positionWS);
	surface.tangent = tangentWS;
	surface.binormal = cross(NormalTangentToWorld(getNormal(baseUV), normalWS, tangentWS), tangentWS.xyz) * tangentWS.w;

	float heightTex = GammaToLinear(SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, baseUV)).r;
	float2 parallaxOffset = ParallaxOffset(heightTex, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Height), surface.viewDirection);

	if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _HeightMode) == 0)
		parallaxOffset = float2(0,0);

	surface.color = getBase(baseUV + parallaxOffset);
	surface.alpha = getAlpha(baseUV);

	surface.subSurfaceColor = getSubSurfaceColor();
	surface.metallic = getMetallic(baseUV);

	if (isUseRoughness())
		surface.smoothness = getSmoothness(baseUV);
	else
		surface.smoothness = PerceptualRoughnessToPerceptualSmoothness(getSmoothness(baseUV));

	surface.sheen = getSheen();
	surface.sheenTint = getSheenTint();
	surface.subsurface = getSubSurface();

	surface.scatteringScale = getScatteringScale();

	surface.occlusion = getOcclusion(baseUV);
	surface.depth = -TransformWorldToView(positionWS).z;

	surface.ior = getIOR();
	surface.dither = InterleavedGradientNoise(positionCS, 0);
	surface.anisotropic = getAnisotropic();
	surface.transmission = getTransmission();

	return surface;
}

#endif