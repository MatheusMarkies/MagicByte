Shader "Magic Byte/Fur" {
	
	Properties {
		_FurColor("Fur Color",2D) = "white" {}
		_FurLength("Fur Length",Range(0,1)) = 1
		_FurThinness("Fur Thinness", Float) = 1

		_FurThinness("Gravity", Vector) = (0,0,0)

		_Cutoff("Alpha Cutoff", Range(0, 1.0)) = 1

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
	}

		SubShader{
			HLSLINCLUDE
			#include "../../ShaderLibrary/Common.hlsl"
			#include "../../ShaderLibrary/UnityInput.hlsl"
			#include "../LitInput.hlsl"
			ENDHLSL

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

			float _FurLength;
			float FurShell = 0.1 * 1;

			#include "FurPass.hlsl"
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
				float _FurLength = 1;
			float FurShell = 0.1 *2;

			#include "FurPass.hlsl"
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
				float _FurLength;
			float FurShell = 0.1 *3;

			#include "FurPass.hlsl"
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
				float _FurLength;
			float FurShell = 0.1 *4;

			#include "FurPass.hlsl"
			ENDHLSL
		}
				Pass{
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
float _FurLength;
float FurShell = 0.1 *5;

#include "FurPass.hlsl"
ENDHLSL
			}
				Pass{
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
	float _FurLength;
float FurShell = 0.1 *6;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *7;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *8;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *9;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *10;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *11;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *12;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *13;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *14;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *15;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *16;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *17;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *18;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *19;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *20;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *21;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *22;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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
	float _FurLength;
float FurShell = 0.1 *23;

#include "FurPass.hlsl"
ENDHLSL
}
Pass{
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

float FurShell = 0.1 *24;

#include "FurPass.hlsl"
ENDHLSL
}

		//Pass {
		//	Tags {
		//		"LightMode" = "ShadowCaster"
		//	}

		//	ColorMask 0

		//	HLSLPROGRAM
		//	#pragma target 3.5
		//	#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
		//	#pragma multi_compile_instancing
		//	#pragma multi_compile _ LOD_FADE_CROSSFADE
		//	#pragma vertex ShadowCasterPassVertex
		//	#pragma fragment ShadowCasterPassFragment
		//	#include "../../ShadowCasterPass.hlsl"
		//	ENDHLSL
		//}

		//Pass {
		//	Tags {
		//		"LightMode" = "Meta"
		//	}

		//	Cull Off

		//	HLSLPROGRAM
		//	#pragma target 3.5
		//	#pragma vertex MetaPassVertex
		//	#pragma fragment MetaPassFragment
		//	#include "../MetaPass.hlsl"
		//	ENDHLSL
		//}
	
	}

}