using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ObjectPosition : MonoBehaviour
{
    Material[] mats;

    void Start()
    {
        mats = GetComponent<Renderer>().sharedMaterials;

        for (int i = 0; i < mats.Length; i++)
        {
            mats[i].SetVector("_ObjectPos", transform.position);
        }
    }
}
