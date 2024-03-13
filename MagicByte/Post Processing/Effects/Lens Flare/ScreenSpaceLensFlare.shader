Shader "Hidden/ScreenSpaceLensFlare"
{
    Properties{}
        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        ZTest Always Cull Off ZWrite Off

        HLSLINCLUDE
        #include "../../../ShaderLibrary/Common.hlsl"
        ENDHLSL

        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment Threshold
            #include "ScreenSpaceLensFlare.hlsl"
            ENDHLSL
        }

        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment FragBox
            #include "ScreenSpaceLensFlare.hlsl"
            ENDHLSL
        }
        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment FragHBlur
            #include "ScreenSpaceLensFlare.hlsl"
            ENDHLSL
        }
        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment FragVBlur
            #include "ScreenSpaceLensFlare.hlsl"
            ENDHLSL
        }
        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment FragRadialWarp
            #include "ScreenSpaceLensFlare.hlsl"
            ENDHLSL
        }
        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment FragGhost
            #include "ScreenSpaceLensFlare.hlsl"
            ENDHLSL
        }
        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment Composite
            #include "ScreenSpaceLensFlare.hlsl"
            ENDHLSL
        }

    }
}