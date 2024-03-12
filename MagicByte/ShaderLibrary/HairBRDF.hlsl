#ifndef HAIRBRDF_INCLUDED
#define HAIRBRDF_INCLUDED
#include "../../ShaderLibrary/Iridescence.hlsl"
//#define PI 3.14159265359
#define MIN_REFLECTIVITY 0.04

#define MEDIUMP_FLT_MAX    65504.0
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

float strandSpecular(float3 T, float3 V, Light light, float exp) {
	float3 h = SafeNormalize(light.direction + V);
	float ToH = dot(T, h);
	float sinToH = sqrt(1- ToH * ToH);
	float dirAtt = smoothstep(-1, 0, ToH);
	return dirAtt * pow(sinToH,exp);
}

float3 HairSpecular(Surface surface, BRDF brdf, Light light, float3 specularColor1, float3 specularColor2,float exp1,float exp2,float3 ramp) {
	float3 tangent1 = shiftTangent(surface.tangent, surface.normal, 0.02);
	float3 tangent2 = shiftTangent(surface.tangent, surface.normal, 0.06);
	float3 tangent3 = shiftTangent(surface.tangent, surface.normal, 0.03);

	float NoL = dot(surface.normal, light.direction);
	float VoL = dot(surface.viewDirection, light.direction);
	float NoV = dot(surface.viewDirection, surface.normal);
	float fresnelF = Fresnel(surface.ior, surface.normal, surface.viewDirection);

	float3 specular = lerp(specularColor1, light.color, NoL) * specularColor1 * strandSpecular(tangent1, surface.viewDirection, light, exp1);
	specular += specularColor2 * strandSpecular(tangent3, surface.viewDirection, light, exp2 - 0.1);
	specular += specularColor2 * strandSpecular(tangent2, surface.viewDirection, light, exp2);

	return specular * ramp;
}

float3 DirectHairBRDF (Surface surface, BRDF brdf, Light light, float3 specularColor1, float3 specularColor2, float exp1, float exp2,float specularIntensity,float3 ramp) {

	float NoL = dot(surface.normal, light.direction);
	float3 energyCompensation = 1.0 + NoL * (1.0 / (1.1-brdf.roughness) - 1.0);
	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float LoH = dot(light.direction, h);
	float LoV = dot(light.direction, surface.viewDirection);

	float f90 = 0.5 + (brdf.perceptualRoughness + brdf.perceptualRoughness * LoV);

	float Rough2Max = max(brdf.roughness * brdf.roughness, 2.0e-3);
	float k = Rough2Max * 0.5f;
	float G_SmithL = NoL * (1.0f - k) + k;
	float G_SmithV = dot(surface.normal, surface.viewDirection) * (1.0f - k) + k;
	float G = 0.25f / (G_SmithL * G_SmithV);
	
	return HairSpecular(surface, brdf, light, specularColor1, specularColor2, exp1, exp2,ramp) * G * (energyCompensation * specularIntensity) + (1 / PI*disneyDiffuse(dot(surface.normal, surface.viewDirection), NoL, LoH, brdf.roughness) * brdf.diffuse) * FresnelBRDF(surface) + (1 / PI*brdf.diffuse);
}

#endif