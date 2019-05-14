Shader "Hidden/PostEffect/UIRenderTexture"
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
	
	#include "UnityCG.cginc"
	#include "AK47NewShader-Post-Common.cginc"
	
	struct VaryingsFlipped
	{
		half4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		half2 uvSPR : TEXCOORD1; // Single Pass Stereo UVs
		half3 localPos : TEXCOORD2; 
	};

	VaryingsFlipped VertFinal(AttributesDefault v)
	{
		VaryingsFlipped o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		o.uvSPR = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
		
		o.localPos = v.vertex.xyz;

		return o;
	}
		
	half4 FragFinal(VaryingsFlipped i) : SV_Target
	{
		half4 source = tex2D(_MainTex, i.uvSPR);
		
		half2 centerPos = half2(0.5, 0.5);
		/* half distX = distance(centerPos.x, i.uvSPR.x);
		half distY = distance(centerPos.y, i.uvSPR.y);
		fixed alpha = max(distX, distY) * 2;
		alpha = 1 - smoothstep(0.8, 1, alpha); */
		
		fixed dist = distance(centerPos, i.uvSPR);
		fixed alpha = dist * 2;
		alpha = 1 - smoothstep(0.75, 1, alpha);
		
		//return half4(alpha.xxx, 1);
		return half4(source.rgb, source.a * alpha);
	}
    ENDCG
}