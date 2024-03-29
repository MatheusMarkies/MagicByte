Shader "Hidden/AdditiveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            ZTest Always

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _PostFXSource;
            float4 _PostFXSource_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _PostFXSource);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            float _Sample;

            fixed4 frag (v2f i) : SV_Target
            {
            return float4(tex2D(_PostFXSource, i.uv).rgb, 1.0f / (_Sample + 1.0f));
            }
            ENDCG
        }
    }
}
