Shader "AK47NewShader/Water" 
{
	Properties 
	{
		[Toggle(ENABLE_SOFTEDGE)] _SoftEdge("是否开启柔边", float) = 0
		[Toggle(MANUAL_FOG)] _WaterFog("雾", float) = 0
		_FogDistance ("水面雾距离 X=近 Y=远", Vector)  = (0, 20, 0, 0)
		
		[Space(10)]
		_DeepColor ("深水区颜色", COLOR)  = (0.18, 0.32, 0.44, 1)
		_ShallowColor ("浅水区颜色", COLOR)  = (0.41, 0.93, 0.86, 1)
		_EdgeFactor ("柔边范围", Range (0,5)) = 0.5
		_ShallowAera ("浅水区范围", Range (0,5)) = 0.5
		_NormalScale("法线强度", Range(0,4)) = 1
		_FresnelPower ("菲涅尔强度", Range(0, 4))  = 2
		_Transparent ("透明度", Range(0, 1))  = 0.8
		_WaveSpeed ("水流速度", Vector) = (1,1,1,1)
		[HideInInspector]_SpecPower ("高光范围", Range(0.1,10)) = 5
		[HideInInspector]_SpecIntensity ("高光强度", range(0,5)) = 1
		[HideInInspector]_SpecClr ("高光颜色", color) = (1,1,1,1)
		
		_DistortIntensity ("反射扭曲强度", Range(0,10)) = 1
		_ReflIntensity ("反射亮度", Range(0,2)) = 1
		
		[Space]
		_BumpMap ("法线贴图 ", 2D) = "bump" {}
		[NoScaleOffset]_ReflectionTex ("反射贴图 ", 2D) = "white" {}
	}

	SubShader 
	{
		Tags {"Queue"="Geometry-10" "RenderType"="Transparent" "IgnoreProjector"="True" "LightMode"="ForwardBase"}
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back 
		ZWrite Off
		Lighting Off	
		LOD 900
		
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature ENABLE_SOFTEDGE
			#pragma shader_feature MANUAL_FOG
			#pragma shader_feature FOG_ON
			#pragma shader_feature ENABLE_REFLECTIVE
			#pragma multi_compile __ DEPTH_ON
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "AK47.cginc"		
			
			half4 _WaveSpeed;
			fixed4 _DeepColor;
			fixed4 _ShallowColor;
			sampler2D _BumpMap; half4 _BumpMap_ST;
			sampler2D _ReflectionTex; 
			#if ENABLE_REFLECTIVE
				sampler2D _RealReflectionTex; 
				half _RealDistortIntensity;
			#endif
			half _NormalScale;
			half _FresnelPower;
			half _Transparent;
			
			//fixed4 _SpecClr;
			//half _SpecIntensity;
			//half _SpecPower;
			
			half _DistortIntensity;
			half _ReflIntensity;
			half4 _FogDistance;
			
			#if ENABLE_SOFTEDGE && DEPTH_ON
				UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
				fixed _EdgeFactor;
				fixed _ShallowAera;
			#endif
			
			struct appdata 
			{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half2 uv : TEXCOORD0;
			};

			struct v2f 
			{
				half4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
				half3 viewDir : TEXCOORD2;
				half3 normal : NORMAL;
				half4 projPos : TEXCOORD3;
				half2 fogCoord : TEXCOORD5;
				half3 worldPos : TEXCOORD6;
			};
			
			v2f vert(appdata v)
			{
				v2f o = (v2f)0;
				
				o.pos = UnityObjectToClipPos (v.vertex);
				
				o.projPos = ComputeScreenPos (o.pos);
					
				#if ENABLE_SOFTEDGE && DEPTH_ON
					COMPUTE_EYEDEPTH(o.projPos.z);
				#endif
				
				half2 nuv = TRANSFORM_TEX(v.uv, _BumpMap);
				half4 waveScale = half4(nuv, nuv.x * 0.4, nuv.y * 0.45);
				half4 waveOffset = _WaveSpeed * _Time.y * 0.05;
				o.uv = waveScale + frac(waveOffset);
				
				half3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				half3 viewSpacePos = mul(UNITY_MATRIX_V, half4(worldPos, 1)).xyz;
				o.fogCoord.x = viewSpacePos.z;
				o.fogCoord.y = worldPos.y;
				o.worldPos = worldPos;
				
				o.viewDir = _WorldSpaceCameraPos.xyz - worldPos;
				
				return o;
			}

			fixed4 frag( v2f i ) : SV_Target
			{
				fixed3 bump1 = UnpackNormal(tex2D( _BumpMap, i.uv.xy )).rgb;
				fixed3 bump2 = UnpackNormal(tex2D( _BumpMap, i.uv.zw )).rgb;
				fixed3 normal = bump1 + bump2;
				normal.xy *= -_NormalScale;
				normal = normalize(normal.xzy);
				
				half3 viewDir = normalize(i.viewDir);
				fixed fresnelFac = 1 - dot(viewDir, normal);
				fresnelFac = saturate(pow(fresnelFac, _FresnelPower) + 0.02);
				
				//reflect
				half4 reflUV = i.projPos;
				fixed3 reflection;
				
				#if !ENABLE_REFLECTIVE
					reflUV.xy += normal.xz * _DistortIntensity;
					reflection = tex2Dproj(_ReflectionTex, reflUV).rgb;
				#else
					reflUV.xy += normal.xz * _RealDistortIntensity;
					reflection = tex2Dproj(_RealReflectionTex, UNITY_PROJ_COORD(reflUV)).rgb;
				#endif	
				reflection *= _ReflIntensity;
				
				fixed4 color;
				
				#if ENABLE_SOFTEDGE && DEPTH_ON
					half sceneZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos));
					sceneZ = LinearEyeDepth (sceneZ);
					half partZ = i.projPos.z;
					half edge = sceneZ - partZ;
					
					half softAlpha = saturate(edge * _EdgeFactor);
					half shallowAera = saturate(edge * _ShallowAera);
					
					color.rgb = lerp(_DeepColor, reflection, fresnelFac);
					color.rgb = lerp(_ShallowColor.rgb, color.rgb, shallowAera); 
					color.a = max(_Transparent, fresnelFac) * softAlpha;
				#else
					color.rgb = lerp(_DeepColor, reflection, fresnelFac);
					color.a = max(_Transparent, fresnelFac);
				#endif
				
				/* //specular
				half3 lightDir = _SceneLightDir.xyz;
				half3 halfDir = normalize(lightDir + viewDir);
				half spec = pow(saturate(dot(halfDir,normal)), _SpecPower * 128) * _SpecIntensity;
				#if ENABLE_SOFTEDGE && DEPTH_ON
					spec *= softAlpha;
				#endif
				half3 specColor = spec * _SpecClr;
				color.rgb += specColor;
				color.a = max(color.a, spec); */
				
				#if MANUAL_FOG && FOG_ON
					color.rgb = ComputeWaterHeightFog(i.fogCoord, color.rgb, i.worldPos, _FogDistance);
				#endif
				
				return fixed4(color);
			}
			ENDCG
		}
	}
	
	CGINCLUDE
	#include "AK47.cginc"		
	fixed3 ComputeWaterHeightFog(half2 fogCoord, fixed3 color, half3 worldPos, half4 fogDistnce) //fogCoord.x = viewSpacePos.z  y = worldpos.y
	{
		g_FogParam.xy = fogDistnce.xy;
		
		half fogDepth = -fogCoord.x;
		half start = g_FogParam.x;
		half end = g_FogParam.y;
		half fog = (end - fogDepth) / (end - start);  // linear fog
		//half fog = exp(-(g_FogDensity * fogDepth));  //Exp Fog
		half startHeight = g_FogParam.z;
		half endHeight = g_FogParam.w;
		half heightFog = (endHeight - fogCoord.y) * (1.0f / ( endHeight - startHeight));
		
		fog = saturate(fog);
		heightFog = saturate(heightFog);
		fog *= heightFog;
		fog = 1 - fog;
		
		half noFogAera = distance(g_CharacterPos, worldPos);
		noFogAera -= g_NoFogRange.x;
		noFogAera *= g_NoFogRange.y;
		noFogAera = saturate(noFogAera);
		
		fog *= noFogAera;
		
		fixed3 oColor = color;
		fixed3 fogColor = lerp(g_FogColor.rgb, g_FogColor2.rgb, weatherLerp).rgb;
		oColor = lerp(color, fogColor, fog);
		return oColor;
	}
	ENDCG
}
