#ifndef GRASS_PASS_INCLUDED
#define GRASS_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/ClearCoat.hlsl"

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 baseUV : TEXCOORD0;
	GI_ATTRIBUTE_DATA
		UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS : VAR_NORMAL;
	float4 tangentWS : VAR_TANGENT;
	float2 baseUV : VAR_BASE_UV;
	float2 detailUV : VAR_DETAIL_UV;
	GI_VARYINGS_DATA
		UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex(Attributes input) {
	Varyings output;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
	output.baseUV = TransformBaseUV(input.baseUV);
	output.detailUV = TransformDetailUV(input.baseUV);

	return output;
}

float3 GetLighting(Surface surface, BRDF brdf, Light light) {
	return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

float3 GetLighting(Surface surfaceWS, BRDF brdf, GI gi) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;

	float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}

	return color;
}

float3 GetLightingGlass(Surface surfaceWS, BRDF brdf, GI gi) {
	ShadowData shadowData = GetShadowData(surfaceWS);
	shadowData.shadowMask = gi.shadowMask;
	float fresnel = Fresnel(surfaceWS.fresnelStrength, surfaceWS.normal, surfaceWS.viewDirection);
	float3 color = lerp(gi.refract, IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular), fresnel);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}

	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}

	return color;
}
//
//[maxvertexcount(3)]
//void LitPassGeometry(triangle Varyings IN[3], inout TriangleStream<g2f> triStream)
//{
//	g2f o;
//
//	float3 pos = IN[0].positionCS;
//	float3 vNormal = IN[0].normalWS;
//	float4 vTangent = IN[0].tangentWS;
//	float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;
//
//	float3x3 tangentToLocal = float3x3(
//		vTangent.x, vBinormal.x, vNormal.x,
//		vTangent.y, vBinormal.y, vNormal.y,
//		vTangent.z, vBinormal.z, vNormal.z
//		);
//
//	//TransformWorldToHClip
//	o.positionWS.rgb = TransformObjectToHClip(pos + mul(tangentToLocal, float3(0.5, 0, 0)));
//	triStream.Append(o);
//
//	o.positionWS.rgb = TransformObjectToHClip(pos + mul(tangentToLocal, float3(-0.5, 0, 0)));
//	triStream.Append(o);
//
//	o.positionWS.rgb = TransformObjectToHClip(pos + mul(tangentToLocal, float3(0, 1, 0)));
//	triStream.Append(o);
//}

struct g2f
{
	float4 vertex : SV_POSITION;
	float4 grassLeafColor : COLOR;
};

[maxvertexcount(4)]
void LitPassGeometry(triangle Varyings IN[3], inout TriangleStream<g2f> triStream) {

	float4 v0 = IN[0].positionCS;
	float4 v1 = IN[1].positionCS;
	float4 v2 = IN[2].positionCS;

	float3 n0 = IN[0].normalWS;
	float3 n1 = IN[1].normalWS;
	float3 n2 = IN[2].normalWS;

	float4x4 vp = GetWorldToHClipMatrix();

	////noise textures that increase variability between each blade
	////these could be all fused into a single texture but different channels, just think of the saving on the texture lookups
	//float randomHeight = (IN[0].grassHeight.r + IN[1].grassHeight.r + IN[2].grassHeight.r) / 3;
	//float randomWind = (IN[0].grassWind.r + IN[1].grassWind.r + IN[2].grassWind.r) / 3;
	//float randomAngle = (IN[0].grassOrientation.r + IN[1].grassOrientation.r + IN[2].grassOrientation.r) / 3;
	//float steppedValue = min(IN[0].grassStepped.r + IN[1].grassStepped.r + IN[2].grassStepped.r, 0.9);

	////center will be the bottom of each grass blade
	float4 center = (v0 + v1 + v2) / 3;
	////basicly the up vector
	float4 normal = float4((n0 + n1 + n2) / 3, 0) * 4;
	////basicly the bottom vector that defines both the width and the orientation of the triangle/blade
	float4 tangent = IN[0].tangentWS;//mul((center - v0) * 2, rotationMatrix(normal, 1 * 3.14159 * 2));

	//normal = mul(normal, rotationMatrix(tangent, steppedValue * HALF_PI)) + tangent * sin((center.x + center.z + randomWind + _Time) * _WindSpeed);

	//first tri
	g2f pIn;

	pIn.vertex = mul(vp, center + tangent);
	pIn.grassLeafColor = float4(0, 0, 0, 1);
	triStream.Append(pIn);

	pIn.vertex = mul(vp, center - tangent);
	pIn.grassLeafColor = float4(0, 0, 0, 1);
	triStream.Append(pIn);

	//top vertex of the triangle, multiply the normal vector with a rotation matrix create with the crush texture map
	//also add a sideways vector and multiply it with a sin function in order to animate wind
	pIn.vertex = mul(vp, center + normal);
	pIn.grassLeafColor = float4(0, 0, 0, 1);
	triStream.Append(pIn);

	//second tri for backface visibility, taking advantage of tri strip

	pIn.vertex = mul(vp, center + tangent);
	pIn.grassLeafColor = float4(0, 0, 0, 1);
	triStream.Append(pIn);
	triStream.RestartStrip();

}

float4 LitPassFragment(g2f input) : SV_TARGET{
UNITY_SETUP_INSTANCE_ID(input);

float3 finalColor = (0, 0, 0);
	
//Surface grass;
//
//grass.position = input.positionWS;
//
//float2 NormalUV = input.baseUV;
//
//float4 Nmap = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, NormalUV);
//float scale = 1;// UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalStrength);
//float3 normalMain = DecodeNormal(Nmap, scale);
//
//grass.metallic = 1;
//grass.smoothness = 1;
//
//float3 normal = normalMain;
//
//grass.normal = NormalTangentToWorld(normal, input.normalWS, input.tangentWS);
//grass.viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);
//
//grass.fresnelStrength = 1;//UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Fresnel);
//grass.color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV);// *UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
//
//grass.interpolatedNormal = input.normalWS;
//
//grass.depth = -TransformWorldToView(input.positionWS).z;
//grass.tangent = input.tangentWS;
//grass.binormal = cross(NormalTangentToWorld(normal, input.normalWS, input.tangentWS), input.tangentWS.xyz) * input.tangentWS.w;
//
//grass.occlusion = 1;
//grass.dither = 1;
//grass.anisotropic = 0;
//
//BRDF brdf = GetBRDF(grass);
//GI gi = GetGI(GI_FRAGMENT_DATA(input), grass, brdf);
//finalColor = GetLighting(grass, brdf, gi);
//
//float4 EmissionMap = SAMPLE_TEXTURE2D(_Emission, sampler_Emission, input.baseUV);
//float4 Ecolor = float4(1, 1, 1, 1);// UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
//finalColor += EmissionMap.rgb * Ecolor;

return float4(finalColor, 1);
}

#endif