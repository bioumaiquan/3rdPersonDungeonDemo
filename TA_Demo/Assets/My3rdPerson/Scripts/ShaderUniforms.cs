using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 脚本传入shader的全局变量
/// </summary>
public class ShaderUniforms
{
    /// <summary>
    /// 切换场景天气变换的值
    /// </summary>
    internal static readonly int weatherLerp = Shader.PropertyToID("weatherLerp");
    /// <summary>
    /// 场景天气变换前的整体色调
    /// </summary>
    internal static readonly int _ColorChangeBefor = Shader.PropertyToID("_ColorChangeBefor");
    /// <summary>
    /// 场景天气变换后的整体色调
    /// </summary>
    internal static readonly int _ColorChangeAfter = Shader.PropertyToID("_ColorChangeAfter");
    /// <summary>
    /// 玩家当前世界坐标
    /// </summary>
    internal static readonly int g_CharacterPos = Shader.PropertyToID("g_CharacterPos");
    /// <summary>
    /// 场景天气变换前的雾颜色
    /// </summary>
    internal static readonly int g_FogColor = Shader.PropertyToID("g_FogColor");
    /// <summary>
    /// 场景天气变换后的雾颜色
    /// </summary>
    internal static readonly int g_FogColor2 = Shader.PropertyToID("g_FogColor2");
    /// <summary>
    /// 雾效参数 x = near, y = far, z = top, w = bottom
    /// </summary>
    internal static readonly int g_FogParam = Shader.PropertyToID("g_FogParam");
    /// <summary>
    /// 以玩家为中心点, 不产生雾的参数 x = 以玩家为中心点不产生雾的距离, y = 有雾和没有雾的过度效果
    /// </summary>
    internal static readonly int g_NoFogRange = Shader.PropertyToID("g_NoFogRange");
    /// <summary>
    /// 噪声雾的参数, x = 噪声的缩放, zyw = 世界坐标xyz方向的噪声移动速度
    /// </summary>
    internal static readonly int g_FogNoiseFac = Shader.PropertyToID("g_FogNoiseFac");
    /// <summary>
    /// 场景灯光方向
    /// </summary>
    internal static readonly int _SceneLightDir = Shader.PropertyToID("_SceneLightDir");
    /// <summary>
    /// 以当前相机坐标为基础, 偏移一个值的新坐标
    /// </summary>
    internal static readonly int _NewCamPos = Shader.PropertyToID("_NewCamPos");
    /// <summary>
    /// 沙漠场景的沙子反光参数 x = 噪点贴图的缩放值, y = 高光强度, z = 高光power, w = 额外的闪烁高光强度
    /// </summary>
    internal static readonly int _SandGlitterParam = Shader.PropertyToID("_SandGlitterParam");
    /// <summary>
    /// 沙漠场景的沙子反光用的噪点贴图
    /// </summary>
    internal static readonly int _SandGlitterTex = Shader.PropertyToID("_SandGlitterTex");

    /// <summary>
    /// 场景下雨时的高光颜色
    /// </summary>
    internal static readonly int g_RainSpecColor = Shader.PropertyToID("g_RainSpecColor");
    /// <summary>
    /// 场景下雨时的高光参数, x = sepc power, y = sepc intensity
    /// </summary>
    internal static readonly int g_RainSpec = Shader.PropertyToID("g_RainSpec");
    /// <summary>
    /// 场景下雨时的高光扭曲贴图
    /// </summary>
    internal static readonly int g_RainDistortTex = Shader.PropertyToID("g_RainDistortTex");
    /// <summary>
    /// 场景下雨时的高光流动速度
    /// </summary>
    internal static readonly int g_RainFlowSpeed = Shader.PropertyToID("g_RainFlowSpeed");

    /// <summary>
    /// 默认shader的颜色属性
    /// </summary>
    internal static readonly int _TintColor = Shader.PropertyToID("_TintColor");

    /// <summary>
    /// 场景的风向, xz = 风向 y = 风速 z = 风力
    /// </summary>
    internal static readonly int g_WindDir = Shader.PropertyToID("g_WindDir");

    //HDR Bloom
    internal static readonly int _Threshold = Shader.PropertyToID("_Threshold");
    internal static readonly int _Curve = Shader.PropertyToID("_Curve");
    internal static readonly int _BaseTex = Shader.PropertyToID("_BaseTex");
    internal static readonly int _BloomTex = Shader.PropertyToID("_BloomTex");
    internal static readonly int _Bloom_Settings = Shader.PropertyToID("_Bloom_Settings");

    //Color Grading
    internal static readonly int _LutParams = Shader.PropertyToID("_LutParams");
    internal static readonly int _HueShift = Shader.PropertyToID("_HueShift");
    internal static readonly int _Saturation = Shader.PropertyToID("_Saturation");
    internal static readonly int _Contrast = Shader.PropertyToID("_Contrast");
    internal static readonly int _Balance = Shader.PropertyToID("_Balance");
    internal static readonly int _LogLut = Shader.PropertyToID("_LogLut");
    internal static readonly int _LogLut_Params = Shader.PropertyToID("_LogLut_Params");
    internal static readonly int _ExposureEV = Shader.PropertyToID("_ExposureEV");

    //Depth of field
    internal static readonly int _DOFTex = Shader.PropertyToID("_DOFTex");
    internal static readonly int _RcpAspect = Shader.PropertyToID("_RcpAspect");
    internal static readonly int _MaxCoC = Shader.PropertyToID("_MaxCoC");
    internal static readonly int _DOFBlur = Shader.PropertyToID("_DOFBlur");
    internal static readonly int _DOFRange = Shader.PropertyToID("_DOFRange");
    internal static readonly int _DOFDistance = Shader.PropertyToID("_DOFDistance");
    internal static readonly int _ClearDistance = Shader.PropertyToID("_ClearDistance");

    //Fast Blur
    internal static readonly int _BlurTex = Shader.PropertyToID("_BlurTex");

    //vignette
    internal static readonly int _Vignette_Color = Shader.PropertyToID("_Vignette_Color");
    internal static readonly int _Vignette_Settings = Shader.PropertyToID("_Vignette_Settings");

    //rain
    internal static readonly int _PostRainDistortTex = Shader.PropertyToID("_PostRainDistortTex");
    internal static readonly int _PostRainParam = Shader.PropertyToID("_PostRainParam");

    internal static readonly int _CharacterPos = Shader.PropertyToID("_CharacterPos");
    internal static readonly int _SrcBlend = Shader.PropertyToID("_SrcBlend");
    internal static readonly int _DstBlend = Shader.PropertyToID("_DstBlend");
    internal static readonly int _ZWrite = Shader.PropertyToID("_ZWrite");

    internal static readonly int _DissolveFactor = Shader.PropertyToID("_DissolveFactor");
    internal static readonly int _Alpha = Shader.PropertyToID("_Alpha");

    //UI Particle
    internal static readonly int _ClipRect = Shader.PropertyToID("_ClipRect");
    internal static readonly int _ClipParam = Shader.PropertyToID("_ClipParam");

    //UI RenderTexture
    internal static readonly int _UILightDir = Shader.PropertyToID("_UILightDir");
    internal static readonly int _UIShadowColor = Shader.PropertyToID("_UIShadowColor");
}
