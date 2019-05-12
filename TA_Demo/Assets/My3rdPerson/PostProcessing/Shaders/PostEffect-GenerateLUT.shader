Shader "Hidden/PostEffect/GenerateLut"
{
    CGINCLUDE

        #pragma target 3.0
        #include "UnityCG.cginc"
		#include "AK47NewShader-Post-Common.cginc"
		#include "AK47NewShader-Post-ACES.cginc" 
		#include "AK47NewShader-Post-ColorGrading.cginc" 

        half3 _Balance;

        half _HueShift;
        half _Saturation;
        half _Contrast;

        half4 _LutParams;

        half3 ColorGrade(half3 color)
        {
            half3 aces = unity_to_ACES(color);

            // ACEScc (log) space
            half3 acescc = ACES_to_ACEScc(aces);

            acescc = Saturation(acescc, _Saturation);
            acescc = ContrastLog(acescc, _Contrast);

            aces = ACEScc_to_ACES(acescc);

            // ACEScg (linear) space
            half3 acescg = ACES_to_ACEScg(aces);

            acescg = WhiteBalance(acescg, _Balance);

            half3 hsv = RgbToHsv(max(acescg, 0.0));
            hsv.x = RotateHue(hsv.x + _HueShift, 0.0, 1.0);
            acescg = HsvToRgb(hsv);

            color = ACEScg_to_unity(acescg);

            return color;
        }

        half4 FragCreateLut(VaryingsDefault i) : SV_Target
        {
            // 2D strip lut
            half2 uv = i.uv - _LutParams.yz;
            half3 color;
            color.r = frac(uv.x * _LutParams.x);
            color.b = uv.x - color.r / _LutParams.x;
            color.g = uv.y;

            // Lut is in LogC
            half3 colorLogC = color * _LutParams.w;

            // Switch back to unity linear and color grade
            half3 colorLinear = LogCToLinear(colorLogC);
            half3 graded = ColorGrade(colorLinear);

            return half4(graded, 1.0);
        }

    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // (0)
        Pass
        {
            CGPROGRAM

                #pragma vertex VertDefault
                #pragma fragment FragCreateLut

            ENDCG
        }
    }
}
