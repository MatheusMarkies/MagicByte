#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface {
	float3 position;
	float3 normal;
	float3 interpolatedNormal;
	float3 viewDirection;
	float subsurface;
	float4 tangent;
	float3 binormal;
	float3 color;
	float3 subSurfaceColor;
	float alpha;
	float metallic;
	float smoothness;
	float occlusion;
	float ior;
	float dither;
	float anisotropic;
	float sheen;
	float sheenTint;
	float depth;
	float transmission;
	float clearCoatRoughness;
	float scatteringScale;
};

#endif