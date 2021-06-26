#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"
#include "../../ShaderLibrary/Simplex3D.hlsl"

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
float4 _Time;

float3 _SecondAnisotropicColor;
float3 _AnisotropicColor;
float _AnisotropicScale;
float _SecondAnisotropicScale;
float _specularIntensity;
float _ScatteringAmplitude;
float _ScatteringScale;
TEXTURE2D(_HairLightRamp);
SAMPLER(sampler_HairLightRamp);

float3 GetLightingHair(Surface surfaceWS, BRDF brdf, GI gi, float3 specularColor1, float3 specularColor2, float exp1, float exp2, float specularIntensity, float3 ramp) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLightingHair(surfaceWS, brdf, light, specularColor1, specularColor2, exp1, exp2, specularIntensity, ramp);
		float3 lightDir = light.direction + surfaceWS.normal;
		float3 translucency = (pow(saturate(dot(surfaceWS.viewDirection, -lightDir)), _ScatteringAmplitude) * _ScatteringScale + gi.diffuse * 1) *light.attenuation; //* light.distanceAttenuation;
		// color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
		color += surfaceWS.color * light.color * translucency;
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLightingHair(surfaceWS, brdf, light, specularColor1, specularColor2, exp1, exp2, specularIntensity, ramp);
		float3 lightDir = light.direction + surfaceWS.normal;
		float3 translucency = (pow(saturate(dot(surfaceWS.viewDirection, -lightDir)), _ScatteringAmplitude) * _ScatteringScale + gi.diffuse * 1) *light.attenuation; //* light.distanceAttenuation;
		// color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
		color += surfaceWS.color * light.color * translucency;
	}

	return color;
}

float4 LitPassFragment (Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);

	float4 base = GetBase(input.baseUV, input.detailUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif

	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	Surface surface;
	surface.position = input.positionWS;
	surface.normal = NormalTangentToWorld(GetNormalTS(input.baseUV, input.detailUV), input.normalWS, input.tangentWS);
	surface.interpolatedNormal = input.normalWS;
	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.depth = -TransformWorldToView(input.positionWS).z;
	surface.tangent = input.tangentWS;
	surface.binormal = cross(NormalTangentToWorld(GetNormalTS(input.baseUV, input.detailUV), input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;
	surface.color = base.rgb;
	surface.alpha = base.a;

	surface.metallic = 0.2;//GetMetallic(input.baseUV);
	if(UseRoughness() == 0)
	surface.smoothness = GetSmoothness(input.baseUV);
	else
	surface.smoothness = PerceptualRoughnessToPerceptualSmoothness(GetSmoothness(input.baseUV));
	surface.smoothness = 0.3;
	surface.occlusion = GetOcclusion(input.baseUV);

	surface.fresnelStrength = GetFresnel();
	surface.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

	surface.anisotropic = 0.4;// GetAnisotropicX();

	BRDF brdf = GetBRDF(surface);
	GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf, GetClearCoatRoughness());
	Light light = GetDirectionalLightIndex(0);
	float3 color = GetLightingHair(surface, brdf, gi, _AnisotropicColor, _SecondAnisotropicColor, _AnisotropicScale, _SecondAnisotropicScale, _specularIntensity, SAMPLE_TEXTURE2D(_HairLightRamp, sampler_HairLightRamp, input.baseUV));

	float VoL = dot(surface.viewDirection, light.direction);
	float NoL = dot(surface.normal, light.direction);
	float NoV = dot(surface.viewDirection, surface.normal);
	//color += Anisotropic(input.baseUV, 0.7, 0.025, _AnisotropicScale) * _AnisotropicColor;

	color += color*Fresnel(surface.fresnelStrength, surface.normal, surface.viewDirection);

	color += GetEmission(input.baseUV);

	return float4(color, surface.alpha);
}

#endif