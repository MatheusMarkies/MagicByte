using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;

[ExecuteInEditMode]
public class PathTracingObject : MonoBehaviour
{

    [System.Serializable]
    public struct pathTracingObject
    {
        public Vector4 Position;

        public int indicesCount;
        public int indicesOffset;

        public Matrix4x4 localToWorldMatrix;
    };

    public pathTracingObject _pathTracingObject = new pathTracingObject();
    public Mesh objectMesh;
    public void OnExecutePathTracing() 
    {
        _pathTracingObject.localToWorldMatrix = gameObject.transform.localToWorldMatrix;
    }

    //private void RebuildMeshObjectBuffers()
    //{

    //    Mesh mesh = gameObject.GetComponent<MeshFilter>().sharedMesh;
    //    _rayTracingObject.triangles = mesh.triangles;//GetComponent<MeshFilter>().mesh.GetIndices(0);
    //    _rayTracingObject.vertices = mesh.vertices;

    //}

}
