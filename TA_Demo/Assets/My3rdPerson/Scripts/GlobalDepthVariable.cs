using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Camera))]
public class GlobalDepthVariable : MonoBehaviour
{
    public static bool waterDepth = false;
    public static bool focusBlurDepth = false;
    Camera m_Cam;

    bool depthState = false;
    bool DepthState
    {
        get { return depthState; }
        set
        {
            if (depthState != value)
            {
                depthState = value;
                SetCameraDepth();
            }
        }
    }

    private void Start()
    {
        m_Cam = GetComponent<Camera>();
    }

    void LateUpdate ()
    {
        if (waterDepth || focusBlurDepth)
            DepthState = true;
        else
            DepthState = false;
    }

    void SetCameraDepth()
    {
        if (depthState)
            m_Cam.depthTextureMode = DepthTextureMode.Depth;
        else
            m_Cam.depthTextureMode = DepthTextureMode.None;
    }
}
