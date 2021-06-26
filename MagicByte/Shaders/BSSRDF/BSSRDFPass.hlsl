#ifndef BSSRDF_PASS_INCLUDED
#define BSSRDF_PASS_INCLUDED

//#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BSSRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Noise.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"
#include "../../ShaderLibrary/ColorFunction.hlsl"

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

float3 IncomingLight(Surface surface, Light light) {
	float3 color = float3(1, 1, 1);
	color = light.color;
	return saturate(dot(surface.normal, light.direction) * light.attenuation) * lerp(light.color, color, light.scatteringBorders);
}

float3 GetLighting(Surface surface, BRDF brdf, Light light,float ior) {
	return IncomingLight(surface, light) * DirectBSSRDF(surface, brdf, light,ior);
}

float3 GetLighting(Surface surfaceWS, BRDF brdf, GI gi,float ior) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = lerp(gi.refract, IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular, ior), surfaceWS.alpha);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light, ior);
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light, ior);
	}

	return color;
}

float4 LitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);

Surface surface = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);

	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif

	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	clip(SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, input.baseUV).r - 0.1);

	BRDF brdf = GetBRDF(surface);
	GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf);
	if(surface.alpha != 1)
	gi = GetGlassGI(GI_FRAGMENT_DATA(input), surface, brdf,1-surface.ior,surface.alpha);

	Light light = GetDirectionalLightIndex(0);
	float3 color = float3(0, 0, 0);

	color = GetLighting(surface, brdf, gi, surface.ior);
	
	if (UseClearCoat() == 1)
		color += ClearCoat(getClearCoatRoughness(), surface, gi, light, brdf);

	//color += Voronoi(float3(input.baseUV.x * 200, input.baseUV.y*200,10));

	return float4(color , surface.alpha);
}

#endif