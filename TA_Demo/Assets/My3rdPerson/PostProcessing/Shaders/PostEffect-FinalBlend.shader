Shader "Hidden/PostEffect/PostFinalBlend"
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
                #pragma vertex VertFinal
                #pragma fragment FragFinal
            ENDCG
        }
    }

    CGINCLUDE
	
	#pragma multi_compile __ ENABLE_AKPOST_BLOOM
	#pragma multi_compile __ ENABLE_AKPOST_DOF
	#pragma multi_compile __ ENABLE_AKPOST_VIGNETTE
	#pragma multi_compile __ ENABLE_AKPOST_COLORGRADING
	#pragma multi_compile __ ENABLE_AKPOST_FASTBLUR
	#pragma multi_compile __ ENABLE_AKPOST_RAIN
	#pragma shader_feature ENABLE_AKPOST_DOF_DEBUG

	#pragma target 3.0
	#include "UnityCG.cginc"
	#include "AK47NewShader-Post-Bloom.cginc"
	#include "AK47NewShader-Post-ColorGrading.cginc" 

	//HDR bloom
	sampler2D _BloomTex;
	half2 _Bloom_Settings; // x: sampleScale, y: bloom.intensity
	
	//depth of field
	sampler2D _DOFTex;
	sampler2D _CameraDepthTexture;
	float _DOFDistance;
	float _ClearDistance;
	float _DOFRange;
	
	//vignette
	fixed4 _Vignette_Color;
	half4 _Vignette_Settings;
	half2 _Vignette_Center;
	
	//color grading
	sampler2D _LogLut;
	half3 _LogLut_Params;
	half _ExposureEV;
	
	//fast blur
	sampler2D _BlurTex;
	
	//rain
	sampler2D _PostRainDistortTex;
	half2 _PostRainParam;
	
	struct VaryingsFlipped
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uvSPR : TEXCOORD1; // Single Pass Stereo UVs
		float2 uvFlipped : TEXCOORD2; // Flipped UVs (DX/MSAA/Forward)
		float2 uvFlippedSPR : TEXCOORD3; // Single Pass Stereo flipped UVs
	};

	VaryingsFlipped VertFinal(AttributesDefault v)
	{
		VaryingsFlipped o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		o.uvSPR = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
		o.uvFlipped = v.texcoord.xy;

	#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0.0)
			o.uvFlipped.y = 1.0 - o.uvFlipped.y;
	#endif 

		o.uvFlippedSPR = UnityStereoScreenSpaceUVAdjust(o.uvFlipped, _MainTex_ST);

		return o;
	}
		
	half4 FragFinal(VaryingsFlipped i) : SV_Target
	{
		#if ENABLE_AKPOST_RAIN
			_Time.y *= _PostRainParam.x;
			half2 rainUV1 = (i.uvFlippedSPR + half2((_Time.y * 0.163), (_Time.y * 0.3))) * 1.54 * half2(1.66, 1);
			half2 rainUV2 = (i.uvFlippedSPR + half2((_Time.y * 0.2), (_Time.y * 0.50))) * 1 * half2(1.66, 1);
			half2 rainUV3 = (i.uvFlippedSPR + half2((_Time.y * 0.05), (_Time.y * 0.13))) * 1.64 * half2(1.66, 1);
			
			fixed distortTex1 = tex2D(_PostRainDistortTex, rainUV1).r;
			fixed distortTex2 = tex2D(_PostRainDistortTex, rainUV2 + distortTex1 * 0.1).r;
			fixed distortTex3 = tex2D(_PostRainDistortTex, rainUV3 + distortTex2 * 0.07).r;
			
			distortTex3 *= distortTex3;
			distortTex3 *= _PostRainParam.y;
			
			i.uvFlippedSPR += distortTex3;
			i.uvSPR += distortTex3;
			i.uv += distortTex3;
		#endif

		half3 source;
		#if ENABLE_AKPOST_FASTBLUR
			source = tex2D(_BlurTex, i.uvFlippedSPR);
			//source = GammaToLinearSpace(source);
		#else
			source = tex2D(_MainTex, i.uvSPR);
			//source = GammaToLinearSpace(source);
			
			#if ENABLE_AKPOST_DOF
				half depth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv));
				depth -= (_ClearDistance + _DOFDistance);
				depth *= _DOFRange;
				depth = saturate(depth);
				
				half3 dof = tex2D(_DOFTex, i.uvFlippedSPR);
				source = lerp(source, dof, depth);
				
				#if ENABLE_AKPOST_DOF_DEBUG
					source = depth.xxx;
				#endif
			#endif	
		#endif
		
		#if ENABLE_AKPOST_BLOOM
			half3 bloom = UpsampleFilter(_BloomTex, i.uvFlippedSPR, _MainTex_TexelSize.xy, _Bloom_Settings.x) * _Bloom_Settings.y;
			source += bloom;
		#endif
		
		#if ENABLE_AKPOST_COLORGRADING
			source *= _ExposureEV;
			half3 colorLogC = saturate(LinearToLogC(source));
            source = ApplyLut2d(_LogLut, colorLogC, _LogLut_Params);
		#endif
		
		#if ENABLE_AKPOST_VIGNETTE
			_Vignette_Center = half2(0.5, 0.5);
			half2 d = abs(i.uv - _Vignette_Center) * _Vignette_Settings.x;
			d = pow(d, _Vignette_Settings.z); // Roundness
			half vfactor = pow(saturate(1.0 - dot(d, d)), _Vignette_Settings.y);
			source *= lerp(_Vignette_Color, 1.0, vfactor);
		#endif

		source = saturate(source);
		//source = LinearToGammaSpace(source);
		
		return half4(source, 1);
	}
    ENDCG
}