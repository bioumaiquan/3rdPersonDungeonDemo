using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterStates : MonoBehaviour
{
    public static Vector3 CharacterPos = Vector3.zero;
    public static Vector3 CharacterDir = Vector3.zero;

    void LateUpdate()
    {
        CharacterPos = gameObject.transform.position;
        CharacterDir = gameObject.transform.forward;
    }
}
