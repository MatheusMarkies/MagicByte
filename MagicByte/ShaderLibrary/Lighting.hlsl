#ifndef LIGHTING_INCLUDED
#define LIGHTING_INCLUDED

#include "../../ShaderLibrary/ColorFunction.hlsl"
#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/HairBRDF.hlsl"

float3 IncomingLight(Surface surface, Light light) {
	float3 color = float3(1, 1, 1);
	if (light.scatteringBorders > 0) {

		float3 hsv = RGBtoHSV(light.color);//HSV
		hsv.x = gmod(hsv.x + -0.02, 1);//Add HUE
		hsv.yz *= float2(light.scatteringBorders, 1);//Add Saturation
		float3 LightColor = saturate(HSVtoRGB(hsv));//RGB
		LightColor = pow(LightColor, 1.3);
		LightColor *= 3;
		LightColor *= pow(0.7, light.attenuation);
		color = lerp(float3(1, 1, 1), LightColor * 2, (1 - light.attenuation) * 0.7) * 0.5;
	}
	else {
		color = light.color;
		return saturate(dot(surface.normal, light.direction) * light.attenuation) * light.color;
	}

	//return saturate(dot(surface.normal, light.direction) * light.attenuation) * (light.color + (color * light.scatteringBorders));
	return saturate(dot(surface.normal, light.direction) * light.attenuation) * lerp(light.color,color,light.scatteringBorders);
}

float3 GetLighting(Surface surface, Light light) {
	return IncomingLight(surface, light);
}

//float3 GetLighting(Surface surfaceWS, GI gi) {
//	ShadowData shadowData = GetShadowData(surfaceWS);
//	shadowData.shadowMask = gi.shadowMask;
//
//	float3 color = (0, 0, 0);
//	for (int i = 0; i < GetDirectionalLightCount(); i++) {
//		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
//		color += GetLighting(surfaceWS, light);
//	}
//
//	for (int j = 0; j < GetOtherLightCount(); j++) {
//		Light light = GetOtherLight(j, surfaceWS, shadowData);
//		color += GetLighting(surfaceWS, light);
//	}
//
//	return color;
//}

///////////////////////////////////////////////////////////////
//
// HAIR
//
///////////////////////////////////////////////////////////////

float3 GetLightingHair(Surface surface, BRDF brdf, Light light, float3 specularColor1, float3 specularColor2, float exp1, float exp2, float specularIntensity,float3 ramp) {
	return IncomingLight(surface, light) * DirectHairBRDF(surface, brdf, light, specularColor1, specularColor2, exp1, exp2, specularIntensity, ramp);
}

///////////////////////////////////////////////////////////////
//
// SURFACE SCATTERING
//
///////////////////////////////////////////////////////////////

float3 GetLightingScattering(Surface surface, BRDF brdf, Light light) {
	return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

float3 GetLightingScattering(Surface surfaceWS, BRDF brdf, GI gi, int Alpha) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha))));
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha))));
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	return color;
}

float3 GetLightingScatteringFresnel(Surface surfaceWS, BRDF brdf, GI gi, int Alpha, float fresnel) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))) * Fresnel(fresnel, surfaceWS.normal, surfaceWS.viewDirection);
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))) * Fresnel(fresnel, surfaceWS.normal, surfaceWS.viewDirection);
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	return color;
}

float3 GetLightingScattering(Surface surfaceWS, BRDF brdf, GI gi, int Alpha, float ScatteringMask) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))) * ScatteringMask;
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))) * ScatteringMask;
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	return color;
}
float3 GetLightingScattering(Surface surfaceWS, BRDF brdf, GI gi, int Alpha, float power, float scale) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = pow(saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))), power) * scale;
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = pow(saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))), power) * scale;
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	return color;
}

float3 GetLightingScattering(Surface surfaceWS, BRDF brdf, GI gi, int Alpha, float power, float scale, float ScatteringMask) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = pow(saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))), power) * scale * ScatteringMask;
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLightingScattering(surfaceWS, brdf, light);
		float scattering = pow(saturate(dot(surfaceWS.viewDirection, -(normalize(light.direction + surfaceWS.normal * Alpha)))), power) * scale * ScatteringMask;
		color += scattering * (light.color * 1.5) + surfaceWS.color * scattering;
	}

	return color;
}


///////////////////////////////////////////////////////////////
//
// ANISOTROPIC
//
///////////////////////////////////////////////////////////////

//float3 GetLightingAniso(Surface surfaceWS, BRDF brdf, GI gi) {
//	ShadowData shadowData = GetShadowData(surfaceWS);
//	shadowData.shadowMask = gi.shadowMask;
//
//	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
//	for (int i = 0; i < GetDirectionalLightCount(); i++) {
//		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
//		color += GetLighting(surfaceWS, light);
//	}
//
//	for (int j = 0; j < GetOtherLightCount(); j++) {
//		Light light = GetOtherLight(j, surfaceWS, shadowData);
//		color += GetLighting(surfaceWS, light);
//	}
//
//	return color;
//}
//
//float3 GetLighting(Surface surfaceWS, BRDF brdf) {
//	ShadowData shadowData = GetShadowData(surfaceWS);
//
//	float3 color = 0;
//	for (int i = 0; i < GetDirectionalLightCount(); i++) {
//		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
//		color += GetLighting(surfaceWS, brdf, light);
//	}
//
//	for (int j = 0; j < GetOtherLightCount(); j++) {
//		Light light = GetOtherLight(j, surfaceWS, shadowData);
//		color += GetLighting(surfaceWS, brdf, light);
//	}
//
//	return color;
//}

///////////////////////////////////////////////////////////////
//
// IRIDESCENCE
//
///////////////////////////////////////////////////////////////

//float3 GetLightingIridescence(Surface surface, BRDF brdf, Light light, float iridescenceThickness) {
//	return IncomingLight(surface, light) * DirectIridescenceBRDF(surface, brdf, light, iridescenceThickness);
//}
//
//float3 GetLightingIridescence(Surface surfaceWS, BRDF brdf, GI gi, float iridescenceThickness) {
//	ShadowData shadowData = GetShadowData(surfaceWS);
//	shadowData.shadowMask = gi.shadowMask;
//
//	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
//	for (int i = 0; i < GetDirectionalLightCount(); i++) {
//		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
//		color += GetLightingIridescence(surfaceWS, brdf, light, iridescenceThickness);
//	}
//	return color;
//}

#endif