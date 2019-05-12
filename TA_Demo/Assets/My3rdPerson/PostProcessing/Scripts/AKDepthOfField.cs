using UnityEngine;

public class AKDepthOfField
{
    public PostProcessingMain postSetting = null;

    RenderTextureFormat rtType = RenderTextureFormat.ARGB32;
    const float k_FilmHeight = 0.024f;
    float blur, range, distance;

    public void DoDOF(Material finalMat, Material DOFMat, RenderTexture source, Camera cam, int width, int height)
    {

        if (PostProcessingMain.enableTaskChatblur)
        {
            blur = 1.5f;
            range = 30;
            distance = 0.007f;
        }
        else
        {
            blur = postSetting.DOFBlur;
            range = postSetting.DOFRange;
            distance = postSetting.DOFDistance;
        }
        
        // Material setup
        float aspect = (float)width / height;
        DOFMat.SetFloat(ShaderUniforms._RcpAspect, 1f / aspect);
        DOFMat.SetFloat(ShaderUniforms._DOFBlur, blur);
        DOFMat.SetFloat(ShaderUniforms._MaxCoC, 0.00556f);

        //Downsampling
        RenderTexture rt1 = AKPostStuff.rtGet("DOF", width, height, 0, rtType);
        Graphics.Blit(source, rt1);

        // blur pass
        RenderTexture rt2 = AKPostStuff.rtGet("DOF", width, height, 0, rtType);
        Graphics.Blit(rt1, rt2, DOFMat, 0);

        // Postfilter pass
        Graphics.Blit(rt2, rt1, DOFMat, 1);

        float clearDistance = GetClearDistance(cam);

        // Give the results to the final material.
        finalMat.SetTexture(ShaderUniforms._DOFTex, rt1);
        finalMat.SetFloat(ShaderUniforms._ClearDistance, clearDistance);
        finalMat.SetFloat(ShaderUniforms._DOFRange, range);
        finalMat.SetFloat(ShaderUniforms._DOFDistance, distance);

        AKPostStuff.rtRelease(rt1);
        AKPostStuff.rtRelease(rt2);
    }

    float GetClearDistance(Camera cam)
    {
        float distance = GlobalShaderParam.characterDistanceWithCamera;
        float camViewRange = cam.farClipPlane - cam.nearClipPlane;

        return distance / camViewRange;
    }
}