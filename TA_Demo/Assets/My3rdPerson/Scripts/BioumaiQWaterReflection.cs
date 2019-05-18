using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BioumaiQWaterReflection : MonoBehaviour {

    public bool isReflection = false;

    [Range(1,200)]
    public float waterReflectionCullDistance = 100;
    bool CullDistanceNeedUpdate = true;
    float distance;
    float Distance
    {
        get { return distance; }
        set
        {
            if (distance != value)
            {
                distance = value;
                CullDistanceNeedUpdate = true;
            }
        }
    }
    private float[] cullDistance = new float[32];

    public int textureSize = 512;
    public float clipPlaneOffset = -1.0f;
    [Range(0,5)]
    public float reflIntensity = 2;
    public LayerMask reflectLayers = 1<<28|1<<25;

    private Dictionary<Camera, Camera> m_ReflectionCameras = new Dictionary<Camera, Camera>(); // Camera -> Camera table
    private RenderTexture m_ReflectionTexture;
    private int m_OldReflectionTextureSize;
    private static bool s_InsideWater;

    // This is called when it's known that the object will be rendered by some
    // camera. We render reflections / refractions and do other updates here.
    // Because the script executes in edit mode, reflections for the scene view
    // camera will just work!
    public void OnWillRenderObject()
    {
        if (!GetComponent<Renderer>() || !GetComponent<Renderer>().sharedMaterial ||
            !GetComponent<Renderer>().enabled)
        {
            return;
        }

        if (Shader.globalMaximumLOD < 500)
        {
            return;
        }

        Camera cam = Camera.current;

        if (!cam)
        {
            return;
        }

        if (s_InsideWater)
        {
            return;
        }
        s_InsideWater = true;

        Material material = GetComponent<Renderer>().sharedMaterial;

        Camera reflectionCamera;
        CreateWaterObjects(cam, out reflectionCamera);

        // find out the reflection plane: position and normal in world space
        Vector3 pos = transform.position;
        Vector3 normal = new Vector3(0f, 1f, 0f);

        UpdateCameraModes(cam, reflectionCamera);

        if (isReflection == false)
        {
            material.DisableKeyword("ENABLE_REFLECTIVE");
            if (m_ReflectionTexture)
            {
                DestroyImmediate(m_ReflectionTexture);
                m_ReflectionTexture = null;
            }
            foreach (var kvp in m_ReflectionCameras)
            {
                DestroyImmediate((kvp.Value).gameObject);
            }
            m_ReflectionCameras.Clear();
        }
        else
        {
            // Reflect camera around reflection plane
            float d = -Vector3.Dot(normal, pos);// - clipPlaneOffset;
            Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);

            Matrix4x4 reflection = Matrix4x4.zero;
            CalculateReflectionMatrix(ref reflection, reflectionPlane);
            Vector3 oldpos = cam.transform.position;
            Vector3 newpos = reflection.MultiplyPoint(oldpos);
            reflectionCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflection;

            // Setup oblique projection matrix so that near plane is our reflection
            // plane. This way we clip everything below/above it for free.
            Vector4 clipPlane = CameraSpacePlane(reflectionCamera, pos, normal, 1.0f);
            reflectionCamera.projectionMatrix = cam.CalculateObliqueMatrix(clipPlane);

            reflectionCamera.cullingMask = ~(1 << 4) & reflectLayers.value; // never render water layer
            reflectionCamera.targetTexture = m_ReflectionTexture;
            bool oldCulling = GL.invertCulling;
            GL.invertCulling = !oldCulling;
            reflectionCamera.transform.position = newpos;
            Vector3 euler = cam.transform.eulerAngles;
            reflectionCamera.transform.eulerAngles = new Vector3(-euler.x, euler.y, euler.z);
            reflectionCamera.Render();
            reflectionCamera.transform.position = oldpos;
            GL.invertCulling = oldCulling;
            material.SetTexture("_ReflectionTex", m_ReflectionTexture);
            //material.SetFloat("_RealDistortIntensity", reflIntensity);
            //material.EnableKeyword("ENABLE_REFLECTIVE");
        }

        s_InsideWater = false;
    }

    // Cleanup all the objects we possibly have created
    void OnDisable()
    {
        if (m_ReflectionTexture)
        {
            DestroyImmediate(m_ReflectionTexture);
            m_ReflectionTexture = null;
        }
        foreach (var kvp in m_ReflectionCameras)
        {
            DestroyImmediate((kvp.Value).gameObject);
        }
        m_ReflectionCameras.Clear();
    }

    void UpdateCameraModes(Camera src, Camera dest)
    {
        if (dest == null)
        {
            return;
        }
        // set water camera to clear the same way as current camera
        dest.clearFlags = src.clearFlags;
        dest.backgroundColor = src.backgroundColor;
        dest.nearClipPlane = src.nearClipPlane;
        dest.orthographic = src.orthographic;
        dest.fieldOfView = src.fieldOfView;
        dest.aspect = src.aspect;
        dest.orthographicSize = src.orthographicSize;

        Distance = waterReflectionCullDistance;
        if (CullDistanceNeedUpdate)
            UpdateCullDistance(dest);

        //if (src.clearFlags == CameraClearFlags.Skybox)
        //{
        //    Skybox sky = src.GetComponent<Skybox>();
        //    Skybox mysky = dest.GetComponent<Skybox>();
        //    if (!sky || !sky.material)
        //    {
        //        mysky.enabled = false;
        //    }
        //    else
        //    {
        //        mysky.enabled = true;
        //        mysky.material = sky.material;
        //    }
        //}
        // update other values to match current camera.
        // even if we are supplying custom camera&projection matrices,
        // some of values are used elsewhere (e.g. skybox uses far plane)
    }

    void UpdateCullDistance(Camera cam)
    {
        for (int i = 0; i < cullDistance.Length; i++)
            cullDistance[i] = Distance;
        cullDistance[25] = 0; //sky 
        cullDistance[24] = 300; // ground 

        cam.layerCullSpherical = true;
        cam.layerCullDistances = cullDistance;
        CullDistanceNeedUpdate = false;
    }

    // On-demand create any objects we need for water
    void CreateWaterObjects(Camera currentCamera, out Camera reflectionCamera)
    {
        reflectionCamera = null;

        if (isReflection)
        {
            // Reflection render texture
            if (!m_ReflectionTexture || m_OldReflectionTextureSize != textureSize)
            {
                if (m_ReflectionTexture)
                    DestroyImmediate(m_ReflectionTexture);
                m_ReflectionTexture = new RenderTexture(textureSize, textureSize, 16, RenderTextureFormat.ARGBHalf);
                m_ReflectionTexture.name = "__WaterReflection" + GetInstanceID();
                m_ReflectionTexture.isPowerOfTwo = true;
                m_ReflectionTexture.hideFlags = HideFlags.DontSave;
                m_OldReflectionTextureSize = textureSize;
            }

            // Camera for reflection
            m_ReflectionCameras.TryGetValue(currentCamera, out reflectionCamera);
            if (!reflectionCamera) // catch both not-in-dictionary and in-dictionary-but-deleted-GO
            {
                GameObject go = new GameObject("Water Refl Camera id" + GetInstanceID() + " for " + currentCamera.GetInstanceID(), typeof(Camera), typeof(Skybox));
                reflectionCamera = go.GetComponent<Camera>();
                reflectionCamera.enabled = false;
                reflectionCamera.transform.position = transform.position;
                reflectionCamera.transform.rotation = transform.rotation;
                reflectionCamera.depthTextureMode = DepthTextureMode.None;
                //reflectionCamera.gameObject.AddComponent<FlareLayer>();
                go.hideFlags = HideFlags.HideAndDontSave;
                m_ReflectionCameras[currentCamera] = reflectionCamera;
            }
        }
    }

    // Given position/normal of the plane, calculates plane in camera space.
    Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
    {
        Vector3 offsetPos = pos + normal * clipPlaneOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint(offsetPos);
        Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }

    // Calculates reflection matrix around the given plane
    static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
    {
        reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2F * plane[1] * plane[0]);
        reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2F * plane[2] * plane[1]);
        reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2F * plane[3] * plane[2]);

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;
    }
}
