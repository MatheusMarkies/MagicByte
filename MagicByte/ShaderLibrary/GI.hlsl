#ifndef CUSTOM_GI_INCLUDED
#define CUSTOM_GI_INCLUDED
//https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/master/CGIncludes/UnityGlobalIllumination.cginc
#include "Core RP/ShaderDependencies/EntityLighting.hlsl"
#include "Core RP/ShaderDependencies/ImageBasedLighting.hlsl"

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);

TEXTURE3D_FLOAT(unity_ProbeVolumeSH);
SAMPLER(samplerunity_ProbeVolumeSH);

TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);

#if defined(LIGHTMAP_ON)
#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
#define TRANSFER_GI_DATA(input, output) \
		output.lightMapUV = input.lightMapUV * \
		unity_LightmapST.xy + unity_LightmapST.zw;
#define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
#define GI_ATTRIBUTE_DATA
#define GI_VARYINGS_DATA
#define TRANSFER_GI_DATA(input, output)
#define GI_FRAGMENT_DATA(input) 0.0
#endif

struct GI {
	float3 diffuse;
	float3 specular;
	float3 reflect;
	float3 clearCoatReflect;
	float3 refract;
	ShadowMask shadowMask;
};

float3 SampleLightMap(float2 lightMapUV) {
#if defined(LIGHTMAP_ON)
	return SampleSingleLightmap(
		TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightMapUV,
		float4(1.0, 1.0, 0.0, 0.0),
#if defined(UNITY_LIGHTMAP_FULL_HDR)
		false,
#else
		true,
#endif
		float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0)
	);
#else
	return 0.0;
#endif
}

float3 SampleLightProbe(Surface surfaceWS) {
#if defined(LIGHTMAP_ON)
	return 0.0;
#else
	if (unity_ProbeVolumeParams.x) {
		return SampleProbeVolumeSH4(
			TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
			surfaceWS.position, surfaceWS.normal,
			unity_ProbeVolumeWorldToObject,
			unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
			unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
		);
	}
	else {
		float4 coefficients[7];
		coefficients[0] = unity_SHAr;
		coefficients[1] = unity_SHAg;
		coefficients[2] = unity_SHAb;
		coefficients[3] = unity_SHBr;
		coefficients[4] = unity_SHBg;
		coefficients[5] = unity_SHBb;
		coefficients[6] = unity_SHC;
		return max(0.0, SampleSH9(coefficients, surfaceWS.normal));
	}
#endif
}

float4 SampleLightProbeOcclusion(Surface surfaceWS) {
	return unity_ProbesOcclusion;
}

float4 SampleBakedShadows(float2 lightMapUV, Surface surfaceWS) {
#if defined(LIGHTMAP_ON)
	return SAMPLE_TEXTURE2D(
		unity_ShadowMask, samplerunity_ShadowMask, lightMapUV
	);
#else
	if (unity_ProbeVolumeParams.x) {
		return SampleProbeOcclusion(
			TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
			surfaceWS.position, unity_ProbeVolumeWorldToObject,
			unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
			unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
		);
	}
	else {
		return unity_ProbesOcclusion;
	}
#endif
}

float4 chromaticAberrationReflection(float2 chromaticAberration, float3 uvw, float mip) {
	float colR = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x - chromaticAberration.x, uvw.y - chromaticAberration.x, uvw.z - chromaticAberration.x), mip).r;
	float colG = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x, uvw.y, uvw.z), mip).g;
	float colB = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x + chromaticAberration.x, uvw.y + chromaticAberration.x, uvw.z + chromaticAberration.x), mip).b;


	return float4(lerp(float3(lerp(colR, colG, 0.1), lerp(colG, colB, 0.1), lerp(colR, colB, 0.1)), SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x, uvw.y, uvw.z), mip), 0.25), 1);
}
float4 chromaticAberrationRefraction(float2 chromaticAberration, float3 uvw, float mip) {
	float colR = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x - chromaticAberration.x, uvw.y - chromaticAberration.x, uvw.z - chromaticAberration.x), mip).r;
	float colG = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x, uvw.y, uvw.z), mip).g;
	float colB = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x + chromaticAberration.x, uvw.y + chromaticAberration.x, uvw.z + chromaticAberration.x), mip).b;


	return float4(lerp(float3(lerp(colR, colG, 0.1), lerp(colG, colB, 0.1), lerp(colR, colB, 0.1)), SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x, uvw.y, uvw.z), mip), 0.5), 1);
}

float3 SampleEnvironment(Surface surfaceWS, BRDF brdf) {
	float3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal);
	float mip = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);

	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

float3 SampleEnvironmentAnistropic(Surface surfaceWS, BRDF brdf) {
	float3 AnistropicTg = cross(surfaceWS.viewDirection, surfaceWS.binormal);
	float3 AnistropicNormal = cross(AnistropicTg, surfaceWS.binormal);
	float3 reflectionNormal = normalize(lerp(surfaceWS.normal, AnistropicNormal, abs(surfaceWS.anisotropic)));

	float3 uvw = reflect(-surfaceWS.viewDirection, reflectionNormal);

	float mip = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);
	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

float3 SampleReflect(Surface surfaceWS) {
	float3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal);
	float mip = PerceptualRoughnessToMipmapLevel(PerceptualSmoothnessToPerceptualRoughness(surfaceWS.smoothness));
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);
	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

float3 SampleEnvironmentRainy(Surface surfaceWS, BRDF brdf, float Mip, float2 uvRainy) {
	float3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal) + float3(uvRainy, 0);
	float mip = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness * Mip);
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);

	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

float3 SampleClearCoat(Surface surfaceWS) {
	float3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal);
	float mip = PerceptualRoughnessToMipmapLevel(PerceptualSmoothnessToPerceptualRoughness(surfaceWS.clearCoatRoughness));
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);
	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

float3 SampleRefract(Surface surfaceWS) {
	float3 uvw = refract(-surfaceWS.viewDirection, surfaceWS.normal, surfaceWS.ior);
	float mip = PerceptualRoughnessToMipmapLevel(1-surfaceWS.smoothness);
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);
	return DecodeHDREnvironment(environment + chromaticAberrationRefraction(float2(0.002, 0.0005), uvw, mip), unity_SpecCube0_HDR);
}

float3 SampleRefractRainy(Surface surfaceWS, float IOR, float refraction, float Mip, float2 uvRainy) {
	float3 uvw = refract(-surfaceWS.viewDirection, surfaceWS.normal, IOR) + float3(uvRainy, 0);
	float mip = Mip;
	float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);
	return DecodeHDREnvironment(environment + chromaticAberrationRefraction(float2(0.002, 0.0005), uvw, mip), unity_SpecCube0_HDR) * refraction;
}

GI getGI(float2 lightMapUV, Surface surfaceWS, BRDF brdf) {
	GI gi;
	gi.diffuse = SampleLightMap(lightMapUV) + SampleLightProbe(surfaceWS);

	gi.shadowMask.always = false;
	gi.shadowMask.distance = false;
	gi.shadowMask.shadows = 1.0;

	if (surfaceWS.anisotropic != 0)
		gi.specular = SampleEnvironmentAnistropic(surfaceWS, brdf);
	else
		gi.specular = SampleEnvironment(surfaceWS, brdf);

	gi.reflect = SampleReflect(surfaceWS);
	gi.clearCoatReflect = SampleClearCoat(surfaceWS);
	gi.refract = SampleRefract(surfaceWS);
#if defined(_SHADOW_MASK_ALWAYS)
	gi.shadowMask.always = true;
	gi.shadowMask.shadows = SampleBakedShadows(lightMapUV, surfaceWS);
#elif defined(_SHADOW_MASK_DISTANCE)
	gi.shadowMask.distance = true;
	gi.shadowMask.shadows = SampleBakedShadows(lightMapUV, surfaceWS);
#endif
	return gi;
}

#endif