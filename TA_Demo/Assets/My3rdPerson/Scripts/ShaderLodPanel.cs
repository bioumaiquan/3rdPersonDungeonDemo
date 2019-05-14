using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class ShaderLod
{
	[MenuItem("Tools/美术工具/材质预览/高配")]
	public static void Lod1000()
	{
		Shader.globalMaximumLOD = 1000;
	}
	
	[MenuItem("Tools/美术工具/材质预览/中配")]
	public static void Lod500()
	{
		Shader.globalMaximumLOD = 500;
	}

	[MenuItem("Tools/美术工具/材质预览/低配")]
	public static void Lod300()
	{
		Shader.globalMaximumLOD = 300;
	}
	
	//[MenuItem("Tools/美术工具/角色皮肤遮罩预览/开")]
	//public static void TurnOnCharacterSkinMask()
	//{
 //       Shader.EnableKeyword("CHARACTER_SKIN_MASK");
	//}
	
	//[MenuItem("Tools/美术工具/角色皮肤遮罩预览/关")]
	//public static void TurnOffCharacterSkinMask()
	//{
 //       Shader.DisableKeyword("CHARACTER_SKIN_MASK");
 //   }
}

