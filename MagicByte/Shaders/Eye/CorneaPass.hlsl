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


UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float, _ClearCoatFresnel)//
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

	if (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _HeightMode) == 0) {
		input.positionOS.x += getHeight(input.baseUV).x;
		input.positionOS.y += getHeight(input.baseUV).y;
	}

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
	float3 bsdf = DirectBSDF(surface, brdf, light, surface.ior);
	light.direction = (light.direction + 2 * surface.normal * (-light.direction * surface.normal)) / 1.5f;
	float3 btdf = DirectBSDF(surface, brdf, light, surface.ior);
	return IncomingLight(surface, light) * bsdf * btdf;
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

float circleShape(float2 position, float radius) {
	return step(radius, length(position));
}

float4 LitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);

    Surface surface = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);
	surface.metallic = 1;
	surface.smoothness = 0.89;

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

	float3 color = surface.color;
	color += getDirectLighting(surface, brdf, gi);

	float2 irisCenter = input.baseUV * 2.0 - 1.0f;
	color = lerp(color, RadialNoise(input.baseUV), (1 - circleShape(irisCenter, 0.3f)));
	color *= circleShape(irisCenter, 0.3f/5);

	color += ClearCoat(surface.clearCoatRoughness, surface, gi, brdf) * getClearCoat() * Fresnel(1, surface.normal, surface.viewDirection / (UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ClearCoatFresnel) * 3.0f));

	return float4(color, 1);
}

#endif