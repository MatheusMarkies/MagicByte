#ifndef BRDF_INCLUDED
#define BRDF_INCLUDED

#define MEDIUMP_FLT_MAX 65504.0
#define MIN_REFLECTIVITY 0.04
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

float OneMinusReflectivity(float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

struct BRDF {
	float3 diffuse;
	float3 specular;
	float perceptualRoughness;
	float roughness;
	float fresnel;
};

BRDF getBRDF(Surface surface) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);

	brdf.perceptualRoughness = max(PerceptualSmoothnessToPerceptualRoughness(surface.smoothness), 0.01);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

BRDF getBRDF(Surface surface, bool PremultiplyAlpha) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity * surface.alpha;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);

	brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

#endif