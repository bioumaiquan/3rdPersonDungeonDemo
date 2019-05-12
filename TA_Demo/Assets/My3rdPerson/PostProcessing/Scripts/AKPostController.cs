using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class AKPostController : MonoBehaviour
{
    PostProcessingMain postProcessing;
    Camera m_Cam;
    [HideInInspector]
    public LayerMask cameraCullingMasks = 1 << 0 | 1 << 4 | 1 << 8 | 1 << 9 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 20 | 1 << 24 | 1 << 25 | 1 << 28;
    Light sceneLight;

    enum QualityLevel
    {
        High,
        Medium,
        Low,
    }
    QualityLevel level = QualityLevel.High;
    QualityLevel Level
    {
        get { return level; }
        set
        {
            if (level != value)
            {
                level = value;
                SetPostProcessing(level);
            }
        }
    }

    //bool camEnable;
    //bool CamEnable
    //{
    //    get { return camEnable; }
    //    set
    //    {
    //        if (camEnable != value)
    //        {
    //            camEnable = value;
    //            GUICameraClearController.keepBuffer = !camEnable;
    //        }
    //    }
    //}

    private void Start()
    {
        postProcessing = GetComponent<PostProcessingMain>();
        m_Cam = GetComponent<Camera>();
        m_Cam.nearClipPlane = 1;

        if (postProcessing != null)
        {
            if (Shader.globalMaximumLOD == 1000)
                level = QualityLevel.High;

            if (Shader.globalMaximumLOD == 500)
                level = QualityLevel.Medium;

            if (Shader.globalMaximumLOD == 300)
                level = QualityLevel.Low;

            SetPostProcessing(level);
        }
        else
        {
            Debug.LogError("当前场景 " + SceneManager.GetActiveScene().name + " 没有获取到后处理脚本");
        }

        //sceneLight = GlobalShaderParam.sceneLight;
        //if (sceneLight != null)
        //{
        //    sceneLight.cullingMask = 1 << 8 | 1 << 9 | 1 << 24 | 1 << 28;
        //    sceneLight.shadows = LightShadows.None;
        //}
    }

    private void LateUpdate()
    {
        //CamEnable = m_Cam.isActiveAndEnabled ? true : false;

        if (postProcessing != null)
        {
            GetQualityLevel();

            if (level == QualityLevel.Low)
            {
                postProcessing.enabled = PostProcessingMain.enableFastBlur ? true : false;
            }
        }

        //prerender之前开启相机更新
        if (!PostProcessingMain.enableFastBlur)
        {
            m_Cam.clearFlags = CameraClearFlags.SolidColor;
            m_Cam.cullingMask = cameraCullingMasks;
        }
    }

    float time;
    private void OnPostRender()
    {
        //延迟1帧再停止相机更新
        if (PostProcessingMain.enableFastBlur)
        {
            time += Time.deltaTime;
            if (time > Time.deltaTime)
            {
                m_Cam.clearFlags = CameraClearFlags.Nothing;
                m_Cam.cullingMask = 0;
                time = 0;
            }
        }
    }

    void GetQualityLevel()
    {
        if (Shader.globalMaximumLOD == 1000)
            Level = QualityLevel.High;

        if (Shader.globalMaximumLOD == 500)
            Level = QualityLevel.Medium;

        if (Shader.globalMaximumLOD == 300)
            Level = QualityLevel.Low;
    }

    void SetPostProcessing(QualityLevel level)
    {
        switch (level)
        {
            case QualityLevel.High:
                postProcessing.enabled = true;
                postProcessing.enableBloom = true;
                postProcessing.enableDOF = true;
                postProcessing.DOFRange = 2.0f;
                postProcessing.DOFBlur = 0.5f;
                postProcessing.enableMSAA = false;
                break;
            case QualityLevel.Medium:
                postProcessing.enabled = true;
                postProcessing.enableBloom = true;
                postProcessing.enableMSAA = false;
                break;
            case QualityLevel.Low:
                //postProcessing.enabled = false;
                postProcessing.enableBloom = false;
                postProcessing.enableMSAA = false;
                break;
        }
    }
}
