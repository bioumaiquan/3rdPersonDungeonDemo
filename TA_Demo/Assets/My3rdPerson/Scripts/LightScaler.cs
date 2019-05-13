using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class LightScaler : MonoBehaviour
{
    public bool scale = false;
    Light[] lights = null;

    // Update is called once per frame
    void Update()
    {
        if (scale == true)
        {
            lights = null;
            lights = GetComponentsInChildren<Light>();

            for (int i = 0; i < lights.Length; i++)
            {
                lights[i].range *= gameObject.transform.localScale.x;
            }

            scale = false;
        }
    }
}
