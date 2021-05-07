Shader "Magic Byte/Water" {
	
	Properties {
		
		_BaseColor("Water Color",Color) = (0, 0, 0, 1)
		_WaterBlendColor("Water Blend Color",Color) = (0, 0, 0, 1)
		_WaterDistanceColor("Water Blend Color",Color) = (0, 0, 0, 1)

		[NoScaleOffset] _HeightMap("Wave HeightMap",2D) = "white" {}


		[NoScaleOffset] _Normal("Main Wave Normal",2D) = "bump" {}

		_NormalStrength("Normal Strength",Range(0, 1)) = 1
		_NormalSpeed("Normal Speed",Vector) = (0.5,0,0,0)
		_NormalSize("Normal Size",Float) = 2

		[HideInInspector] _Metallic("Metallic",Range(0, 1)) = 1
		[HideInInspector] _Smoothness("Smoothness",Range(0, 1)) = 1

		//_chromaticAberrationUV("Chromatic Aberration UV", Range(0, 0.05)) = 0

		[NoScaleOffset] _NormalSecond("Second Wave Normal",2D) = "bump" {}

		_DetailNormalStrength("Second Normal Strength",Range(0, 1)) = 1
		_NormalSecondSpeed("Second Normal Speed",Vector) = (0,0.5,0,0)
		_NormalSecondSize("Second Normal Size",Float) = 2

		[NoScaleOffset] _Emission("Emission",2D) = "white" {}
        [HDR] _EmissionColor("Emission Color",Color) = (0, 0, 1, 1)
        _Refraction("Refraction", Range(0,1)) = 0.7
		_Fresnel("Reflectance", Range(0,1)) = 0.8

  		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
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
			#include "WaterPass.hlsl"
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