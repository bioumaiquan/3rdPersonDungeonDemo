using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[ImageEffectAllowedInSceneView, ExecuteInEditMode, RequireComponent(typeof(Camera))]
[ExecuteInEditMode, RequireComponent(typeof(Camera))]
public class PostProcessingMain : MonoBehaviour
{
    #region Bloom Variable
    [Header("光晕")]
    public bool enableBloom = false;
    [Range(1, 4.75f), Tooltip("发光范围, 数值越大越消耗性能")]
    public float bloomRadius = 3;
    [Range(0,5), Tooltip("发光强度")]
    public float bloomIntensity = 1;
    [Range(0,4), Tooltip("发光阈值")]
    public float bloomThreshold = 1;
    [Range(0,1), Tooltip("发光的模糊的边缘强度")]
    public float bloomSoftKnee = 0.5f;

    private bool supportDHR;
    private bool bloom;
    bool EnableBloom
    {
        get { return bloom; }
        set
        {
            if (bloom != value)
            {
                renderTargetNeedInit = true;
            }
            bloom = value;
        }
    }
    #endregion

    #region DOF Variable
    [Header("景深")]
    public bool enableDOF = false;
    public bool enableDOFDebug = false;
    [Tooltip("景深的模糊程度"), Range(0f,3f)]
    public float DOFBlur = 1;
    [Tooltip("景深效果的清晰区域的距离")]
    public float DOFRange = 1;
    [Tooltip("微调角色周围的清晰范围"), Range(-0.01f,0.01f)]
    public float DOFDistance = 0;
    #endregion

    #region color gradian variable
    [Header("色彩调整")]
    public bool enableColorGrading = false;
    [Tooltip("曝光值")]
    public float CG_exposure = 0;
    [Tooltip("白平衡 - 色温"), Range(-100,100)]
    public float CG_Temperature = 0;
    [Tooltip("白平衡 - 调整绿色或品红的色偏"), Range(-100,100)]
    public float CG_tint;
    [Tooltip("色相"), Range(-180, 180)]
    public float CG_HUE = 0;
    [Tooltip("饱和度"), Range(0, 2)]
    public float CG_Saturation = 1;
    [Tooltip("对比度"), Range(0, 2)]
    public float CG_Contrast = 1;
    #endregion

    #region vignette variable
    [Header("暗角")]
    public bool enableVignette = false;
    public Color vig_Color = Color.black;
    [Range(0,1)]
    public float vig_Intensity = 0.55f;
    [Range(0.01f, 1)]
    public float vig_Smoothness = 0.88f;
    [Range(0, 1)]
    public float vig_Roundness = 0.8f;
    #endregion

    #region FastBlur
    public static bool enableFastBlur = false;  //UI面板开启后为true
    public static bool enableTaskChatblur = false; //剧情对话时为true
    #endregion

    [Header("抗锯齿")]
    public bool enableMSAA = false;
    private bool aa;
    bool EnableMSAA
    {
        get { return aa; }
        set
        {
            if (aa != value)
            {
                renderTargetNeedInit = true;
            }
            aa = value;
        }
    }

    [Header("下雨")]
    public bool enableRain = false;
    [Range(0,0.3f)]
    public float rainDistortScale = 0.1f;
    [Range(0,3)]
    public float rainFlowSpeed = 1;
    Texture2D rainDistortTex;

    [HideInInspector]
    public AKPostController p_Controller;

    AKHDRBloom p_Bloom;
    AKDepthOfField p_DOF;
    AKColorGrading p_ColorGrading;
    AKVignette p_Vignette;
    AKFastBlur p_FastBlur;
    AKPostRain p_Rain;
    Camera cam;
    Material p_FinalMat = null;
    Material p_BloomMat = null;
    Material p_DOFMat = null;
    Material p_LUTMat = null;
    Material p_FastBlurMat = null;

    RenderTexture renderTarget = null;
    int fullWidth = 1920;
    int fullHeight = 1080;
    int halfWidth, halfHeight, quarterWidth, quarterHeight;
    bool renderTargetNeedInit = true;

    private void OnEnable()
    {
        p_Bloom = new AKHDRBloom();
        p_Bloom.postSetting = this;
        p_DOF = new AKDepthOfField();
        p_DOF.postSetting = this;
        p_ColorGrading = new AKColorGrading();
        p_ColorGrading.postSetting = this;
        p_Vignette = new AKVignette();
        p_Vignette.postSetting = this;
        p_FastBlur = new AKFastBlur();
        p_Rain = new AKPostRain();
        p_Rain.postSetting = this;

        GlobalDepthVariable depthController = GetComponent<GlobalDepthVariable>();
        if (depthController == null)
        {
            depthController = gameObject.AddComponent<GlobalDepthVariable>();
        }

        cam = GetComponent<Camera>();
        if (cam != null)
        {
            cam.allowHDR = false;
            cam.allowMSAA = false;
        }

        p_FinalMat = AKPostStuff.GetMaterial(p_FinalMat, "Hidden/PostEffect/PostFinalBlend");

        fullWidth = Screen.width;
        fullHeight = Screen.height;

#if UNITY_EDITOR
        fullWidth = cam.pixelWidth;
        fullHeight = cam.pixelHeight;
#endif

        halfWidth = fullWidth >> 1;
        halfHeight = fullHeight >> 1;
        quarterWidth = halfWidth >> 1;
        quarterHeight = halfHeight >> 1;

        supportDHR = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf) ? true : false;

        RenderTargetInitializer();
        renderTargetNeedInit = false;
    }

    private void OnPreRender()
    {
        if (cam == null)
        {
            cam = GetComponent<Camera>();
        }

        if (!enableFastBlur)
        {
            EnableMSAA = enableMSAA;
            EnableBloom = supportDHR ? enableBloom : false;

            if (renderTargetNeedInit)
            {
                ReleaseRenderTarget();
                RenderTargetInitializer();
                renderTargetNeedInit = false;
            }
        }

        cam.targetTexture = renderTarget;
    }

    private void OnPostRender()
    {
        cam.targetTexture = null;

        //后处理
        //FastBlurPass();
        //BloomPass();
        //DOFPass();
        //ColorGradingPass();
        //VignettePass();
        //Rain();
        //end

        if (p_FinalMat == null)
        {
            Debug.LogError("final mat is null");
        }
        Graphics.Blit(renderTarget, p_FinalMat);
    }

    private void OnDisable()
    {
        ClearMaterial();
        ReleaseRenderTarget();
        rainDistortTex = null;
    }

    private void OnDestroy()
    {
        ClearMaterial();
        ReleaseRenderTarget();
        if (renderTarget != null)
        {
            Destroy(renderTarget);
        }
    }

    void ClearMaterial()
    {
        if (p_BloomMat)
            DestroyImmediate(p_BloomMat);

        if (p_DOFMat)
            DestroyImmediate(p_DOFMat);

        if (p_LUTMat)
            DestroyImmediate(p_LUTMat);

        if (p_FinalMat)
            DestroyImmediate(p_FinalMat);

        if (p_FastBlurMat)
            DestroyImmediate(p_FastBlurMat);
    }

    void ReleaseRenderTarget()
    {
        if (cam != null)
        {
            cam.targetTexture = null;
        }

        if (renderTarget != null)
        {
            renderTarget.Release();
            renderTarget = null;
        }
        renderTargetNeedInit = true;
    }

    void RenderTargetInitializer()
    {
        RenderTextureFormat rtf = supportDHR ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32;
        string msaalevel = aa ? "8xMSAA" : "MSAAoff";

        renderTarget = new RenderTexture(fullWidth, fullHeight, 24, rtf, RenderTextureReadWrite.Linear)
        {
            antiAliasing = aa ? 8 : 2,
            name = "AKPost_RenderTarget_" + msaalevel,
            filterMode = FilterMode.Bilinear,
            wrapMode = TextureWrapMode.Clamp
        };
        renderTarget.Create();
    }

    // 光晕
    void BloomPass()
    {
        if (bloom && p_Bloom.postSetting.bloomIntensity > 0 && !enableFastBlur)
        {
            p_BloomMat = AKPostStuff.GetMaterial(p_BloomMat, "Hidden/PostEffect/FXFastBloom");
            p_Bloom.DoBloom(p_FinalMat, p_BloomMat, renderTarget, halfWidth, halfHeight);
            p_FinalMat.EnableKeyword("ENABLE_AKPOST_BLOOM");
        }
        else
        {
            p_FinalMat.DisableKeyword("ENABLE_AKPOST_BLOOM");
            if (p_BloomMat != null)
                DestroyImmediate(p_BloomMat);
        }
    }

    //景深
    void DOFPass()
    {
        if ((enableDOF && !enableFastBlur) || enableTaskChatblur)
        {
            GlobalDepthVariable.focusBlurDepth = true;
            if (enableDOFDebug)
                p_FinalMat.EnableKeyword("ENABLE_AKPOST_DOF_DEBUG");
            else
                p_FinalMat.DisableKeyword("ENABLE_AKPOST_DOF_DEBUG");

            p_DOFMat = AKPostStuff.GetMaterial(p_DOFMat, "Hidden/PostEffect/DepthOfField");
            p_FinalMat.EnableKeyword("ENABLE_AKPOST_DOF");

            p_DOF.DoDOF(p_FinalMat, p_DOFMat, renderTarget, cam, halfWidth, halfHeight);
        }
        else
        {
            GlobalDepthVariable.focusBlurDepth = false;
            p_FinalMat.DisableKeyword("ENABLE_AKPOST_DOF");
            if (p_DOFMat != null)
                DestroyImmediate(p_DOFMat);
        }
    }

    //色彩调整
    void ColorGradingPass()
    {
        if (enableColorGrading)
        {
            p_LUTMat = AKPostStuff.GetMaterial(p_LUTMat, "Hidden/PostEffect/GenerateLut");
            p_FinalMat.EnableKeyword("ENABLE_AKPOST_COLORGRADING");
            p_ColorGrading.DoColorGrading(p_FinalMat, p_LUTMat, renderTarget);
        }
        else
        {
            p_FinalMat.DisableKeyword("ENABLE_AKPOST_COLORGRADING");
            if (p_LUTMat != null)
                DestroyImmediate(p_LUTMat);
        }
    }

    //暗角
    void VignettePass()
    {
        if (enableVignette && p_Vignette.postSetting.vig_Intensity > 0)
        {
            p_FinalMat.EnableKeyword("ENABLE_AKPOST_VIGNETTE");
            p_Vignette.DoVignette(p_FinalMat);
        }
        else
        {
            p_FinalMat.DisableKeyword("ENABLE_AKPOST_VIGNETTE");
        }
    }

    //UI用 快速模糊
    void FastBlurPass()
    {
        if (enableFastBlur)
        {
            if (Shader.globalMaximumLOD > 300) //低配下不做模糊, 只保留frame buffer
            {
                p_FastBlurMat = AKPostStuff.GetMaterial(p_FastBlurMat, "Hidden/PostEffect/FastBlur");
                p_FinalMat.EnableKeyword("ENABLE_AKPOST_FASTBLUR");
                p_FastBlur.DoFastBlur(p_FinalMat, p_FastBlurMat, renderTarget, halfWidth, halfHeight);
            }
            else
            {
                p_FinalMat.DisableKeyword("ENABLE_AKPOST_FASTBLUR");
            }
        }
        else
        {
            p_FinalMat.DisableKeyword("ENABLE_AKPOST_FASTBLUR");
            if (p_FastBlurMat != null)
                DestroyImmediate(p_FastBlurMat);
        }
    }

    //下雨镜头水流
    void Rain()
    {
        if (enableRain)
        {
            p_FinalMat.EnableKeyword("ENABLE_AKPOST_RAIN");

            if (rainDistortTex == null)
            {
                rainDistortTex = Resources.Load<Texture2D>("Textures/ak_Post_Rain");
            }

            p_Rain.DoRain(p_FinalMat, rainDistortTex);

        }
        else
        {
            p_FinalMat.DisableKeyword("ENABLE_AKPOST_RAIN");
        }
    }
}
