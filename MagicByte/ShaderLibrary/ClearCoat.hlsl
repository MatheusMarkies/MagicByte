#ifndef CLEARCOAT_INCLUDED
#define CLEARCOAT_INCLUDED
#include "../ShaderLibrary/Simplex3D.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"
#include "../ShaderLibrary/Common.hlsl"

//float4 sparkleSurface(int qtn,float4 noiseTexture, float4 noiseTexture2, float4 color,float3 NLdot) {
//
//	float4 SparkleTex = float4(0, 0, 0, 1);
//	float sparkle = 0;
//
//	for (int i = 0; i < qtn; i++) {
//	sparkle += (pow(noiseTexture + noiseTexture2,i + 5) + pow(noiseTexture + noiseTexture2, i + 5))*lerp(0.4996,1, NLdot);
//    }
//	SparkleTex.rgb = ((sparkle + sparkle) * color);
//
//	return SparkleTex;
//}

float Sparkles(float3 viewDir, float3 wPos,float _SparkleDepth, float _AnimSpeed, float _NoiseScale,float4 Time)
{
	float noiseScale = _NoiseScale * 1000;
	float sparkles = snoise(wPos * noiseScale + viewDir * _SparkleDepth - Time.x * _AnimSpeed) * snoise(wPos * noiseScale + Time.x * _AnimSpeed);
	sparkles = smoothstep(.5, .6, sparkles);
	return sparkles;
}

float SparklesMult(float3 viewDir, float3 wPos, float _SparkleDepth, float _AnimSpeed, float _NoiseScale, float4 Time,int i)
{
	float noiseScale = _NoiseScale * 10;
	float sparkles = 0;
	for (int o = 0; o < i; o++) {
		sparkles += snoise(wPos * noiseScale + viewDir * _SparkleDepth - Time.x * _AnimSpeed) * snoise(wPos * noiseScale + Time.x * _AnimSpeed);
	}
	sparkles = smoothstep(.5, .6, sparkles);
	return sparkles;
}

float3 getSurfaceClearCoat(float4 microFlakes,float clearCoat,float clearCoatRoughness,Surface surface,GI gi,Light light){

float3 np = microFlakes.rgb;

float NoV = dot(surface.normal, surface.viewDirection);
float3 coatReflection = 2 * surface.normal * NoV - surface.viewDirection;

float3 envMap = gi.reflect;
float3 npWorld =  mul(surface.normal, np);
//float fresnel = (saturate(dot(npWorld, surface.viewDirection))) * clearCoat;

float fresnel = FresnelBRDF(surface);

float fresnelSqr = fresnel * fresnel;

float3 paintColor = fresnel * (fresnelSqr + pow(fresnel, 16)) * microFlakes.rgb;

float envContribution = 1.0 - 0.5 * NoV;

return (envMap * clearCoatRoughness * envContribution) + paintColor;
}

#endif