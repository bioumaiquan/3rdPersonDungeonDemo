Shader "Hidden/PostEffect/DepthOfField"
{
	Properties
    {
        _MainTex ("", 2D) = "black"
    }
	
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

        Pass 
        {
            Name "Bokeh Filter (small)"
            CGPROGRAM
                #pragma target 3.0
                #pragma vertex VertDOF
                #pragma fragment FragBlur
            ENDCG
        }

        Pass 
        {
            Name "Postfilter"
            CGPROGRAM
                #pragma target 3.0
                #pragma vertex VertDOF
                #pragma fragment FragPostBlur
            ENDCG
        }
	}
	
	CGINCLUDE
	#include "AK47NewShader-Post-Common.cginc"
	
	static const int kSampleCount = 16;
	static const float2 kDiskKernel[kSampleCount] = 
	{
		float2(0,0),
		float2(0.54545456,0),
		float2(0.16855472,0.5187581),
		float2(-0.44128203,0.3206101),
		float2(-0.44128197,-0.3206102),
		float2(0.1685548,-0.5187581),
		float2(1,0),
		float2(0.809017,0.58778524),
		float2(0.30901697,0.95105654),
		float2(-0.30901703,0.9510565),
		float2(-0.80901706,0.5877852),
		float2(-1,0),
		float2(-0.80901694,-0.58778536),
		float2(-0.30901664,-0.9510566),
		float2(0.30901712,-0.9510565),
		float2(0.80901694,-0.5877853),
	};

	sampler2D _CameraDepthTexture;
	sampler2D _CoCTex;

	// Camera parameters
	float _MaxCoC;
	float _RcpAspect;
	float _DOFBlur;

	struct VaryingsDOF
	{
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		half2 uvAlt : TEXCOORD1;
	};

	// Common vertex shader with single pass stereo rendering support
	VaryingsDOF VertDOF(AttributesDefault v)
	{
		half2 uvAlt = v.texcoord;
	#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0.0) uvAlt.y = 1.0 - uvAlt.y;
	#endif

		VaryingsDOF o;
		o.pos = UnityObjectToClipPos(v.vertex);

	#if defined(UNITY_SINGLE_PASS_STEREO)
		o.uv = UnityStereoScreenSpaceUVAdjust(v.texcoord, _MainTex_ST);
		o.uvAlt = UnityStereoScreenSpaceUVAdjust(uvAlt, _MainTex_ST);
	#else
		o.uv = v.texcoord;
		o.uvAlt = uvAlt;
	#endif

		return o;
	}
	
	// Bokeh filter with disk-shaped kernels
	half4 FragBlur(VaryingsDOF i) : SV_Target
	{
		half3 blur = 0;
		UNITY_LOOP for (int si = 0; si < kSampleCount; si++)
		{
			half2 disp = kDiskKernel[si] * _MaxCoC * _DOFBlur;

			half2 duv = half2(disp.x * _RcpAspect, disp.y);
			half4 samp = tex2D(_MainTex, i.uv + duv);
			
			blur += samp.rgb;
		}
		blur /= kSampleCount;
		
		return half4(blur, 1);
	}

	// Postfilter blur
	half4 FragPostBlur(VaryingsDOF i) : SV_Target
	{
		// 9 tap tent filter with 4 bilinear samples
		const float4 duv = _MainTex_TexelSize.xyxy * float4(0.5, 0.5, -0.5, 0);
		half3 dof;
		dof  = tex2D(_MainTex, i.uv - duv.xy);
		dof += tex2D(_MainTex, i.uv - duv.zy);
		dof += tex2D(_MainTex, i.uv + duv.zy);
		dof += tex2D(_MainTex, i.uv + duv.xy);
		dof /= 4.0;
		dof = GammaToLinearSpace(dof);
		
		return half4(dof, 1);
	}
	ENDCG
}