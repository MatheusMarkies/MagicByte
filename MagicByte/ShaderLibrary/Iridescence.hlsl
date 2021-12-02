#ifndef IRIDESCENCE_BRDF_INCLUDED
#define IRIDESCENCE_BRDF_INCLUDED

#include "../ShaderLibrary/Simplex3D.hlsl"
#include "../ShaderLibrary/ColorFunction.hlsl"

// Common constants
#define PI 3.14159265359

float3 IridescenceSimple(Surface surface,Light light,float3 iridescenceThickness) {

	float VoL = dot(surface.viewDirection, light.direction);
	float ss = 401 + (250 * snoise(float3(iridescenceThickness.r * VoL, iridescenceThickness.g, 0)));

	float3 I = ZucconiGradientFunction(ss) * Fresnel(iridescenceThickness.b, surface.normal, surface.viewDirection);

	return I;
}

float3 Iridescence(Surface surface, Light light, float tile) {

	float NoL = dot(surface.normal, light.direction);
	float VoL = dot(surface.viewDirection, light.direction);
	float NoV = dot(surface.viewDirection, surface.normal);
	float fresnelF = Fresnel(surface.ior, surface.normal, surface.viewDirection);

	float ss = 401 + (250 * snoise(float3(VoL, NoV,0)));
	float3 rr = RodriguesRotation(lerp(NoV, fresnelF, surface.ior) * tile, ZucconiGradientFunction(ss));

	float3 I = rr;

	return I;
}

#endif