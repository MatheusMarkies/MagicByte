#ifndef BRDF_INCLUDED
#define BRDF_INCLUDED

struct BRDF {
	float3 diffuse;
	float3 specular;
	float perceptualRoughness;
	float roughness;
	float fresnel;
};

//#define PI 3.14159265359
#define MIN_REFLECTIVITY 0.04

#define MEDIUMP_FLT_MAX    65504.0
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

float OneMinusReflectivity (float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

BRDF GetBRDF (Surface surface) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);

    brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

BRDF GetBRDF(Surface surface, bool PremultiplyAlpha) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity * surface.alpha;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
	
	brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}


float FresnelTransmissionBRDF(float f0, float f90, float u)
{
	real x = 1.0 - u;
	real x2 = x * x;
	real x5 = x * x2 * x2;
	return (1.0 - f90 * x5) - f0 * (1.0 - x5);
}

float FresnelTransmissionBRDF(float u)
{
	float m = clamp(1 - u, 0, 1);
	float m2 = m * m;
	return m2 * m2 * m; // pow(m,5)
}

//GGX
float SpecularStrength(Surface surface, BRDF brdf, Light light) {
	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float NoH = dot(surface.normal, h);
	float3 NxH = cross(surface.normal, h);
	float a = NoH * brdf.roughness;
	float k = brdf.roughness / (dot(NxH, NxH) + a * a);
	float d = k * k * (1.0 / PI);
	return saturateMediump(d);
}

float3 shiftTangent(float3 T, float3 N, float shift)
{
	return normalize((T + shift)*N);
}
//
//Anisotropy Surfaces
float SpecularStrengthAnisotropy(Surface surface, BRDF brdf, Light light) {
	float at = max(brdf.roughness * (1.0 + surface.anisotropic), 0.005);
	float ab = max(brdf.roughness * (1.0 - surface.anisotropic), 0.005);

	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float NoH = sqrt(1-dot(normalize(surface.normal), h)* dot(normalize(surface.normal), h));

	float ToH = dot(shiftTangent(normalize(surface.tangent), normalize(surface.normal), 0.1), h);

	float3 b = normalize(cross(normalize(surface.normal), surface.tangent));//normalize(cross(surface.normal, surface.tangent.xyz) * surface.tangent.w);

	float BoH = dot(b, h);
	float a2 = at * ab;
	float3 v = float3(ab * ToH, at * BoH, a2 * NoH);
	float v2 = dot(v, v);
	float w2 = a2 / v2;
	return a2 * w2 * w2 * (1.0 / PI);
}

////Fresnel BRDF
//float FresnelBRDF(Surface surface) {
//float NoV = dot(surface.normal, surface.viewDirection);
//float f = pow(1.0 - 0.3, 5.0);
//return f + NoV * (1.0 - f);
//}
//Fresnel Schlick
float FresnelBRDF(Surface surface) {
	float NoV = dot(surface.normal, surface.viewDirection);
	float f = pow(1.0 - NoV, 4.0);
	return f*0.5 + NoV * (1.0 - f) * surface.metallic;
}

float FresnelBRDF(float f0, float u)
{
	return f0 + (1 - f0) * pow(1 - u, 5);
}

float3 GammaController(float3 color)
{
	return float3(pow(color.r, 2.2), pow(color.g, 2.2), pow(color.b, 2.2));
}

float3 irradianceOclusion(float3 n) {
return unity_SHAr + unity_SHAg * (n.y) + unity_SHAb * (n.z) + unity_SHBr * (n.x) + unity_SHBg * (n.y * n.x) + unity_SHBb * (n.y * n.z) + unity_SHC * (3.0 * n.z * n.z - 1.0);
}

float3 IndirectBRDF (Surface surface, BRDF brdf, float3 diffuse, float3 specular){

float fresnelStrength = surface.ior * Pow4(1.0 - saturate(dot(surface.normal, surface.viewDirection)));

float3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);

reflection /= brdf.roughness * brdf.roughness + 1.0;

return (diffuse * (brdf.diffuse / PI) + reflection) * surface.occlusion;
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

float3 DirectBRDF (Surface surface, BRDF brdf, Light light) {

	float NoL = dot(surface.normal, light.direction);

	float3 energyCompensation = 1.0 + NoL * (1.0 / (1.1-brdf.roughness) - 1.0);

	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float LoH = dot(light.direction, h);
	float LoV = dot(light.direction, surface.viewDirection);
	float NoH = dot(surface.normal, h);

	float f90 = 0.5 + (brdf.perceptualRoughness + brdf.perceptualRoughness * LoV);

	//float Rough2Max = max(brdf.roughness * brdf.roughness, 2.0e-3);
	//float k = Rough2Max * 0.5f;
	//float G_SmithL = NoL * (1.0f - k) + k;
	//float G_SmithV = dot(surface.normal, surface.viewDirection) * (1.0f - k) + k;
	//float G = 0.25f / (G_SmithL * G_SmithV);
	float G = min(1.0, min(2 * NoH * dot(surface.normal, surface.viewDirection) / dot(surface.viewDirection, h), 2 * NoH * NoL / dot(surface.viewDirection,h))); 
	G *= 1 / (NoL * dot(surface.normal, surface.viewDirection));

	float fresnel = Fresnel(surface.ior, surface.normal, surface.viewDirection);
	float3 diffuse = brdf.diffuse * (1.0f / dot(float3(0.3f, 0.6f, 1.0f), brdf.diffuse)) * saturate((LoV * fresnel + NoL) * light.color);

	float f0 = pow((surface.ior) / (surface.ior + 2), 2);
	float F = FresnelBRDF(f0, LoH) * surface.occlusion;

	if (surface.anisotropic == 0) {
	return (1 / PI) * (SpecularStrength(surface, brdf, light)* G * (F * lerp(light.color*surface.color,brdf.specular,surface.metallic))) * energyCompensation + GammaController(brdf.diffuse);
	}
	else {
		return (1 / PI) * (SpecularStrengthAnisotropy(surface, brdf, light) * (F * brdf.specular * 1) * energyCompensation) + (disneyDiffuse(dot(surface.normal, surface.viewDirection), NoL, LoH, brdf.roughness) * brdf.diffuse);
	}
	//return HairSpecular(surface, brdf, light,float3(1,1,1),float3(0.5,0.5,0.5),7,88);//
}


#endif