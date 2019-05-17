Shader "AK47NewShader/Lighting/Character-Hair"
{
	Properties
	{
		[Toggle(SWITCH_TANGENT)] _SwitchTangent ("切换tangent方向", Float) = 0.0
		
		[Toggle(ENABLE_CUTOUT)] _Cutout ("是否开启Cutout", Float) = 0.0
		_CutoutFac ("Cutout阈值", Range(0,1)) = 0.5
		
		[Space]
		_LightIntensity ("亮度", Range(0,2)) = 1
		_NormalScale ("法线强度", Range(0,3)) = 1
		_LightWarp ("暗部亮度", Range(0,1)) = 0.5
		
		[Header(Specular)]
		_SpecColorMain ("高光颜色", color)  = (1,1,1,1)
		_SpecColor ("副高光颜色", color)  = (1,1,1,1)
		_Shift ("副高光偏移", Range(-1,1)) = 0.1
		_SpecIntensity1 ("主高光强度", Range(0,1)) = 0.4
		_SpecIntensity2 ("副高光强度", Range(0,1)) = 0.25
		_SpecPower1 ("主高光范围", Range(0.1,8)) = 1
		_SpecPower2 ("副高光范围", Range(0.1,8)) = 1
		
		[Header(Rim)]
		_RimPower ("边缘光范围", Range(0.1,10)) = 3
		_RimColor ("边缘光颜色", color)  = (1,1,1,1)
		
		[Header(Texture)]
		_MainTex ("颜色贴图", 2D) = "white" {}
		_ShiftTex ("高光偏移贴图", 2D) = "white" {}
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 900
		Cull Back 
		ZWrite On
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma shader_feature SWITCH_TANGENT
			#pragma shader_feature ENABLE_CUTOUT
			#include "UnityCG.cginc"

			//shift spec
			inline half3 ShiftTangent(half3 tangent, half3 normal, half shift)
			{
				half3 shiftedT = tangent + (shift * normal);
				return normalize(shiftedT);
			}
			//kajiya-kay model
			inline half KajiyaKaySpec(half3 tangent, half3 viewDir, half lightDir, half specPower)
			{
				half3 halfDir = normalize(lightDir + viewDir);
				half TdotH = dot(tangent, halfDir);
				half sinTH = sqrt(1.0 - TdotH * TdotH);
				half dirAtten = smoothstep(-1.0, 0.0, dot(tangent, halfDir));

				return dirAtten * pow(sinTH, specPower);
			}
			
			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
			};

			struct v2f
			{
				half4 uv : TEXCOORD0;
				half4 vertex : SV_POSITION;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
				half3 viewDir : TEXCOORD1;
			};

			sampler2D _MainTex; half4 _MainTex_ST;
			sampler2D _ShiftTex; half4 _ShiftTex_ST;
			
			fixed _NormalScale;
			
			fixed _Shift;
			fixed _SpecIntensity1;
			fixed _SpecIntensity2;
			half _SpecPower1;
			half _SpecPower2;
			fixed4 _SpecColor;
			fixed4 _SpecColorMain;
			
			fixed _LightWarp;
			fixed _LightIntensity;
			
			half _RimPower;
			fixed4 _RimColor;
			
			half4 _SceneLightParam; //.x lightIntensity .y lightWarp .z lightColorLerp
			half4 _SceneLightDir;
			fixed4 _SceneLightColor;
			
			#if ENABLE_CUTOUT
				fixed _CutoutFac;
			#endif
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _ShiftTex);
				
				o.normal = v.normal;
				
				#if SWITCH_TANGENT
					half3 binormal = cross(v.normal, v.tangent.xyz);
					o.tangent.xyz = binormal;
					o.tangent.w = v.tangent.w;
				#else
					o.tangent = v.tangent;
				#endif
				
				o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 worldNormal = UnityObjectToWorldNormal(i.normal);
				half3 worldTangent = UnityObjectToWorldNormal(i.tangent.xyz);
				
				fixed4 color = tex2D(_MainTex, i.uv.xy);
				#if ENABLE_CUTOUT
					clip(color.a - _CutoutFac);
				#endif

				//shift tangent
				fixed shiftTex = (tex2D(_ShiftTex,i.uv.zw).r - 0.5) * _NormalScale;
				half3 t1 = ShiftTangent(worldTangent, worldNormal, shiftTex);
				half3 t2 = ShiftTangent(worldTangent, worldNormal, _Shift + shiftTex);
				
				//rim
				half3 upDir = half3(0,1,0);
				fixed upFalloff = dot(worldNormal, upDir) * 0.5 + 0.5;
				fixed3 rimcolor = pow(1 - max(0, dot(worldNormal, i.viewDir)), _RimPower) * _RimColor * upFalloff;
				
				//specular
				fixed3 spec1 =  KajiyaKaySpec(t1, i.viewDir, upDir, 128 * _SpecPower1) * _SpecIntensity1 * _SpecColorMain;
				fixed3 spec2 =  KajiyaKaySpec(t2, i.viewDir, upDir, 12 * _SpecPower2) * _SpecIntensity2 * _SpecColor;
				fixed3 specColor = (spec1 + spec2) * upFalloff;
				color.rgb += specColor;
				
				//lighting
				half ndotl = dot(worldNormal, _SceneLightDir) * _LightWarp + (1 - _LightWarp);
				ndotl = saturate(ndotl);
				
				_SceneLightColor.rgb = lerp(fixed3(1,1,1), _SceneLightColor.rgb, _SceneLightParam.z);
				color.rgb *= ndotl * _SceneLightParam.x * _SceneLightColor.rgb * _LightIntensity;
				
				color.rgb += rimcolor;
				
				return fixed4(color.rgb, 1);
			}
			ENDCG
		}
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 400
		Cull Back 
		ZWrite On
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma shader_feature SWITCH_TANGENT
			#pragma shader_feature ENABLE_CUTOUT
			#include "UnityCG.cginc"

			//shift spec
			inline half3 ShiftTangent(half3 tangent, half3 normal, half shift)
			{
				half3 shiftedT = tangent + (shift * normal);
				return normalize(shiftedT);
			}
			//kajiya-kay model
			inline half KajiyaKaySpec(half3 tangent, half3 viewDir, half lightDir, half specPower)
			{
				half3 halfDir = normalize(lightDir + viewDir);
				half TdotH = dot(tangent, halfDir);
				half sinTH = sqrt(1.0 - TdotH * TdotH);
				half dirAtten = smoothstep(-1.0, 0.0, dot(tangent, halfDir));

				return dirAtten * pow(sinTH, specPower);
			}
			
			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
			};

			struct v2f
			{
				half4 uv : TEXCOORD0;
				half4 vertex : SV_POSITION;
				half3 normal : NORMAL;
				half3 tangent : TEXCOORD2;
				half3 viewDir : TEXCOORD1;
				fixed3 lightFalloff : TEXCOORD3;
				fixed4 rimColor : TEXCOORD4;
			};

			sampler2D _MainTex; half4 _MainTex_ST;
			sampler2D _ShiftTex; half4 _ShiftTex_ST;
			
			fixed _NormalScale;
			
			fixed _Shift;
			fixed _SpecIntensity1;
			half _SpecPower1;
			fixed4 _SpecColor;
			fixed4 _SpecColorMain;
			
			fixed _LightWarp;
			fixed _LightIntensity;
			
			half _RimPower;
			fixed4 _RimColor;
			
			half4 _SceneLightParam; //.x lightIntensity .y lightWarp .z lightColorLerp
			half4 _SceneLightDir;
			fixed4 _SceneLightColor;
			
			#if ENABLE_CUTOUT
				fixed _CutoutFac;
			#endif
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _ShiftTex);
				
				o.normal = UnityObjectToWorldNormal(v.normal);
				half3 tangent;
				#if SWITCH_TANGENT
					half3 binormal = cross(v.normal, v.tangent.xyz);
					tangent = binormal;
				#else
					tangent = v.tangent;
				#endif
				o.tangent = UnityObjectToWorldNormal(tangent);
				o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
				
				half ndotl = dot(o.normal, _SceneLightDir) * _LightWarp + (1 - _LightWarp);
				ndotl = saturate(ndotl);
				_SceneLightColor.rgb = lerp(fixed3(1,1,1), _SceneLightColor.rgb, _SceneLightParam.z);
				o.lightFalloff = ndotl * _SceneLightParam.x * _SceneLightColor.rgb * _LightIntensity;
				
				half3 upDir = half3(0,1,0);
				fixed upFalloff = dot(o.normal, upDir) * 0.5 + 0.5;
				fixed3 rimcolor = pow(1 - max(0, dot(o.normal, o.viewDir)), _RimPower) * _RimColor * upFalloff;
				o.rimColor.rgb = rimcolor;
				o.rimColor.a = upFalloff;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 color = tex2D(_MainTex, i.uv.xy);
				#if ENABLE_CUTOUT
					clip(color.a - _CutoutFac);
				#endif
				
				//shift tangent
				fixed shiftTex = (tex2D(_ShiftTex,i.uv.zw).r - 0.5) * _NormalScale;
				half3 t1 = ShiftTangent(i.tangent, i.normal, shiftTex);
				
				//specular
				fixed3 spec1 =  KajiyaKaySpec(t1, i.viewDir, half3(0,1,0), 128 * _SpecPower1) * _SpecIntensity1 * _SpecColorMain;
				fixed3 specColor = spec1 * i.rimColor.a;
				color.rgb += specColor;
				
				//lighting
				color.rgb *= i.lightFalloff;
				
				//rim
				color.rgb += i.rimColor.rgb;
				
				return fixed4(color.rgb, 1);
			}
			ENDCG
		}
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 100
		Cull Back 
		ZWrite On
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma shader_feature ENABLE_CUTOUT
			#include "UnityCG.cginc"

			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
			};

			struct v2f
			{
				half4 uv : TEXCOORD0;
				half4 vertex : SV_POSITION;
				fixed3 lightFalloff : TEXCOORD2;
			};

			sampler2D _MainTex; half4 _MainTex_ST;
			
			fixed _LightWarp;
			fixed _LightIntensity;
			
			half4 _SceneLightParam; //.x lightIntensity .y lightWarp .z lightColorLerp
			half4 _SceneLightDir;
			fixed4 _SceneLightColor;
			
			#if ENABLE_CUTOUT
				fixed _CutoutFac;
			#endif
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				half3 normal = UnityObjectToWorldNormal(v.normal);
				
				fixed ndotl = dot(normal, _SceneLightDir) * _LightWarp + (1 - _LightWarp);
				ndotl = saturate(ndotl);
				
				_SceneLightColor.rgb = lerp(fixed3(1,1,1), _SceneLightColor.rgb, _SceneLightParam.z);
				o.lightFalloff = ndotl * _SceneLightParam.x * _SceneLightColor.rgb * _LightIntensity;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//final color
				fixed4 color = tex2D(_MainTex, i.uv.xy);
				
				#if ENABLE_CUTOUT
					clip(color.a - _CutoutFac);
				#endif
				
				//lighting
				color.rgb *= i.lightFalloff;
				
				return fixed4(color.rgb, 1);
			}
			ENDCG
		}
	}
}
