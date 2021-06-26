Shader "Hidden/ScreenSpaceLensFlare"
{
    Properties{}
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        ZTest Always Cull Off ZWrite Off

        HLSLINCLUDE
        #include "../../ShaderLibrary/Common.hlsl"
        ENDHLSL

        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment thresholder
            #include "ScreamSpaceLensFlare.hlsl"
            ENDHLSL
        }
        Pass{
            HLSLPROGRAM
            #pragma target 3.5
                #pragma vertex DefaultPassVertex
                #pragma fragment ghostPass
            #include "ScreamSpaceLensFlare.hlsl"
            ENDHLSL
        }
               
    }
}