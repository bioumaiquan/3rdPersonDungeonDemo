Shader "Marc Sureda/StylizedWater" {
    Properties {
        _DepthGradient1 ("DepthGradient1", Color) = (0.1098039,0.5960785,0.6196079,1)
        _DepthGradient2 ("DepthGradient2", Color) = (0.05882353,0.1960784,0.4627451,1)
        _DepthGradient3 ("DepthGradient3", Color) = (0,0.0625,0.25,1)
        _GradientPosition1 ("GradientPosition1", Float ) = 1.6
        _GradientPosition2 ("GradientPosition2", Float ) = 2
        _FresnelColor ("FresnelColor", Color) = (0.5764706,0.6980392,0.8000001,1)
        _FresnelExp ("FresnelExp", Range(0, 10)) = 10
        _Roughness ("Roughness", Range(0.01, 1)) = 0.6357628
        _LightColorIntensity ("LightColorIntensity", Range(0, 1)) = 0.7759457
        _SpecularIntensity ("SpecularIntensity", Range(0, 1)) = 1
        _FoamColor ("FoamColor", Color) = (0.854902,0.9921569,1,1)
        _MainFoamScale ("Main Foam Scale", Float ) = 40
        _MainFoamIntensity ("Main Foam Intensity", Range(0, 10)) = 3.84466
        _MainFoamSpeed ("Main Foam Speed", Float ) = 0.1
        _MainFoamOpacity ("Main Foam Opacity", Range(0, 1)) = 0.8737864
        _SecondaryFoamScale ("Secondary Foam Scale", Float ) = 40
        _SecondaryFoamIntensity ("Secondary Foam Intensity", Range(0, 10)) = 2.330097
        _SecondaryFoamOpacity ("Secondary Foam Opacity", Range(0, 1)) = 0.6310679
        [MaterialToggle] _SecondaryFoamAlwaysVisible ("Secondary Foam Always Visible", Float ) = 1
        _TurbulenceDistortionIntesity ("Turbulence Distortion Intesity", Range(0, 6)) = 0.8155341
        _TurbulenceScale ("Turbulence Scale", Float ) = 10
        _WaveDistortionIntensity ("WaveDistortion Intensity", Range(0, 4)) = 0.592233
        _WavesDirection ("Waves Direction", Range(0, 360)) = 0
        _WavesAmplitude ("Waves Amplitude", Range(0, 10)) = 4.980582
        _WavesSpeed ("Waves Speed", Float ) = 1
        _WavesIntensity ("Waves Intensity", Float ) = 2
        [MaterialToggle] _VertexOffset ("Vertex Offset", Float ) = 0
        [MaterialToggle] _RealTimeReflection ("Real Time Reflection", Float ) = 0
        _ReflectionsIntensity ("ReflectionsIntensity", Range(0, 3)) = 1
        _OpacityDepth ("OpacityDepth", Float ) = 5
        _Opacity ("Opacity", Range(0, 1)) = 0.7378641
        _RefractionIntensity ("Refraction Intensity", Float ) = 1
        _DistortionTexture ("DistortionTexture", 2D) = "white" {}
        _FoamTexture ("FoamTexture", 2D) = "white" {}
        _ReflectionTex ("ReflectionTex", 2D) = "white" {}
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
        }
        GrabPass{ "Refraction" }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
//            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x n3ds wiiu 
            #pragma target 3.0
            uniform float4 _LightColor0;
            uniform sampler2D Refraction;
            uniform sampler2D _CameraDepthTexture;
            uniform float4 _TimeEditor;
            uniform float4 _DepthGradient2;
            uniform float4 _FoamColor;
            uniform float4 _FresnelColor;
            uniform float _MainFoamIntensity;
            uniform float _FresnelExp;
            uniform sampler2D _ReflectionTex; uniform float4 _ReflectionTex_ST;
            uniform sampler2D _DistortionTexture; uniform float4 _DistortionTexture_ST;
            uniform float _MainFoamScale;
            uniform float _SecondaryFoamScale;
            uniform float _SecondaryFoamIntensity;
            uniform fixed _SecondaryFoamAlwaysVisible;
            uniform float _SecondaryFoamOpacity;
            uniform float _MainFoamOpacity;
            uniform float _WavesDirection;
            uniform float _WavesSpeed;
            uniform fixed _VertexOffset;
            uniform float _WavesAmplitude;
            uniform float _WavesIntensity;
            uniform fixed _RealTimeReflection;
            uniform float _WaveDistortionIntensity;
            uniform float4 _DepthGradient1;
            uniform float _MainFoamSpeed;
            uniform float _GradientPosition1;
            uniform float _GradientPosition2;
            uniform float4 _DepthGradient3;
            uniform float _TurbulenceDistortionIntesity;
            uniform float _TurbulenceScale;
            uniform float _ReflectionsIntensity;
            uniform float _LightColorIntensity;
            uniform float _Roughness;
            uniform float _SpecularIntensity;
            uniform float _OpacityDepth;
            uniform float _Opacity;
            uniform float _RefractionIntensity;
            uniform sampler2D _FoamTexture; uniform float4 _FoamTexture_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float4 projPos : TEXCOORD4;
                UNITY_FOG_COORDS(5)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                float4 node_8260 = _Time + _TimeEditor;
                float node_9794_ang = (_WavesDirection/57.0);
                float node_9794_spd = 1.0;
                float node_9794_cos = cos(node_9794_spd*node_9794_ang);
                float node_9794_sin = sin(node_9794_spd*node_9794_ang);
                float2 node_9794_piv = float2(0.5,0.5);
                float2 node_9794 = (mul(o.uv0-node_9794_piv,float2x2( node_9794_cos, -node_9794_sin, node_9794_sin, node_9794_cos))+node_9794_piv);
                float4 _Gradient = tex2Dlod(_DistortionTexture,float4(TRANSFORM_TEX(node_9794, _DistortionTexture),0.0,0));
                float node_5335 = sin(((node_8260.g*_WavesSpeed)-(_Gradient.b*(_WavesAmplitude*30.0))));
                float Waves = (node_5335*_WavesIntensity*10.0);
                v.vertex.xyz += lerp( 0.0, (v.normal*(Waves*0.04)), _VertexOffset );
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                o.screenPos = o.pos;
                return o;
            }
            float4 frag(VertexOutput i) : COLOR 
            {
                i.normalDir = normalize(i.normalDir);
                i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
                i.screenPos.y *= _ProjectionParams.x;

                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float sceneZ = max(0,LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)))) - _ProjectionParams.g);
                float partZ = max(0,i.projPos.z - _ProjectionParams.g);
                float depth = (sceneZ-partZ);
                float4 node_8260 = _Time + _TimeEditor;
                float node_9794_ang = (_WavesDirection/57.0);
                float node_9794_spd = 1.0;
                float node_9794_cos = cos(node_9794_spd*node_9794_ang);
                float node_9794_sin = sin(node_9794_spd*node_9794_ang);
                float2 node_9794_piv = float2(0.5,0.5);
                float2 node_9794 = (mul(i.uv0-node_9794_piv,float2x2( node_9794_cos, -node_9794_sin, node_9794_sin, node_9794_cos))+node_9794_piv);
                float4 _Gradient = tex2D(_DistortionTexture,TRANSFORM_TEX(node_9794, _DistortionTexture));
                float node_5335 = sin(((node_8260.g*_WavesSpeed)-(_Gradient.b*(_WavesAmplitude*30.0))));
                float Waves = (node_5335 * _WavesIntensity*10.0);
                float4 node_9238 = _Time + _TimeEditor;
                float2 node_5311 = ((i.uv0*_TurbulenceScale)+node_9238.g*float2(0.01,0.01));
                float4 _DistortionExtra = tex2D(_DistortionTexture,TRANSFORM_TEX(node_5311, _DistortionTexture));
                
                float Turbulence = ((0.05 * Waves * _WaveDistortionIntensity) + ((_DistortionExtra.g * _TurbulenceDistortionIntesity) * 2.0 + 0.0));

                float2 sceneUVs = (i.screenPos.xy * 0.5 + 0.5) + (Turbulence - 0.5) * 0.01 * depth;
                float4 refractColor = tex2D(Refraction, sceneUVs);

                //water main color
                half3 waterColor = lerp(_DepthGradient1.rgb,lerp(_DepthGradient2.rgb,_DepthGradient3.rgb,pow(saturate(depth/(_GradientPosition1+_GradientPosition2)),3.0)),saturate(depth/_GradientPosition1));
                waterColor = saturate(waterColor);
                waterColor = lerp(refractColor.rgb, waterColor, saturate(depth/_OpacityDepth) * _Opacity);

                //reflection
                float2 reflectUV = lerp(sceneUVs, (sceneUVs + 0.01), Turbulence);
                float4 _ReflectionTex_var = tex2D(_ReflectionTex, reflectUV);
                float fresnel = pow(1 - max(0, dot(normalDirection, viewDirection)), _FresnelExp);
                //half3 refColor = lerp(0.0, (_ReflectionTex_var.rgb * _ReflectionsIntensity), fresnel) * _FresnelColor;
                half3 refColor = _ReflectionTex_var.rgb * _ReflectionsIntensity;
                refColor = pow(refColor, 1.5) * saturate(depth);

                //foam
                float2 foamUV = (_MainFoamSpeed * 0.15 * _Time.y) + (i.uv0 * _MainFoamScale);
                float4 _FoamNoise = tex2D(_FoamTexture,TRANSFORM_TEX(foamUV, _FoamTexture));
                float mainFoam = ((1.0 - saturate((pow(saturate(saturate(depth/((node_5335*0.1+0.2)*(_FoamNoise.r*_MainFoamIntensity)))),15.0)/0.1)))*_MainFoamOpacity);
                half3 foamColor = _FoamColor.rgb * mainFoam;

                
                half3 finalRGBA = lerp(waterColor, refColor, fresnel) + foamColor;

                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return float4(finalRGBA.rgb,  1);
            }
            ENDCG
        }
    }
    CustomEditor "CustomMaterialInspector"
}
