#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

//struct Surface {
//	float3 position;
//	float3 normal;
//	float3 interpolatedNormal;
//	float3 viewDirection;
//	float depth;
//	float4 tangent;
//	float3 binormal;
//	float3 color;
//	float alpha;
//	float metallic;
//	float smoothness;
//	float occlusion;
//	float fresnelStrength;
//	float dither;
//	float anisotropic;
//	//float Scattering;
//};
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
	float scatteringScale;
};
//
//Surface BSSRDFtoNormal(SurfaceBSSRDF surfaceB) {
//
//	Surface surface;
//	surface.position = surfaceB.position;
//	surface.normal = surfaceB.normal;
//	surface.interpolatedNormal = surfaceB.interpolatedNormal;
//	surface.viewDirection = surfaceB.viewDirection;
//	surface.depth = surfaceB.subsurface;
//	surface.tangent = surfaceB.tangent;
//	surface.binormal = surfaceB.binormal;
//	surface.color = surfaceB.color;
//	surface.alpha = surfaceB.alpha;
//	surface.metallic = surfaceB.metallic;
//	surface.smoothness = surfaceB.smoothness;
//	surface.occlusion = surfaceB.occlusion;
//	surface.fresnelStrength = surfaceB.ior;
//	surface.dither = surfaceB.dither;
//	surface.anisotropic = surfaceB.anisotropic;
//
//	return surface;
//}


#endif