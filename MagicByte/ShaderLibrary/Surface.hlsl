#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface {
	float3 position;
	float3 normal;
	float3 interpolatedNormal;
	float3 viewDirection;
	float depth;
	float4 tangent;
	float3 binormal;
	float3 color;
	float alpha;
	float metallic;
	float smoothness;
	float occlusion;
	float fresnelStrength;
	float dither;
	float anisotropic;
	//float Scattering;
};

#endif