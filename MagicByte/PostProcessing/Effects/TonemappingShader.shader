Shader "Hidden/TonemappingShader"
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
            #include "../../ShaderLibrary/ColorFunction.hlsl"

            TEXTURE2D(_PostFXSource);
            SAMPLER(sampler_PostFXSource);

            float _usePathTracing = 0;
            TEXTURE2D(_PathTracingFrame);
            SAMPLER(sampler_PathTracingFrame);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 fxUV : VAR_FX_UV;
            };

            Varyings DefaultPassVertex(uint vertexID : SV_VertexID) {
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
                return output;
            }

           float3 _HSV;
           float _Exposure = 1.84442666;
           int _Tone = 1;
           float _Gamma = 1;
           float _Contrast = 1;
           float3 _WhiteBalance;

           float _RedMultiply;
           float _GreenMultiply;
           float _BlueMultiply;

float3 ACESFilm(float3 color)
{
    color *= _Exposure;

    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return saturate((color*(a*color+b))/(color*(c*color+d)+e));
}

float3 linearT(float3 color)
{
	color = clamp(_Exposure * color, 0.0, 1.0);
	return color;
}

float3 simpleReinhard(float3 color)
{
	color *= _Exposure/(1.0 + color / _Exposure);
	return color;
}
float POWER2 (float a){
    return a*a;
}
float3 lumaBasedReinhard(float3 color)
{
    float luma = sqrt(dot(color, float3(POWER2(0.299), POWER2(0.587), POWER2(0.114))));//GetLuminance 
	float toneMappedLuma = luma / (1.0 + luma);
	color *= toneMappedLuma / luma;
	return color * _Exposure;
}

half3 Photographic(float3 color)
{
    color *= _Exposure;
    return 1.0 - exp2(-color);
}

float3 whitePreservingLuma(float3 color)
{
    color*= _Exposure;
	float white = 2.;
	float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1.0 + luma / (white*white)) / (1.0 + luma);
	color *= toneMappedLuma / luma;
	return color;
}

//float3 filmic(float3 color)
//{
//    color *= _Exposure;
//	color = max(float3(0.0,0.0,0.0), color - float3(0.004,0.004,0.004));
//	color = (color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06);
//	return color;
//}

float3 filmic(float3 x) {
    return x / (x + 0.17) * 1.019;
}

float3 Gray(float3 color) {
    float gray = dot(color, float3(0.2126, 0.7152, 0.0722));
    return float3(gray, gray, gray);
}

float4 GetSource(float2 fxUV) {
    return SAMPLE_TEXTURE2D(_PostFXSource, sampler_PostFXSource, fxUV);
}
float4 GetSourcePathTracing(float2 fxUV) {
    return SAMPLE_TEXTURE2D(_PathTracingFrame, sampler_PathTracingFrame, fxUV);
}
float4 frag (Varyings i) : SV_Target
{

                float4 color = GetSource(i.fxUV);

                if (_usePathTracing == 1)
                    color = GetSourcePathTracing(i.fxUV);

                float3 hsv = RGBtoHSV(color.rgb);
                hsv.x = gmod(hsv.x + _HSV.x, 1.0);
                hsv.yz *= _HSV.yz;
                color.rgb = saturate(HSVtoRGB(hsv));

                		if (_Tone == 1) color.rgb = linearT(color.rgb);
		                if (_Tone == 2) color.rgb = simpleReinhard(color.rgb);
		                if (_Tone == 3) color.rgb = lumaBasedReinhard(color.rgb);
                        if (_Tone == 4) color.rgb = Photographic(color.rgb);
		                if (_Tone == 5) color.rgb = whitePreservingLuma(color.rgb);		
		                if (_Tone == 6) color.rgb = filmic(color.rgb);
                        if (_Tone == 7) color.rgb = ACESFilm(color.rgb);
                        if (_Tone == 8) color.rgb = Gray(color.rgb);

                color.rgb = pow(color.rgb,_Gamma);

                half3 lms = mul(LIN_2_LMS_MAT, color.rgb);
                lms *= _WhiteBalance;
                color.rgb = mul(LMS_2_LIN_MAT, lms);

                color.rgb = saturate((color.rgb - 0.5) * _Contrast + 0.5);

                color.r *= _RedMultiply;
                color.g *= _GreenMultiply;
                color.b *= _BlueMultiply;

                return color;
            }
            ENDHLSL
        }
    }
}
