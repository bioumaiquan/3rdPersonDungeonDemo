using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AKVignette
{
    public PostProcessingMain postSetting = null;

    public void DoVignette(Material finalMaterial)
    {
        finalMaterial.SetColor(ShaderUniforms._Vignette_Color, postSetting.vig_Color);

        float roundness = (1f - postSetting.vig_Roundness) * 6f + postSetting.vig_Roundness;
        finalMaterial.SetVector(ShaderUniforms._Vignette_Settings, new Vector3(postSetting.vig_Intensity * 3f, postSetting.vig_Smoothness * 5f, roundness));
    }
}
