using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

[ExecuteInEditMode]
public class GlobalShaderParam : MonoBehaviour
{
    #region Variable
    [Tooltip("变色前颜色"), SerializeField]
    Color colorChangeBefor = Color.white;
    [Tooltip("变色后颜色"), SerializeField]
    Color colorChangeAfter = Color.white;
    [Range(0,1), Tooltip("全局天气切换变量"), SerializeField]
    public float WeatherLerp;

    [SerializeField]
    Light mainlight;
    public static Light sceneLight;
    public static Vector3 mainlightRotation;
    //[Range(0, 5), Tooltip("光照强度")]
    //public float lightIntensity = 1f;
    //[Tooltip("光照颜色")]
    //public Color lightColor = Color.white;
    //[Range(0, 1), Tooltip("明暗交界线调整")]
    //public float lightWarp = 0.5f;
    //[Range(0, 1), Tooltip("光照颜色影响角色的强度")]
    //public float lightColorLerp = 1;
    //[Tooltip("环境光颜色")]
    //public Color environmentColor = Color.gray;

    [SerializeField]
    bool fogOn = false;
    [SerializeField]
    Color fogColor1 = Color.gray;
    [SerializeField]
    Color fogColor2 = Color.gray;
    [SerializeField]
    float near = 5;
    [SerializeField]
    float far = 100;
    [SerializeField]
    float top = 20;
    [SerializeField]
    float bottom = -10;
    [SerializeField]
    float characterFogRange = 5;
    [SerializeField, Range(0.01f, 1)]
    float characterFogEdge = 1;

    [SerializeField]
    bool noise = false;
    [SerializeField, Range(0.01f,1), Tooltip("噪声大小")]
    float noiseScale = 0.2f;
    [SerializeField, Tooltip("噪声移动速度")]
    Vector3 noiseSpeed = Vector3.one;
    [SerializeField, Range(0.0f,0.1f), HideInInspector]
    float fogDensity = 0.1f;

    [SerializeField]
    bool SoftOn = false;
    bool softWater = false;
    bool SoftWater
    {
        get { return softWater; }
        set
        {
            if (softWater != value)
            {
                softWater = value;
                SetWaterDepth();
            }
        }
    }

    [SerializeField]
    bool sandSpecularOn = false;
    [SerializeField]
    Texture sandGlitterTexture;
    [SerializeField]
    Material terrainMaterial;
    [Range(50, 200), SerializeField]
    float sandSpecularScale = 75;
    [Range(0,3), SerializeField]
    float sandSpecularIntensity = 1;
    [Range(0.05f, 2), SerializeField]
    float sandSpecularPower = 0.5f;
    [Range(0,2), SerializeField]
    float sandSpecularAdd = 0.5f;

    #region camera cull setting
    [Range(1,500), SerializeField]
    float shadowLayer = 400;
    [Range(1, 500), SerializeField]
    float bigSceneModels = 200;
    [Range(1, 500), SerializeField]
    float smallSceneModels = 100;
    [Range(1,500), HideInInspector]
    float otherLayer = 100;
    float[] cullDistance = new float[32];
    bool CullDisNeedUpdate = true;
    float shadowCull;
    float ShadowCull
    {
        get { return shadowCull; }
        set
        {
            if (shadowCull != value)
            {
                shadowCull = value;
                CullDisNeedUpdate = true;
            }
        }
    }
    float bigCull;
    float BigCull
    {
        get { return bigCull; }
        set
        {
            if (bigCull != value)
            {
                bigCull = value;
                CullDisNeedUpdate = true;
            }
        }
    }
    float smallCull;
    float SmallCull
    {
        get { return smallCull; }
        set
        {
            if (smallCull != value)
            {
                smallCull = value;
                CullDisNeedUpdate = true;
            }
        }
    }
    #endregion
    #endregion

    [SerializeField]
    bool rainOn = false;
    [SerializeField]
    Texture rainDistortTex;
    [SerializeField]
    Color rainSpecColor = Color.white;
    [Range(0.01f,1), SerializeField]
    float rainSpecPower = 0.2f;
    [Range(0,3), SerializeField]
    float rainSpecIntensity = 1;
    [Range(0.01f, 1), SerializeField]
    float rainTexUVScale = 0.28f;
    [Range(0.01f, 1), SerializeField]
    float rainTex2UVScale = 0.53f;
    [SerializeField]
    Vector4 rainFlowSpeed = new Vector4(0, 0.1f, -0.13f, -0.5f);

    Camera m_Cam;

    //global veraible from character
    public static Vector3 characterWorldPos = Vector3.zero;
    public static float characterDistanceWithCamera = 0.0f;
    LayerMask cameraCullingMasks = 1 << 4 | 1 << 8 | 1 << 9 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 20 | 1 << 24 | 1 << 25 | 1 << 28 | 1 << 30;

    private void OnEnable()
    {
        RenderSettings.fog = false;
        mainlightRotation = new Vector3(90, 0, 0);
        m_Cam = Camera.main;
        if (m_Cam != null)
        {
            characterWorldPos = m_Cam.transform.position;
            m_Cam.cullingMask = cameraCullingMasks;
            m_Cam.depth = -2;
        }

        GlobalDepthVariable globalDepthVariable = GetComponent<GlobalDepthVariable>();
        if (globalDepthVariable != null)
        {
            DestroyImmediate(globalDepthVariable);
        }

        SetFog();

        SoftWater = Shader.globalMaximumLOD == 1000 ? SoftOn : false;
        SetWaterDepth();

        SetLightParam();

        SetCameraCullDistance();

        SetRainParam();

        SceneStateCheck();

        DisableShadowInGame();
        QualitySettings.shadows = ShadowQuality.Disable;
    }

    void LateUpdate ()
    {
        m_Cam = Camera.main;

        if (m_Cam != null)
        {
            //向shader传递角色坐标和角色与相机的距离
            characterWorldPos = CharacterStates.CharacterPos;
            characterDistanceWithCamera = GetCharacterDistanceWithCamera(m_Cam);

            Shader.SetGlobalVector(ShaderUniforms.g_CharacterPos, new Vector4(characterWorldPos.x, characterWorldPos.y, characterWorldPos.z, characterDistanceWithCamera));

            //场景中角色身上的 以视角方向偏移出来的一个灯光方向
            float lightOffset = GetCharacterLightOffset(m_Cam);
            Vector3 newCamPos;
            if (PostProcessingMain.enableTaskChatblur)
            {
                newCamPos = m_Cam.transform.TransformPoint(new Vector3(-1.3f, 0.3f, 0));
            }
            else
            {
                newCamPos = m_Cam.transform.TransformPoint(new Vector3(-lightOffset, 0.2f, 0));
            }
            Shader.SetGlobalVector(ShaderUniforms._NewCamPos, newCamPos);
        }

        //场景变色相关
        Shader.SetGlobalFloat(ShaderUniforms.weatherLerp, WeatherLerp);
        Shader.SetGlobalColor(ShaderUniforms._ColorChangeBefor, colorChangeBefor);
        Shader.SetGlobalColor(ShaderUniforms._ColorChangeAfter, colorChangeAfter);

        SoftWater = Shader.globalMaximumLOD == 1000 ? SoftOn : false;

#if UNITY_EDITOR
        SetFog();

        SetLightParam();

        SetCameraCullDistance();

        SetRainParam();
#endif
    }

    void SetFog()
    {
        if (fogOn)
        {
            far = far <= near ? near + 0.01f : far;
            top = top <= bottom ? bottom + 0.01f : top;
            Vector4 g_FogParam = new Vector4(near, far, top, bottom);

            Shader.SetGlobalColor(ShaderUniforms.g_FogColor, fogColor1);
            Shader.SetGlobalColor(ShaderUniforms.g_FogColor2, fogColor2);
            Shader.SetGlobalVector(ShaderUniforms.g_FogParam, g_FogParam);
            Shader.SetGlobalVector(ShaderUniforms.g_NoFogRange, new Vector2(characterFogRange, characterFogEdge));
            Shader.SetGlobalVector(ShaderUniforms.g_FogNoiseFac, new Vector4(noiseScale, noiseSpeed.x, noiseSpeed.y, noiseSpeed.z));
            Shader.EnableKeyword("FOG_ON");

            if (noise)
                Shader.EnableKeyword("ENABLE_NOISE_FOG");
            else
                Shader.DisableKeyword("ENABLE_NOISE_FOG");
        }
        else
        {
            Shader.DisableKeyword("FOG_ON");
        }
    }

    void SetWaterDepth()
    {
        if (softWater)
        {
            GlobalDepthVariable.waterDepth = true;
            Shader.EnableKeyword("DEPTH_ON");
        }
        else
        {
            GlobalDepthVariable.waterDepth = false;
            Shader.DisableKeyword("DEPTH_ON");
        }
    }

    void SetLightParam()
    {
        if (mainlight != null)
        {
            mainlightRotation = mainlight.transform.rotation.eulerAngles;

            Vector3 lightDir = mainlight.transform.rotation * Vector3.back;
            Shader.SetGlobalVector(ShaderUniforms._SceneLightDir, lightDir);
        }

        if (sandSpecularOn)
        {
            Shader.SetGlobalVector(ShaderUniforms._SandGlitterParam, new Vector4(sandSpecularScale, sandSpecularIntensity, sandSpecularPower, sandSpecularAdd));
            Shader.SetGlobalTexture(ShaderUniforms._SandGlitterTex, sandGlitterTexture);
            if (terrainMaterial != null)
                terrainMaterial.EnableKeyword("ENABLE_SANDSPEC");
        }
        else
        {
            if (terrainMaterial != null)
                terrainMaterial.DisableKeyword("ENABLE_SANDSPEC");
        }
    }

    void SetCameraCullDistance()
    {
        BigCull = bigSceneModels;
        SmallCull = smallSceneModels;
        ShadowCull = shadowLayer;
        if (CullDisNeedUpdate)
        {
            if (m_Cam != null)
            {
                for (int i = 0; i < cullDistance.Length; i++)
                    cullDistance[i] = 100; //cullDistance[i] = otherLayer;

                cullDistance[25] = 0; //sky 
                cullDistance[9] = bigCull; //big models 
                cullDistance[8] = smallCull; //small models
                cullDistance[28] = bigCull; //can be reflected models
                cullDistance[24] = shadowCull; // ground 
                cullDistance[4] = shadowCull; // water
                m_Cam.layerCullSpherical = true;
                m_Cam.layerCullDistances = cullDistance;
            }
            CullDisNeedUpdate = false;
        }
    }

    float GetCharacterDistanceWithCamera(Camera cam)
    {
        if (cam != null)
        {
            Vector3 charPos = characterWorldPos;
            Vector3 camPos = cam.transform.position;
            camPos.z += cam.nearClipPlane;

            return (charPos - camPos).magnitude;
        }
        else
        {
            return 0.0f;
        }
    }

    float GetCharacterLightOffset(Camera cam)
    {
        if (cam != null)
        {
            Vector3 charPos = characterWorldPos + new Vector3(0, 1.3f, 0);
            Vector3 camPos = cam.transform.position;
            camPos.z += cam.nearClipPlane;
            float distance = (charPos - camPos).magnitude;

            float offset = distance * distance / 15;
            offset = Mathf.Max(1f, offset);

            return offset;
        }
        else
        {
            return 2f;
        }
    }

    void SceneStateCheck()
    {
        string sceneName = SceneManager.GetActiveScene().name;

        if (mainlight != null)
        {
            sceneLight = mainlight;
        }
        else
        {
            Debug.LogError("通知场景美术, 当前场景 " + sceneName + " 的3Dlayer没加灯");
        }
    }

    void DisableShadowInGame()
    {
        Renderer[] renderers = gameObject.GetComponentsInChildren<Renderer>();
        if (renderers != null)
        {
            for (int i = 0; i < renderers.Length; i++)
            {
                renderers[i].shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                renderers[i].receiveShadows = false;
            }
        }

        GameObject go = GameObject.Find("shadow");
        if (go == null) return;

        Transform shadow = go.GetComponent<Transform>();
        if (shadow == null) return;

        Renderer[] shadowRenderers = shadow.GetComponentsInChildren<Renderer>();
        if (shadowRenderers == null) return;

        for (int i = 0; i < shadowRenderers.Length; i++)
        {
            shadowRenderers[i].receiveShadows = true;
        }
    }

    void SetRainParam()
    {
        if (rainOn)
        {
            Shader.SetGlobalColor(ShaderUniforms.g_RainSpecColor, rainSpecColor);
            Shader.SetGlobalVector(ShaderUniforms.g_RainSpec, new Vector4(rainSpecPower, rainSpecIntensity, rainTexUVScale, rainTex2UVScale));
            Shader.SetGlobalTexture(ShaderUniforms.g_RainDistortTex, rainDistortTex);
            Shader.SetGlobalVector(ShaderUniforms.g_RainFlowSpeed, rainFlowSpeed);
        }
    }
}

