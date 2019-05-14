Shader "Hidden/PostEffect/FXFastBloom"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

    SubShader
    {
        ZTest Always Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
                #pragma vertex VertDefault
                #pragma fragment FragPrefilter
            ENDCG
        }

        Pass
        {
            CGPROGRAM
                #pragma vertex VertDefault
                #pragma fragment FragDownsample
            ENDCG
        }

        Pass
        {
            CGPROGRAM
                #pragma vertex VertMultitex
                #pragma fragment FragUpsample
            ENDCG
        }
    }

    CGINCLUDE

	#pragma target 3.0
	#include "UnityCG.cginc"
	#include "AK47NewShader-Post-Bloom.cginc"
	#include "AK47NewShader-Post-Common.cginc"

	sampler2D _BaseTex;

	half _Threshold;
	half3 _Curve;
	half2 _Bloom_Settings; // x: sampleScale, y: bloom.intensity
	
	
	// -----------------------------------------------------------------------------
	// Vertex shaders

	struct VaryingsMultitex
	{
		float4 pos : SV_POSITION;
		float2 uvMain : TEXCOORD0;
		float2 uvBase : TEXCOORD1;
	};

	VaryingsMultitex VertMultitex(AttributesDefault v)
	{
		VaryingsMultitex o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uvMain = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
		o.uvBase = o.uvMain;

	#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0.0)
			o.uvBase.y = 1.0 - o.uvBase.y;
	#endif

		return o;
	}
	
	// -----------------------------------------------------------------------------
	// Fragment shaders

	half4 FragPrefilter(VaryingsDefault i) : SV_Target
	{
		float2 uv = i.uv;

		half4 s0 = SafeHDR(tex2D(_MainTex, uv));
		half3 m = s0.rgb;

		//m = GammaToLinearSpace(m);

		// Pixel brightness
		half br = Brightness(m);

		// Under-threshold part: quadratic curve
		half rq = clamp(br - _Curve.x, 0.0, _Curve.y);
		rq = _Curve.z * rq * rq;

		// Combine and apply the brightness response curve.
		m *= max(rq, br - _Threshold) / max(br, 1e-5);

		return EncodeHDR(m);
	} 

	half4 FragDownsample(VaryingsDefault i) : SV_Target
	{
		return EncodeHDR(DownsampleFilter(_MainTex, i.uvSPR, _MainTex_TexelSize.xy));
	}

	half4 FragUpsample(VaryingsMultitex i) : SV_Target
	{
		half3 base = DecodeHDR(tex2D(_BaseTex, i.uvBase));
		half3 blur = UpsampleFilter(_MainTex, i.uvMain, _MainTex_TexelSize.xy, _Bloom_Settings.x);
		return EncodeHDR(base + blur);
	}
    ENDCG
}