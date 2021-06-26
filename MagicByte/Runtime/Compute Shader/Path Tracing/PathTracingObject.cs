using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class PathTracingObject : MonoBehaviour
{

    public int[] triangles;

    void OnExecutePathTracing() { }
    private void Update()
    {
        triangles = GetComponent<MeshFilter>().mesh.GetIndices(0);
    }
}
