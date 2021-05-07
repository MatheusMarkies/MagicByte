Shader "Hidden/Raymarching"
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

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment frag

            #include "../../ShaderLibrary/UnityInput.hlsl"

            TEXTURE2D(_PostFXSource);
            SAMPLER(sampler_PostFXSource);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 fxUV : VAR_FX_UV;
                float3 ray : TEXCOORD1;
            };

            float4 CameraWorldPosition;
            float4x4 CameraCorners;
            float4x4 CameraToWorld;
            float4 CameraPosition;

            sampler2D _CameraGBufferTexture0; 
            sampler2D _CameraGBufferTexture1; 
            sampler2D _CameraGBufferTexture2; 
            sampler2D _CameraGBufferTexture3; 

            Varyings DefaultPassVertex(appdata i,uint vertexID : SV_VertexID) {
                Varyings output;
                output.positionCS = float4(
                    vertexID <= 1 ? -1.0 : 3.0,
                    vertexID == 1 ? 3.0 : -1.0,
                    0.0, 1.0
                    );
                output.fxUV = float2(
                    vertexID <= 1 ? 0.0 : 2.0,
                    vertexID == 1 ? 2.0 : 0.0
                    );
                if (_ProjectionParams.x < 0.0) {
                    output.fxUV.y = 1.0 - output.fxUV.y;
                }

                float index = i.vertex.z;

                output.ray = CameraCorners[(int)index];
                output.ray /= abs(output.ray.z);
                output.ray = mul(CameraToWorld, output.ray);


                return output;
            }


float4 GetSource(float2 fxUV) {
    return SAMPLE_TEXTURE2D(_PostFXSource, sampler_PostFXSource, fxUV);
}

float4 frag (Varyings i, 
    out half4 outDiffuse : COLOR0, 
    out half4 outSpecRoughness : COLOR1, 
    out half4 outNormal : COLOR2, 
    out half4 outEmission : COLOR3) : SV_Target
{
                float4 color = GetSource(i.fxUV);
                //float3 rayDirection = normalize(i.ray);
                //float3 raySource = CameraPosition.xyz;

                float4 View = outDiffuse;
                float4 Normal = outNormal;
                float4 ColorB = outDiffuse;
                float4 EmissiveColor = outEmission;

                float specular = outSpecRoughness.w;

                float3 reflected = normalize(reflect(normalize(View.rgb),normalize(Normal.rgb)));
                float3 hit = View.rgb;
                float depth;

                //color = float4(rayDirection,1);
                color = float4(reflected, 1);
                return color;
            }
            ENDHLSL
        }
    }
}
