Shader "Magic Byte/Water" {
	/*
	These properties can be edited.
    The properties below are connected with Magic Byte's Default LitInput, adding a new one you will also have to add it to the Shader Pass.
	*/
	Properties {
		[HideInInspector] _BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.83, 0.83, 0.83, 1.0)
		[HideInInspector]_SubSurfaceColor("Sub Surface Color", Color) = (0.8, 0.43, 0.2, 1.0)

		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping("Alpha Clipping", Float) = 0
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows("Receive Shadows", Float) = 1

		[HideInInspector]_Depth("Depth", Float) = 1

		[HideInInspector][KeywordEnum(On, Clip, Dither, Off)] _Shadows("Shadows", Float) = 0

		[HideInInspector]_Metallic("Metallic", Range(0, 1)) = 0.88
		[HideInInspector]_Smoothness("Smoothness", Range(0, 1)) = 1.0

		_WaveColor("Wave Color", Color) = (0.83, 0.83, 0.83, 1.0)

		_WaveMap("Wave Map", 2D) = "white" {}
		_WaveHeight("Wave Height", Float) = 1
		_WaveScale("Wave Scale", Float) = 1
		_WaveSpeed("Wave Speed", Vector) = (1, 1, 0, 0)

		_Occlusion("Occlusion", Range(0, 1)) = 1

		[HideInInspector]_Sheen("Sheen", Range(0, 1)) = 0
		[HideInInspector]_SheenTint("Sheen Tint", Range(0, 1)) = 0
		[HideInInspector]_SubSurface("Sub Surface", Range(0, 1)) = 0
		[HideInInspector]_Anisotropic("Anisotropic", Range(-0.95,0.95)) = 0.0
		[HideInInspector]_Transmission("Transmission", Range(0,1)) = 0.0

		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

		[NoScaleOffset] _NormalMap("Main Normal", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Range(0, 1)) = 1
		_TillingNormal("Tilling Normal", Vector) = (1, 1, 0, 0)
		_MainNormalSpeed("Normal Speed", Vector) = (1, 1, 0, 0)

		[NoScaleOffset] _OtherNormalMap("Second Normal", 2D) = "bump" {}
		_OtherNormalStrength("Second Normal Strength", Range(0, 1)) = 1
		_SecondTillingNormal("Second Tilling Normal", Vector) = (1, 1, 0, 0)
		_SecondNormalSpeed("Second Normal Speed", Vector) = (1, 1, 0, 0)

		_IOR("IOR", Range(0, 1)) = 0.1

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
			#include "WaterPass.hlsl" //Enter the name of your Pass file
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