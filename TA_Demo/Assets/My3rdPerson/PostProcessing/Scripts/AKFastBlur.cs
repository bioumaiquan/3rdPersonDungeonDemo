using UnityEngine;

public class AKFastBlur
{
    RenderTextureFormat rtType = RenderTextureFormat.ARGB32;

    public void DoFastBlur(Material finalMat, Material FastBlurMat, RenderTexture source, int width, int height)
    {
        // Material setup
        float aspect = (float)width / height;
        FastBlurMat.SetFloat(ShaderUniforms._RcpAspect, 1f / aspect);

        //Downsampling
        RenderTexture rt1 = AKPostStuff.rtGet("FastBlur_DownSample", width, height, 0, rtType);
        Graphics.Blit(source, rt1);

        // blur pass
        RenderTexture rt2 = AKPostStuff.rtGet("FastBlur_Blured", width, height, 0, rtType);
        Graphics.Blit(rt1, rt2, FastBlurMat, 0);

        // Give the results to the final material.
        finalMat.SetTexture(ShaderUniforms._BlurTex, rt2);

        AKPostStuff.rtRelease(rt1);
        AKPostStuff.rtRelease(rt2);
    }
}