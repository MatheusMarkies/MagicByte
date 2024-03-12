Shader "Magic Byte/Cloth" {
	
	Properties {
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
		[KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0
	    _AlphaMap("Alpha", 2D) = "white" {}
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Occlusion ("Occlusion", Range(0, 1)) = 1
		_DetailMap ( "Detail" , 2D ) = "linearGrey" {}
		_DetailAlbedo("Detail Albedo", Range(0, 1)) = 1
		[NoScaleOffset] _OcclusionMap("Occlusion Map(AO)", 2D) = "white" {}
		[Enum(Smoothness, 0, Roughness, 1)] _UseRoughness("Smoothness/Roughness", Float) = 0
		[NoScaleOffset] _SmoothnessMap("Smoothness Map(Specular)", 2D) = "white" {}
		[NoScaleOffset] _MetalMap("Metallic Map", 2D) = "white" {}
		_Scattering("Scattering",Range(0,1))=1
		//[NoScaleOffset] _DetailSmoothness("Detail Smoothness", Range(0, 1)) = 1
		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Range(0, 1)) = 1

		[NoScaleOffset] _DetailNormalMap("Detail Normals", 2D) = "bump" {}
		_DetailNormalStrength("Detail Normal Strength", Range(0, 1)) = 1
		_DetailNormalTile("Detail Normal Tile", Float) = 1

		[Enum(Off, 0, On, 1)] _Scattering("Scattering", Float) = 1
        [NoScaleOffset] _ScatteringMask("Scattering Mask", 2D) = "white" {}
		_ScatteringAmplitude("Scattering Amplitude",Float) = 1
		_ScatteringScale("Scattering Scale",Float) = 0.03

		//_AnisotropicX("AnisotropicX", Range(-1,1)) = 0.0
		//_AnisotropicY("AnisotropicY", Range(-1,1)) = 0.0
		_Fresnel("Reflectance", Range(0,1)) = 0.0

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _PREMULTIPLY_ALPHA("PREMULTIPLY ALPHA", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
			
		[HideInInspector] _MainTex("Lightmap Texture", 2D) = "white" {}
		[HideInInspector] _Color("Lightmap Color", Color) = (0.5, 0.5, 0.5, 1.0)
	}
	
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
			#include "ClothPass.hlsl"
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