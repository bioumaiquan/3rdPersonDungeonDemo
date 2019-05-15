#ifndef __AK47__
#define __AK47__
#include "UnityCG.cginc"
		
half4 g_FogParam;
fixed4 g_FogColor;
fixed4 g_FogColor2;
fixed g_FogDensity;
fixed weatherLerp;
fixed4 _ColorChangeBefor;
fixed4 _ColorChangeAfter;

fixed4 g_RainSpecColor;  //w = rain Normal tex uv scale
half4 g_RainSpec;  // x = power  y = intensity  z = distort tex uv scale  w = distort tex2 uv scale
sampler2D g_RainDistortTex;
half4 g_RainFlowSpeed;

half4 _SceneLightDir;
half4 _SceneLightParam; //x = lightIntensity, y = lightWarp, z = lightColorLerp
fixed4 _SceneLightColor;
fixed4 _SceneEnvColor;
half _specMask;
fixed _SandSpecIntensity;

half4 g_CharacterPos;  //w = character distance with camera
half2 g_NoFogRange; //x = distance from character, y = lerp edge
half4 g_FogNoiseFac;

sampler2D _SandGlitterTex;
half4 _SandGlitterParam;  //x = scale  y = intensity  z = specPower  w = other intensity

half4 g_WindDir; //xz = dir y = speed w = intensity

//noise
//https://blog.csdn.net/candycat1992/article/details/50346469
//https://www.shadertoy.com/view/4sc3z2
half3 hash33(half3 p3)
{
	half3 MOD3 = half3(0.1031, 0.11369, 0.13787);
	p3 = frac(p3 * MOD3);
    p3 += dot(p3, p3.yxz + 19.19);
    return -1.0 + 2.0 * frac(half3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}
fixed simplex_noise_3D(half3 pos)
{
    const half K1 = 0.333333333;
    const half K2 = 0.166666667;
    
    half3 i = floor(pos + (pos.x + pos.y + pos.z) * K1);
    half3 d0 = pos - (i - (i.x + i.y + i.z) * K2);
    
    // thx nikita: https://www.shadertoy.com/view/XsX3zB
    half3 e = step(0, d0 - d0.yzx);
	half3 i1 = e * (1.0 - e.zxy);
	half3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    half3 d1 = d0 - (i1 - 1.0 * K2);
    half3 d2 = d0 - (i2 - 2.0 * K2);
    half3 d3 = d0 - (1.0 - 3.0 * K2);
    
    half4 h = max(0.6 - half4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    half4 n = h * h * h * h * half4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    
    return dot(31.316, n) * 0.5 + 0.5;
}


inline half3 calculateWorldNormal(half3 normal, half4 tangent, fixed3 normalTex, half normalScale)
{
	normal         = normalize(normal);
	tangent        = normalize(tangent);
	half3 binormal = cross(normal,tangent.xyz) * tangent.w;
	half3x3 TBN = half3x3(tangent.xyz, binormal, normal);
	
	normalTex.xy *= normalScale;
	half3 normalL = normalTex.x * TBN[0] +
					normalTex.y * TBN[1] +
					normalTex.z * TBN[2];
	half3 normalW = UnityObjectToWorldNormal(normalL);
	return normalize(normalW);
}

//fog
inline half NoneFogAera (half3 worldPos)
{
	half nfa = distance(g_CharacterPos, worldPos);
	nfa -= g_NoFogRange.x;
	nfa *= g_NoFogRange.y;
	return saturate(nfa);
}
fixed3 ComputeHeightFog(half2 fogCoord, fixed3 color, half3 worldPos) 
{
	half fogDepth = -fogCoord.x;
	half start = g_FogParam.x;
	half end = g_FogParam.y;
	half fog = (end - fogDepth) / (end - start);  // linear fog
	//half fog = exp(-(g_FogDensity * fogDepth));  //Exp Fog
	half startHeight = g_FogParam.z;
	half endHeight = g_FogParam.w;
	half heightFog = (endHeight - fogCoord.y) * (1.0f / ( endHeight - startHeight));
	fog = saturate(fog);
	heightFog = 1 - saturate(heightFog);
	
	#if ENABLE_NOISE_FOG
		half3 noisePos = worldPos;
		noisePos += _Time.y * g_FogNoiseFac.yzw;
		noisePos *= g_FogNoiseFac.x;
		fixed noise = simplex_noise_3D(noisePos);
		heightFog = lerp(heightFog * noise, heightFog, heightFog);
	#endif
	
	fog *= (1 - heightFog);
	fog = 1 - fog;
	
	fog *= NoneFogAera(worldPos);
	
	fixed3 oColor = color;
	fixed3 fogColor;
	
	#ifdef UNITY_PASS_FORWARDADD
		fogColor = fixed3(0,0,0);
	#else
		fogColor = lerp(g_FogColor.rgb, g_FogColor2.rgb, weatherLerp).rgb;
	#endif
	
	oColor = lerp(color, fogColor, fog);
	
	return oColor;
}
fixed3 ComputeHeightFog(half2 fogCoord, fixed3 color, half3 worldPos, half noFogAera) 
{
	half fogDepth = -fogCoord.x;
	half start = g_FogParam.x;
	half end = g_FogParam.y;
	half fog = (end - fogDepth) / (end - start);  // linear fog
	//half fog = exp(-(g_FogDensity * fogDepth));  //Exp Fog
	half startHeight = g_FogParam.z;
	half endHeight = g_FogParam.w;
	half heightFog = (endHeight - fogCoord.y) * (1.0f / ( endHeight - startHeight));
	fog = saturate(fog);
	heightFog = 1 - saturate(heightFog);
	
	#if ENABLE_NOISE_FOG
		half3 noisePos = worldPos;
		noisePos += _Time.y * g_FogNoiseFac.yzw;
		noisePos *= g_FogNoiseFac.x;
		fixed noise = simplex_noise_3D(noisePos);
		heightFog = lerp(heightFog * noise, heightFog, heightFog);
	#endif
	
	fog *= (1 - heightFog);
	fog = 1 - fog;
	
	fog *= noFogAera;
	
	fixed3 oColor = color;
	fixed3 fogColor;
	
	#ifdef UNITY_PASS_FORWARDADD
		fogColor = fixed3(0,0,0);
	#else
		fogColor = lerp(g_FogColor.rgb, g_FogColor2.rgb, weatherLerp).rgb;
	#endif
	
	oColor = lerp(color, fogColor, fog);
	
	return oColor;
}
fixed3 ComputeSkyHeightFog(half2 fogCoord, fixed3 color, fixed fogLerp) 
{
	half fogDepth = -fogCoord.x;
	half start = g_FogParam.x;
	half end = g_FogParam.y;
	half fog = (end - fogDepth) / (end - start);  // linear fog
	//half fog = exp(-(g_FogDensity * fogDepth));  //Exp Fog
	half startHeight = g_FogParam.z;
	half endHeight = g_FogParam.w;
	half heightFog = (endHeight - fogCoord.y) * (1.0f / ( endHeight - startHeight));
	
	fog = saturate(fog);
	fog = lerp(1, fog, fogLerp);
	heightFog = saturate(heightFog);
	fog *= heightFog;
	
	fixed3 oColor = color;
	fixed3 fogColor = lerp(g_FogColor.rgb, g_FogColor2.rgb, weatherLerp).rgb;
	oColor = lerp(fogColor, color, fog);
	return oColor;
}


//vertex animation
inline void FastSinCos(half4 val, out half4 s, out half4 c) 
{
	val = frac(val);
    val = val * 6.408849 - 3.1415927;
    // powers for taylor series
    half4 r5 = val * val;                  // wavevec ^ 2
    half4 r6 = r5 * r5;                        // wavevec ^ 4;
    half4 r7 = r6 * r5;                        // wavevec ^ 6;
    half4 r8 = r6 * r5;                        // wavevec ^ 8;

    half4 r1 = r5 * val;                   // wavevec ^ 3
    half4 r2 = r1 * r5;                        // wavevec ^ 5;
    half4 r3 = r2 * r5;                        // wavevec ^ 7;

    //Vectors for taylor's series expansion of sin and cos
    float4 sin7 = {1, -0.16161616, 0.0083333, -0.00019841};
    float4 cos8  = {-0.5, 0.041666666, -0.0013888889, 0.000024801587};

    // sin
    s =  val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
    // cos
    c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
}
inline half4 FastSin(half4 val) 
{
	val = frac(val / 6.283);
    val = val * 6.408849 - 3.1415927;
    // powers for taylor series
    half4 r5 = val * val;                  // wavevec ^ 2
    half4 r1 = r5 * val;                   // wavevec ^ 3
    half4 r2 = r1 * r5;                        // wavevec ^ 5;
    half4 r3 = r2 * r5;                        // wavevec ^ 7;

    //Vectors for taylor's series expansion of sin
    float4 sin7 = {1, -0.16161616, 0.0083333, -0.00019841};

    // sin
    return val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
}
inline half FastSin(half val) 
{
	val = frac(val / 6.283);
    val = val * 6.408849 - 3.1415927;
    // powers for taylor series
    half r5 = val * val;                  // wavevec ^ 2
    half r1 = r5 * val;                   // wavevec ^ 3
    half r2 = r1 * r5;                        // wavevec ^ 5;
    half r3 = r2 * r5;                        // wavevec ^ 7;

    //Vectors for taylor's series expansion of sin
    float4 sin7 = {1, -0.16161616, 0.0083333, -0.00019841};

    // sin
    return val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
}
inline half2 GrassAnimation(half4 vertex, half3 worldPos)
{
	half4 val = half4(_Time.y * g_WindDir.y + worldPos.xz, 1, 1);
	fixed2 waveXZ = FastSin(val).xy * 0.5 + 0.5;
	fixed wave = lerp(waveXZ.x, waveXZ.y, abs(dot(g_WindDir.xz, fixed2(1,0))));
	return g_WindDir.xz * vertex.y * wave * g_WindDir.w;
}
inline half3 CharacterCollision(half3 worldPos)
{
	g_CharacterPos.y += 1.5;
	half3 dir = normalize(worldPos.xyz - (g_CharacterPos.xyz + half3(0,1.5,0)));
	half dist = distance(g_CharacterPos.xyz, worldPos.xyz);
	half strength = lerp(0.8, 0, clamp(dist, 0, 1.5) / 1.5);
	return dir.xyz * strength * half3(1,1.5,1);
}
inline half2 LeavesAnimation(half2 uv)
{
	half4 val = half4(_Time.y * g_WindDir.y * 1.5 + uv.x * 15, 1, 1, 1);
	fixed wave = FastSin(val).x * 0.5 + 0.5;
	return g_WindDir.xz * wave * g_WindDir.w * uv.y * 1.5;
}


inline fixed3 RainSpecular (half3 normal, half3 worldPos, half3 lightDir)
{
	half2 uv = frac(worldPos.xz * g_RainSpec.z) + half2(_Time.y * g_RainFlowSpeed.xy);
	half2 uv2 = frac(worldPos.xz * g_RainSpec.w) + half2(_Time.y * g_RainFlowSpeed.zw);
	fixed distortTex = tex2D(g_RainDistortTex, uv).r;
	fixed distortTex2 = tex2D(g_RainDistortTex, uv2 + distortTex.x * 0.1).r;
	distortTex *= distortTex2;
	distortTex *= distortTex;
	
	half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
    half3 halfDir = normalize (lightDir + viewDir);
    float nh = max (0, dot (normal, halfDir));
    fixed3 spec = pow (nh, g_RainSpec.x * 128.0) * g_RainSpec.y * g_RainSpecColor;
	
	fixed NdotUp = dot(fixed3(0,1,0), normal);
	
    return spec * distortTex * NdotUp;
}

/* inline half3 SandSpecular(half3 lightDir, CustomSurfaceOutput s, half noneFogAera)
{
	fixed GlitterTex = tex2D(_SandGlitterTex, s.fogCoord.zw * _SandGlitterParam.x).r;
	half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - s.worldPos);
	half3 halfDir = normalize(lightDir + viewDir);
	half ndoth = max(0, dot(s.Normal, halfDir));
	half3 specColor = pow (ndoth, _SandGlitterParam.z * 128) * _SandGlitterParam.y * GlitterTex * (1 - noneFogAera);
	
	half ndotv = max(0, dot(s.Normal, viewDir));
	GlitterTex *= GlitterTex;
	GlitterTex *= GlitterTex * GlitterTex;
	GlitterTex *= _SandGlitterParam.w * ndotv * 2;
	specColor += GlitterTex;
	
	return specColor;
} */



//Character PBR

inline half AKRoughnessToSpecPower (fixed roughness, out fixed realRoughness)
{
	realRoughness = max(0.01h, roughness * roughness);		// m is the true academic roughness.

	half n = (2.0 / (realRoughness * realRoughness)) - 2.0;	// https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
															// prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
	return n;
}
inline half AKDotClamped (half3 a, half3 b)
{
	#if (SHADER_TARGET < 30 || defined(SHADER_API_PS3))
	return saturate(dot(a, b));
	#else
	return max(0.0h, dot(a, b));
	#endif
}
inline half3 SafeNormalize(half3 inVec)
{
	half dp3 = max(0.001f, dot(inVec, inVec));
	return inVec * rsqrt(dp3);
}
inline fixed3 AKFresnelLerpFast (fixed3 F0, fixed3 F90, half cosA)
{
	cosA = 1 - cosA;
	half fresnel = cosA * cosA * cosA * cosA;
	return lerp (F0, F90, fresnel); 
}
inline fixed AKOneMinusReflectivityFromMetallic(fixed metallic,fixed dielec)
{
	fixed oneMinusDielectricSpec = 1 - dielec;
	return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}
inline half3 AKDiffuseAndSpecularFromMetallic (fixed3 albedo, fixed metallic, out fixed3 specColor, out fixed oneMinusReflectivity)
{
	fixed dielec = 0.04;
	specColor = lerp (fixed3(dielec,dielec,dielec), albedo, metallic);
	oneMinusReflectivity = AKOneMinusReflectivityFromMetallic(metallic,dielec);
	return albedo * oneMinusReflectivity;
}
inline half3 AKDiffuseAndSpecularFromMetallic (fixed3 albedo, fixed metallic, out fixed3 specColor)
{
	fixed dielec = 0.04;
	specColor = lerp (fixed3(dielec,dielec,dielec), albedo, metallic);
	fixed oneMinusReflectivity = AKOneMinusReflectivityFromMetallic(metallic,dielec);
	return albedo * oneMinusReflectivity;
}

//character Skin 
inline fixed SkinFresnel(half vh, fixed F0)
{
	fixed base = 1 - vh;
	fixed fresnel = base * base;
	fresnel *= fresnel;
	fresnel *= base;
	return fresnel + F0 * (1 - fresnel);
}
inline half KS_Skin_Specular(half nl, fixed fresnel, fixed BeckmannTex)
{
	half PH = pow(BeckmannTex * 2, 10);
	fixed spec = max(0, PH * fresnel);
	return spec * nl;
}

inline fixed3 GetOutlineColor(fixed3 texColor, fixed4 outlineColor, fixed saturateFac, fixed brightnessFac)
{
	fixed gray = max(max(texColor.r, texColor.g), texColor.b);
	fixed3 newColor = texColor;
	
	gray -= (1.0 / 255.0);
	fixed3 lerpFac = saturate((newColor - fixed3(gray,gray,gray)) * 255.0);
	newColor = lerp(saturateFac * newColor, newColor, lerpFac);
	
	fixed3 finalColor = brightnessFac * newColor * texColor * outlineColor.rgb;
	return finalColor;
}

#endif // __AK47__
