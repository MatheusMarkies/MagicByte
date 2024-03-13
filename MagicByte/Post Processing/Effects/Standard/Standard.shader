Shader "Hidden/Standard"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        ZTest Always Cull Off ZWrite Off

        HLSLINCLUDE
        #include "../../../ShaderLibrary/Common.hlsl" //EDIT THIS VALUE TO MOVE FROM FOLDER
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment frag
            #include "StandardPass.hlsl"
            ENDHLSL
        }

    }
}
