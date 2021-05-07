Shader "Magic Byte/SurfaceScattering" {
	
	Properties {
	    _BaseMap("Albedo", 2D) = "white" {}
		_BaseColor("Base Color",Color) = (0, 0, 1, 1)

		[Enum(Simple, 0, Mask, 1, Curve, 2)] _ScatteringMode("Scattering Mode", Float) = 2
		[NoScaleOffset] _ScatteringMask("Scattering Mask", 2D) = "white" {}
		_ScatteringAmplitude("Scattering Amplitude",Float) = 1
		_ScatteringScale("Scattering Scale",Float) = 2

		[NoScaleOffset] _Normal("Main Normal",2D) = "bump" {}
		_NormalStrength("Normal Strength",Range(0, 1)) = 1

		_Metallic("Metallic",Range(0, 1)) = 1
		_Smoothness("Smoothness",Range(0, 1)) = 0.97

		_Occlusion("Occlusion", Range(0, 1)) = 1
		_Fresnel("Fresnel",Range(0, 1.5)) = 1

		[NoScaleOffset] _DetailNormalMap("Detail Normal",2D) = "bump" {}
		_DetailNormalUV("Detail Normal UV",Float) = 4
		_DetailNormalStrength("Second Normal Strength",Range(0, 1)) = 1

		[NoScaleOffset] _OcclusionMap("Occlusion Map(AO)", 2D) = "white" {}
		[NoScaleOffset] _SmoothnessMap("Smoothness Map(Especular)", 2D) = "white" {}
		[NoScaleOffset] _MetalMap("Metallic Map", 2D) = "white" {}

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
	}
	
	SubShader {
		HLSLINCLUDE
		#include "../../ShaderLibrary/Common.hlsl"
		#include "../../ShaderLibrary/UnityInput.hlsl"
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

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

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
			#include "SurfaceScatteringPass.hlsl"
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