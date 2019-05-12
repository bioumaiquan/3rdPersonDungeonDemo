using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AKPostRain
{
    public PostProcessingMain postSetting = null;

    public void DoRain(Material finalMaterial, Texture2D distortTex)
    {
        finalMaterial.SetTexture(ShaderUniforms._PostRainDistortTex, distortTex);
        finalMaterial.SetVector(ShaderUniforms._PostRainParam, new Vector2(postSetting.rainFlowSpeed, postSetting.rainDistortScale));
    }
}
