#ifndef __BLOOM__
#define __BLOOM__

#include "AK47NewShader-Post-Common.cginc"

// Brightness function
half Brightness(half3 c)
{
    return max(max(c.r, c.g), c.b);
}

// 3-tap median filter
half3 Median(half3 a, half3 b, half3 c)
{
    return a + b + c - min(min(a, b), c) - max(max(a, b), c); 
}

// Downsample with a 4x4 box filter
half3 DownsampleFilter(sampler2D tex, float2 uv, float2 texelSize)
{
    float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);

    half3 s;
    s = DecodeHDR(tex2D(tex, uv + d.xy));
    s += DecodeHDR(tex2D(tex, uv + d.zy));
    s += DecodeHDR(tex2D(tex, uv + d.xw));
    s += DecodeHDR(tex2D(tex, uv + d.zw));

    return s * (1.0 / 4.0);
}

//mobile
half3 UpsampleFilter(sampler2D tex, float2 uv, float2 texelSize, float sampleScale)
{
    // 4-tap bilinear upsampler
    float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0) * (sampleScale * 0.5);

    half3 s;
    s =  DecodeHDR(tex2D(tex, uv + d.xy));
    s += DecodeHDR(tex2D(tex, uv + d.zy));
    s += DecodeHDR(tex2D(tex, uv + d.xw));
    s += DecodeHDR(tex2D(tex, uv + d.zw));

    return s * (1.0 / 4.0);
}

#endif // __BLOOM__