Shader "dungeon/emission"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EmiTex ("Emi Tex", 2D) = "white" {}
        [HDR]_EmiColor ("Emi Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
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
                half3 worldPos : TEXCOORD2;
                half3 localPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _EmiTex;
            float4 _MainTex_ST;
            half4 _EmiColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.localPos = v.vertex.xyz;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                fixed3 emiColor = tex2D(_EmiTex, i.uv) * _EmiColor.rgb;
                half emiMask = sin(i.worldPos.y + _Time.y * 1.3) * 0.5 + 0.5;
                half dis = length(sin(i.localPos * 0.5 + half3(2, -3, 0) * _Time.y));
                dis = pow(dis, 6);
                emiMask *= dis;

                emiColor *= saturate(emiMask);

                // apply fog
                return half4(emiColor, 1);
            }
            ENDCG
        }
    }
}
