﻿#ifndef COMMON_INCLUDED
#define COMMON_INCLUDED
//
#include "Core RP/ShaderDependencies/CommonMaterial.hlsl"
#include "Core RP/ShaderDependencies/Common.hlsl"
#include "UnityInput.hlsl"

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_P glstate_matrix_projection

#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
	#define SHADOWS_SHADOWMASK
#endif

#include "Core RP/ShaderDependencies/UnityInstancing.hlsl"
#include "Core RP/ShaderDependencies/SpaceTransforms.hlsl"
#include "Core RP/ShaderDependencies/Packing.hlsl"

float3 DecodeNormal (float4 sample, float scale) {
	#if defined(UNITY_NO_DXT5nm)
	    return UnpackNormalRGB(sample, scale);
	#else
	    return UnpackNormalmapRGorAG(sample, scale);
	#endif
}

float3 NormalTangentToWorld (float3 normalTS, float3 normalWS, float4 tangentWS) {
	float3x3 tangentToWorld =
		CreateTangentToWorld(normalWS, tangentWS.xyz, tangentWS.w);
	return TransformTangentToWorld(normalTS, tangentToWorld);
}

float Square (float x) {
	return x * x;
}

float DistanceSquared(float3 pA, float3 pB) {
	return dot(pA - pB, pA - pB);
}
float Pit(float A, float B) {
	return sqrt(A * A + B * B);
}

void ClipLOD (float2 positionCS, float fade) {
	#if defined(LOD_FADE_CROSSFADE)
		float dither = InterleavedGradientNoise(positionCS.xy, 0);
		clip(fade + (fade < 0.0 ? dither : -dither));
	#endif
}

float IORtoF0(float ior) {
	return ((ior - 1) * (ior - 1)) / ((ior + 1) * (ior + 1));
}

float Fresnel(float fresnelStrength, float3 normal,float3 viewDirection){
return fresnelStrength * Pow4(1.0 - saturate(dot(normal, viewDirection)));
}

float FresnelBRDF(float f0, float u)
{
	return f0 + (1 - f0) * pow(1 - u, 5);
}

#endif