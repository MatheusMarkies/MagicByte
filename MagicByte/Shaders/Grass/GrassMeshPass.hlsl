#ifndef Grass_PASS_INCLUDED
#define Grass_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

float4 _Time;

float _DetailNormalUV;


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
	GI_VARYINGS_DATA
		UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex(Attributes input) {
	UNITY_SETUP_INSTANCE_ID(input);
	Varyings output;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);

	output.positionWS = TransformObjectToWorld(input.positionOS) + (_Time.x * input.positionOS.g);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
	output.baseUV = input.baseUV;

	return output;
}
float _Scattering;
float4 LitPassFragment(Varyings input) : SV_TARGET{
UNITY_SETUP_INSTANCE_ID(input);

float3 finalColor = (0, 0, 0);

Surface Grass = getSurface(input.baseUV, input.positionWS, input.positionCS, input.normalWS, input.tangentWS);

BRDF brdf = GetBRDF(Grass);
GI gi = GetGI(GI_FRAGMENT_DATA(input), Grass, brdf);

finalColor = GetLightingScatteringFresnel(Grass, brdf, gi, _Scattering, IORtoF0(Grass.ior));
clip(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV).a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
return float4(finalColor, SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV).a);
}

#endif