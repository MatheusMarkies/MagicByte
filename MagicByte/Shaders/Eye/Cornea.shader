Shader "Hidden/Magic Byte/Eye/Cornea" {
	/*
	These properties can be edited.
    The properties below are connected with Magic Byte's Default LitInput, adding a new one you will also have to add it to the Shader Pass.
	*/
	Properties {
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.83, 0.83, 0.83, 1.0)

		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

		_NormalMap("Normals", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Range(0, 1)) = 1
		_TillingNormal("Tilling Normal", Vector) = (1, 1, 0, 0)

		_IOR("IOR", Range(0.1, 1)) = 0.1

			/*Usadas neste Shader */
		[HideInInspector] _ClearCoatRoughness("Coat Roughness", Range(0, 1)) = 1
		_ClearCoatFresnel("Coat Fresnel", Range(0.1, 1)) = 0.6
		_ClearCoat("ClearCoat Intensity", Range(0, 1)) = 1
			/*Usadas neste Shader */

		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		[HideInInspector][Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1

		[HideInInspector] _MainTex("Lightmap Texture", 2D) = "white" {}
		[HideInInspector] _Color("Lightmap Color", Color) = (0.5, 0.5, 0.5, 1.0)
	}
	
	/* Magic Byte Standard Surface:
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
	float clearCoatRoughness;
	float scatteringScale;
	*/

	SubShader {
		HLSLINCLUDE
		#include "../../ShaderLibrary/Common.hlsl"
		#include "../LitInput.hlsl"
		ENDHLSL

		Pass {
			Tags {
				"LightMode" = "Meta"
			}

			Cull Off

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex MetaPassVertex
			#pragma fragment MetaPassFragment
			#include "../MetaPass.hlsl"
			ENDHLSL
		}

		Pass {
			Tags {
				"LightMode" = "MBLit"
			}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _CLIPPING
			#pragma shader_feature _RECEIVE_SHADOWS
			#pragma shader_feature _PREMULTIPLY_ALPHA
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
			#pragma multi_compile _ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_instancing
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment
			#include "CorneaPass.hlsl" //Enter the name of your Pass file
			ENDHLSL
		}

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
			#include "../ShadowCasterPass.hlsl"
			ENDHLSL
		}


	}
}