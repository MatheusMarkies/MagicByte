#ifndef INDIRECTBRDF_INCLUDED
#define INDIRECTBRDF_INCLUDED

#include "../../ShaderLibrary/BRDF.hlsl"

float3 indirectBRDF(Surface surface, BRDF brdf, float3 diffuse, float3 specular, float ior) {

	float3 reflection = specular * brdf.fresnel;
	reflection /= brdf.roughness * brdf.roughness + 1.0;

	return lerp(diffuse, reflection, surface.smoothness) * surface.color * surface.occlusion;
}

#endif