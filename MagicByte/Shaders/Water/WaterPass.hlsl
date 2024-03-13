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

TEXTURE2D(_OtherNormalMap);
SAMPLER(sampler_OtherNormalMap);

sampler2D _WaveMap;

float4 _Time;

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float, _OtherNormalStrength)
UNITY_DEFINE_INSTANCED_PROP(float4, _SecondTillingNormal)
UNITY_DEFINE_INSTANCED_PROP(float4, _SecondNormalSpeed)
UNITY_DEFINE_INSTANCED_PROP(float4, _MainNormalSpeed)

UNITY_DEFINE_INSTANCED_PROP(float4, _WaveColor)
UNITY_DEFINE_INSTANCED_PROP(float, _WaveHeight)
UNITY_DEFINE_INSTANCED_PROP(float, _WaveScale)
UNITY_DEFINE_INSTANCED_PROP(float4, _WaveSpeed)
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
	//	input.positionOS.x += getHeight(input.baseUV).x;
	//	input.positionOS.y += getHeight(input.baseUV).y;
	//}

	//float4 waveUV = float4(TransformObjectToWorld(input.positionOS).x + _Time.x * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveSpeed).x, TransformObjectToWorld(input.positionOS).z + _Time.x * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveSpeed).y, 0, 0) * 0.1 * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveScale);
	//float height = tex2Dlod(_WaveMap, waveUV);
	//input.positionOS.y -= height * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveHeight);

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

		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * 5))));
		color += scattering * (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveColor) * 1.5) + surfaceWS.color * scattering;
	}
	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += mergeLighting(surfaceWS, brdf, light);

		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * 5))));
		color += scattering * (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveColor) * 1.5) + surfaceWS.color * scattering;
	}

	return color;
}
/*End Lighting*/

TEXTURE2D(_ScreenDepth);
SAMPLER(sampler_ScreenDepth);
float _Depth;
float _FarPlane;

float4 LitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);

    Surface surface = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);

	#if defined(_CLIPPING)
		clip(surface.alpha - max(getCutoff(), surface.alpha));
	#endif

	float4 screenPosition = mul(unity_MatrixVP, input.positionWS);
	float4 waterDepth = SAMPLE_TEXTURE2D(_ScreenDepth, sampler_ScreenDepth, input.baseUV) * _FarPlane - float4(screenPosition.a * _Depth, screenPosition.a * _Depth, screenPosition.a * _Depth, screenPosition.a * _Depth);

	float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(Props, _TillingNormal) + UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainNormalSpeed) * _Time.x);
	float scale = UNITY_ACCESS_INSTANCED_PROP(Props, _NormalStrength);
	float3 normal = DecodeNormal(map, scale);

	map = SAMPLE_TEXTURE2D(_OtherNormalMap, sampler_OtherNormalMap, input.baseUV * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SecondTillingNormal) + UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SecondNormalSpeed) * _Time.x);
	scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _OtherNormalStrength);
	float3 second = DecodeNormal(map, scale);

	float3 normalMap = BlendNormalRNM(normal, second);

	surface.normal = NormalTangentToWorld(normalMap, input.normalWS, input.tangentWS);
	surface.interpolatedNormal = input.normalWS;
	surface.binormal = cross(NormalTangentToWorld(surface.normal, input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;

	ClipLOD(input.positionCS.xy, unity_LODFade.x);
	clip(SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, input.baseUV).r - 0.1);

	//Get BRDF structure
	BRDF brdf = getBRDF(surface);

	/*GI*/
	GI gi = getGI(GI_FRAGMENT_DATA(input), surface, brdf);
	/*End GI*/

	//float4 waveUV = float4(input.positionWS.x + _Time.x * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveSpeed).x, input.positionWS.z + _Time.x * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveSpeed).y, 0, 0) * 0.1 * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveScale);
	//float height = 1-tex2Dlod(_WaveMap, waveUV);

	float3 color = getDirectLighting(surface, brdf, gi);
	color += getLighting(surface, brdf, gi);
	color = lerp(gi.refract,color, surface.alpha);
	float3 waveColor = lerp(gi.refract, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WaveColor), surface.alpha);
	color *= normalize(waterDepth);

	return float4(lerp(waveColor, color, surface.normal.y), surface.alpha);
}

#endif