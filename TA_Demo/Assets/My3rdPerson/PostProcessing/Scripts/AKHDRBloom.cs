using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class AKHDRBloom
{
    RenderTextureFormat rtFormat = RenderTextureFormat.ARGB32;

    const int k_MaxPyramidBlurLevel = 8;
    RenderTexture[] m_BlurBuffer1 = new RenderTexture[k_MaxPyramidBlurLevel];
    RenderTexture[] m_BlurBuffer2 = new RenderTexture[k_MaxPyramidBlurLevel];

    public PostProcessingMain postSetting = null;
    float thre;
    public void DoBloom(Material finalMaterial, Material bloomMat, RenderTexture source, int width, int height)
    {
        // Do bloom on a half-res buffer, full-res doesn't bring much and kills performances on
        // fillrate limited platforms

        // Determine the iteration count
        float logh = Mathf.Log(height, 2f) + postSetting.bloomRadius - 7f;
        int logh_i = (int)logh;
        int iterations = Mathf.Clamp(logh_i, 1, k_MaxPyramidBlurLevel);

        // Uupdate the shader properties
        thre = postSetting.bloomThreshold;
        bloomMat.SetFloat(ShaderUniforms._Threshold, thre);

        float knee = thre * postSetting.bloomSoftKnee + 1e-5f;
        var curve = new Vector3(thre - knee, knee * 2f, 0.25f / knee);
        bloomMat.SetVector(ShaderUniforms._Curve, curve);

        float sampleScale = 0.5f + logh - logh_i;
        Vector2 bloomsetting = new Vector2(sampleScale, postSetting.bloomIntensity);
        bloomMat.SetVector(ShaderUniforms._Bloom_Settings, bloomsetting);

        // Prefilter pass
        RenderTexture prepass = AKPostStuff.rtGet("Bloom", width, height, 0, rtFormat);
        Graphics.Blit(source, prepass, bloomMat, 0);
        var last = prepass;

        //down sample
        for (int level = 0; level < iterations; level++)
        {
            m_BlurBuffer1[level] = AKPostStuff.rtGet("Bloom", last.width >> 1, last.height >> 1, 0, rtFormat);

            Graphics.Blit(last, m_BlurBuffer1[level], bloomMat, 1);

            last = m_BlurBuffer1[level];
        }

        // Upsample and combine loop
        for (int level = iterations - 2; level >= 0; level--)
        {
            var baseTex = m_BlurBuffer1[level];
            bloomMat.SetTexture(ShaderUniforms._BaseTex, baseTex);

            m_BlurBuffer2[level] = AKPostStuff.rtGet("Bloom", baseTex.width, baseTex.height, 0, rtFormat);

            Graphics.Blit(last, m_BlurBuffer2[level], bloomMat, 2);
            last = m_BlurBuffer2[level];
        }

        finalMaterial.SetTexture(ShaderUniforms._BloomTex, last);
        finalMaterial.SetVector(ShaderUniforms._Bloom_Settings, bloomsetting);

        // Release the temporary buffers
        for (int i = 0; i < k_MaxPyramidBlurLevel; i++)
        {
            if (m_BlurBuffer1[i] != null)
                AKPostStuff.rtRelease(m_BlurBuffer1[i]);

            if (m_BlurBuffer2[i] != null)
                AKPostStuff.rtRelease(m_BlurBuffer2[i]);

            m_BlurBuffer1[i] = null;
            m_BlurBuffer2[i] = null;
        }
        AKPostStuff.rtRelease(prepass);
    }

    float ThresholdLinear
    {
        get { return Mathf.GammaToLinearSpace(thre); }
        set { thre = Mathf.LinearToGammaSpace(value); }
    }
}
