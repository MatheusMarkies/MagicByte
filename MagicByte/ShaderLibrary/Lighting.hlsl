#ifndef LIGHTING_INCLUDED
#define LIGHTING_INCLUDED

#include "../../ShaderLibrary/ColorFunction.hlsl"
#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/IndirectBRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"

//float3 IncomingLight(Surface surface, Light light) {
//	float3 color = float3(1, 1, 1);
//	if (light.scatteringBorders > 0) {
//
//		float3 hsv = RGBtoHSV(light.color);//HSV
//		hsv.x = gmod(hsv.x + -0.02, 1);//Add HUE
//		hsv.yz *= float2(light.scatteringBorders, 1);//Add Saturation
//		float3 LightColor = saturate(HSVtoRGB(hsv));//RGB
//		LightColor = pow(LightColor, 1.3);
//		LightColor *= 3;
//		LightColor *= pow(0.7, light.attenuation);
//		color = lerp(float3(1, 1, 1), LightColor * 2, (1 - light.attenuation) * 0.7) * 0.5;
//	}
//	else {
//		color = light.color;
//		return saturate(dot(surface.normal, light.direction) * light.attenuation) * light.color;
//	}
//
//	return saturate(dot(surface.normal, light.direction) * light.attenuation) * lerp(light.color,color,light.scatteringBorders);
//}

float3 IncomingLight(Surface surface, Light light) {
	float3 color = float3(1, 1, 1);
	color = light.color;
	return saturate(dot(surface.normal, light.direction) * light.attenuation) * lerp(light.color, color, light.scatteringBorders);
}

float3 getLighting(Surface surfaceWS, BRDF brdf, GI gi) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = lerp(gi.refract, indirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular, surfaceWS.ior), surfaceWS.alpha);

	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);

		float3 lightDir = light.direction + surfaceWS.normal;
		float3 translucency = (pow(saturate(dot(surfaceWS.viewDirection, -lightDir)), 1) * surfaceWS.scatteringScale + gi.diffuse * 1) * light.attenuation;
		color += surfaceWS.color * light.color * translucency * (1 - surfaceWS.metallic);
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);

		float3 lightDir = light.direction + surfaceWS.normal;
		float3 translucency = (pow(saturate(dot(surfaceWS.viewDirection, -lightDir)), 1) * surfaceWS.scatteringScale + gi.diffuse * 1) * light.attenuation;
		color += surfaceWS.color * light.color * translucency * (1 - surfaceWS.metallic);
	}

	return color;
}

#endif