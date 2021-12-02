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
    public struct PathTracingObjectStruct
    {
        public Vector4 Position;

        public int indicesCount;
        public int indicesOffset;

        public Matrix4x4 localToWorldMatrix;

        #region ObjectMaterial
        public Vector3 MainColor;
        public float Metallic;
        public float Smoothness;
        public Vector3 Emission;
        public float Transmission;

        #endregion
    };

    public PathTracingObjectStruct pathTracingObject = new PathTracingObjectStruct();
    public Mesh objectMesh;

    private void Start()
    {
        if(TryGetComponent<MeshRenderer>(out MeshRenderer renderer))
        {
            renderer.enabled = true;
            renderer.rayTracingMode = UnityEngine.Experimental.Rendering.RayTracingMode.Static;
            //if (objectMesh == null)
            //    objectMesh = 
        }
    }

    public void Update()
    {
        pathTracingObject.Position = transform.position;
    }

    #region Test
    [System.Serializable]
    public struct ObjectMaterial
    {
        public Color MainColor;
        [Range(0,1)]
        public float Metallic;
        [Range(0, 1)]
        public float Smoothness;
        [ColorUsageAttribute(true, true, 0f, 8f, 0.125f, 3f)]
        public Color Emission;
        [Range(0,1)]
        public float Transmission;
    }
    [SerializeField]
    public ObjectMaterial objectMaterial = new ObjectMaterial();
    #endregion

    public void OnExecutePathTracing() 
    {
        pathTracingObject.localToWorldMatrix = gameObject.transform.localToWorldMatrix;

        pathTracingObject.MainColor = new Vector3(objectMaterial.MainColor.r, objectMaterial.MainColor.g, objectMaterial.MainColor.b);
        pathTracingObject.Smoothness = objectMaterial.Smoothness;
        pathTracingObject.Metallic = objectMaterial.Metallic;
        pathTracingObject.Emission = new Vector3(objectMaterial.Emission.r, objectMaterial.Emission.g, objectMaterial.Emission.b);
        pathTracingObject.Transmission = objectMaterial.Transmission;

    //if (TryGetComponent<MeshRenderer>(out MeshRenderer renderer))
    //{
    //    pathTracingObject.MainColor = new Vector3(renderer.material.GetColor("").r, renderer.material.GetColor("").g, renderer.material.GetColor("").b);
    //    pathTracingObject.Smoothness = renderer.material.GetFloat("");
    //    pathTracingObject.Metallic = renderer.material.GetFloat("");
    //    pathTracingObject.Emission = new Vector3(renderer.material.GetColor("").r, renderer.material.GetColor("").g, renderer.material.GetColor("").b);
    //}
}

}
