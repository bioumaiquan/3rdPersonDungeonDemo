using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Text;

public class AKPostStuff
{
    public static Material GetMaterial(Material material, string shaderName)
    {
        if (material == null)
        {
            var shader = Shader.Find(shaderName);

            if (shader == null)
                throw new ArgumentException(string.Format("Can't find shader ({0})", shaderName));

            material = new Material(shader)
            {
                name = string.Format("AKPostFX - {0}", shaderName.Substring(shaderName.LastIndexOf("/") + 1)),
                hideFlags = HideFlags.DontSave
            };
        }
        return material;
    }

    public static RenderTexture rtGet(string name, int width, int height, int depth, RenderTextureFormat rf, RenderTextureReadWrite rw = RenderTextureReadWrite.Default, int aa = 1)
    {
        RenderTexture rt = RenderTexture.GetTemporary(width, height, depth, rf, rw, aa);
        rt.filterMode = FilterMode.Bilinear;
        rt.wrapMode = TextureWrapMode.Clamp;

        rt.name = BuildStringOptimized("AKPostTempBuffer_", name);
        return rt;
    }

    public static void rtRelease(RenderTexture rt)
    {
        if (rt != null)
        {
            RenderTexture.ReleaseTemporary(rt);
        }
    }

    private static StringBuilder sb = null;
    /// <summary>
    /// 创建字符串，产生更好的GC
    /// </summary>
    /// <param name="args"></param>
    /// <returns></returns>
    public static string BuildStringOptimized(params string[] args)
    {
        if (sb == null)
        {
            sb = new StringBuilder();
            for (int i = 0; i < 256; i++)
            {
                sb.Append('\0');
            }
        }

        int len = 0;
        for (int i = 0; i < args.Length; i++)
        {
            len += args[i].Length;
        }
        if (sb.Length < len)
        {
            for (int i = 0; i < len - sb.Length; i++)
            {
                sb.Append('\0');
            }
        }
        int index = 0;
        for (int i = 0; i < args.Length; i++)
        {
            for (int j = 0; j < args[i].Length; j++)
            {
                sb[index++] = args[i][j];
            }
        }
        sb[index] = '\0';
        return sb.ToString(0, len);
    }
}
