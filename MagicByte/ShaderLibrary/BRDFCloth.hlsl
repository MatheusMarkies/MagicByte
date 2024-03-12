#ifndef CLOTH_BRDF_INCLUDED
#define CLOTH_BRDF_INCLUDED

struct BRDF {
	float3 diffuse;
	float3 specular;
	float perceptualRoughness;
	float roughness;
	float fresnel;
};

#define PI 3.14159265359
#define MIN_REFLECTIVITY 0.04

float OneMinusReflectivity(float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

BRDF GetBRDF (Surface surface) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);

    brdf.perceptualRoughness =PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

#define MEDIUMP_FLT_MAX 65504.0
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

float SpecularStrength(Surface surface, BRDF brdf, Light light) {
	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float NoH = dot(surface.normal, h);
	float3 NxH = cross(surface.normal, h);
	float a = NoH * brdf.roughness;
	float k = brdf.roughness / (dot(NxH, NxH) + a * a);
	float d = k * k * (1.0 / PI);
	return saturateMediump(d);
}

float Ashikhmin(float NoL, float NoV)
{
	return 1.0 / (4.0 * (NoL + NoV - NoL * NoV));
}

float FresnelTransmissionBRDF(float f0, float f90, float u)
{
	real x = 1.0 - u;
	real x2 = x * x;
	real x5 = x * x2 * x2;
	return (1.0 - f90 * x5) - f0 * (1.0 - x5);
}

float FresnelBRDF(Surface surface) {
	float NoV = dot(surface.normal, surface.viewDirection);
	float f = pow(1.0 - 0.3, 5.0);
	return f + NoV * (1.0 - f);
}

float3 shiftTangent(float3 T, float3 N, float shift)
{
	return normalize((T + shift) * N);
}

float CharlieSheen(float roughness, float NoH) {
	float invAlpha = 1.0 / roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

float disneyDiffuse(float NoV, float NoL, float LoH, float roughness)
{
	float  energyBias = lerp(0, 0.7, roughness);
	float  energyFactor = lerp(1.0, 1.0 / 1.51, roughness);
	float  fd90 = energyBias + 1.0 * LoH * LoH * roughness;
	float f0 = 1.0f;
	float lightScatter = FresnelTransmissionBRDF(f0, fd90, NoL);
	float viewScatter = FresnelTransmissionBRDF(f0, fd90, NoV);
	return  lightScatter * viewScatter * energyFactor;
}

float3 IndirectBRDF (Surface surface, BRDF brdf, float3 diffuse, float3 specular){

float fresnelStrength = Fresnel(surface.ior ,surface.normal, surface.viewDirection);

float3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
reflection /= brdf.roughness * brdf.roughness + 1.0;

return (diffuse * brdf.diffuse + reflection) * surface.occlusion;
}

float3 DirectBRDF (Surface surface, BRDF brdf, Light light) {
	float NoL = dot(surface.normal, light.direction);
	float NoV = dot(surface.normal, surface.viewDirection);

	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float NoH = dot(surface.normal, h);
	float LoH = dot(light.direction, h);
	float LoV = dot(light.direction, surface.viewDirection);

	float3 energyCompensation = 1.0 + NoL * (1.0 / (1.1 - brdf.roughness) - 1.0);
	float fresnel = Fresnel(IORtoF0(surface.ior), surface.normal, surface.viewDirection);

	//float3 diffuse = brdf.diffuse * (1.0f / dot(float3(0.3f, 0.6f, 1.0f), brdf.diffuse)) * saturate((LoV * fresnel + NoL) * light.color);

	//float D = distributionCloth(roughness, NoH);
	//float V = visibilityCloth(NoV, NoL);

	float Cdlum = 0.3 * surface.color.r + 0.6 * surface.color.g + 0.1 * surface.color.b;
	float3 Ctint = surface.color / Cdlum;

	float3 Fr = (CharlieSheen(brdf.roughness, NoH)) * Ctint;

	float3 diffuse = saturate((dot(surface.normal, light.color) + 0.5) / 2.25);

	float3 Fd = diffuse * disneyDiffuse(NoV, NoL, LoH, brdf.roughness);

	Fd *= saturate(float3(0.8, 0.3, 0.2) + NoL);
	float3 color = Fd + Fr * NoL;
	color *= (1 * light.attenuation) * light.color;


	return Ashikhmin(NoL, NoV) * brdf.specular * SpecularStrength(surface, brdf, light) * energyCompensation * color;
}

#endif


