Shader "Hidden/Denoiser"
{
    Properties
    {
        //_MainTexCamera ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        ZTest Always Cull Off ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        HLSLINCLUDE
        #include "../../ShaderLibrary/Common.hlsl"
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFrag

            #include "../../ShaderLibrary/UnityInput.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f LitPassVertex(appdata v)
            {
                v2f o;
                o.vertex = TransformWorldToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float _Sample;
            float4 LitPassFrag(v2f i) : SV_Target
            {
            return float4(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv).rgb, 1.0f / (_Sample + 1.0f));
            }

            ENDHLSL
        }
    }
}
