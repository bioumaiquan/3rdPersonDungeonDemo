using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TaskChatBlurController : MonoBehaviour {

    private void OnEnable()
    {
        if (Shader.globalMaximumLOD == 1000)
        {
            PostProcessingMain.enableTaskChatblur = true;
        }
        else
        {
            PostProcessingMain.enableTaskChatblur = false;
        }
    }

    private void OnDisable()
    {
        PostProcessingMain.enableTaskChatblur = false;
    }

    private void OnDestroy()
    {
        PostProcessingMain.enableTaskChatblur = false;
    }
}
