using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class EmissionObject : MonoBehaviour
{
    void Update()
    {
        Material mat = GetComponent<MeshRenderer>().material;
        mat.globalIlluminationFlags &=~ MaterialGlobalIlluminationFlags.BakedEmissive;
    }
}
