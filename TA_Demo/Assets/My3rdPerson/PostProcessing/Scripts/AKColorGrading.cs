using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AKColorGrading
{
    public PostProcessingMain postSetting = null;
    RenderTextureFormat rtFormat = RenderTextureFormat.ARGB32;

    public void DoColorGrading(Material finalMaterial, Material lutMaterial, RenderTexture source)
    {
        RenderTexture LUT = AKPostStuff.rtGet("ColorGradingLUT", 1024, 32, 0, rtFormat);

        lutMaterial.SetVector(ShaderUniforms._LutParams, new Vector4(32.0f, 0.5f/1024.0f, 0.5f/32.0f, 32.0f / 31.0f));

        // Color balance & basic grading settings
        lutMaterial.SetFloat(ShaderUniforms._HueShift, postSetting.CG_HUE / 360f);
        lutMaterial.SetFloat(ShaderUniforms._Saturation, postSetting.CG_Saturation);
        lutMaterial.SetFloat(ShaderUniforms._Contrast, postSetting.CG_Contrast);
        lutMaterial.SetVector(ShaderUniforms._Balance, CalculateColorBalance(postSetting.CG_Temperature, postSetting.CG_tint));

        // Generate the lut
        Graphics.Blit(null, LUT, lutMaterial, 0);

        float ev = Mathf.Exp(postSetting.CG_exposure * 0.69314718055994530941723212145818f);
        finalMaterial.SetFloat(ShaderUniforms._ExposureEV, ev);
        finalMaterial.SetTexture(ShaderUniforms._LogLut, LUT);
        finalMaterial.SetVector(ShaderUniforms._LogLut_Params, new Vector3(1f / LUT.width, 1f / LUT.height, LUT.height - 1f));

        AKPostStuff.rtRelease(LUT);
    }



    Vector3 CalculateColorBalance(float temperature, float tint)
    {
        // Range ~[-1.8;1.8] ; using higher ranges is unsafe
        float t1 = temperature / 55f;
        float t2 = tint / 55f;

        // Get the CIE xy chromaticity of the reference white point.
        // Note: 0.31271 = x value on the D65 white point
        float x = 0.31271f - t1 * (t1 < 0f ? 0.1f : 0.05f);
        float y = StandardIlluminantY(x) + t2 * 0.05f;

        // Calculate the coefficients in the LMS space.
        var w1 = new Vector3(0.949237f, 1.03542f, 1.08728f); // D65 white point
        var w2 = CIExyToLMS(x, y);
        return new Vector3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);
    }

    // An analytical model of chromaticity of the standard illuminant, by Judd et al.
    // http://en.wikipedia.org/wiki/Standard_illuminant#Illuminant_series_D
    // Slightly modifed to adjust it with the D65 white point (x=0.31271, y=0.32902).
    float StandardIlluminantY(float x)
    {
        return 2.87f * x - 3f * x * x - 0.27509507f;
    }

    // CIE xy chromaticity to CAT02 LMS.
    // http://en.wikipedia.org/wiki/LMS_color_space#CAT02
    Vector3 CIExyToLMS(float x, float y)
    {
        float Y = 1f;
        float X = Y * x / y;
        float Z = Y * (1f - x - y) / y;

        float L = 0.7328f * X + 0.4296f * Y - 0.1624f * Z;
        float M = -0.7036f * X + 1.6975f * Y + 0.0061f * Z;
        float S = 0.0030f * X + 0.0136f * Y + 0.9834f * Z;

        return new Vector3(L, M, S);
    }
}
