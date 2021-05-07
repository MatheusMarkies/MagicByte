Shader "Hidden/Bloom"
{
    Properties
    {
        //_MainTexCamera ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        ZTest Always Cull Off ZWrite Off

        HLSLINCLUDE
        #include "../../ShaderLibrary/Common.hlsl"
        ENDHLSL

        Pass {
            Name "Copy"

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment CopyPassFragment
            #include "Bloom.hlsl"
            ENDHLSL
        }
        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment frag
            #include "Bloom.hlsl"
            ENDHLSL
         }
                Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment BloomHorizontalPassFragment
            #include "Bloom.hlsl"
            ENDHLSL
         }
                        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment BloomVerticalPassFragment
            #include "Bloom.hlsl"
            ENDHLSL
         }
                                Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment BloomCombinePassFragment
            #include "Bloom.hlsl"
            ENDHLSL
         }
        //Pass
        //{
        //    HLSLPROGRAM
        //    #pragma target 3.5
        //    #pragma vertex DefaultPassVertex
        //    #pragma fragment BloomPrefilterPassFragment 
        //    #include "Bloom.hlsl"
        //    ENDHLSL
        // }
    }
}


