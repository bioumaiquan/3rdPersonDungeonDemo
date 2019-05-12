using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FastBlurController : MonoBehaviour
{
    private void OnEnable()
    {
        PostProcessingMain.enableFastBlur = true;
    }

    private void OnDisable()
    {
        PostProcessingMain.enableFastBlur = false;
    }

    private void OnDestroy()
    {
        PostProcessingMain.enableFastBlur = false;
    }
}
