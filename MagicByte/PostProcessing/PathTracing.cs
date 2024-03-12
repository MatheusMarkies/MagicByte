using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable]
class PathTracing
{
    
    [SerializeField]
    ComputeShader computeShader;
    [SerializeField]
    GameObject[] pathTracingObjects;
     
    class PathTracingComputeShader
    {
        PathTracingObject[] pathTracingObjects;

        public List<Vector3> vertices = new List<Vector3>();
        public List<int> indices = new List<int>();

        RenderTexture RT;
        public void loadRenderTexture()
        {
            RT = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.DefaultHDR);
            RT.enableRandomWrite = true;
            RT.Create();
        }
        public RenderTexture OnRenderComputeShader(ComputeShader computeShader)
        {
            loadRenderTexture();

            #region Mesh Forwarding

            computeShader.SetInt("_pathTracingObjectCount", pathTracingObjects.Length);

            foreach (PathTracingObject pto in pathTracingObjects)
               pto.OnExecutePathTracing();

            buildObjectList();

            ComputeBuffer objectsBuffer = new ComputeBuffer(pathTracingObjects.Length, 88) { name = "Scenes Objects Buffer" };
            ComputeBuffer vertexBuffer = new ComputeBuffer(vertices.Count, 12) { name = "Vertices Buffer" };
            ComputeBuffer indexBuffer = new ComputeBuffer(indices.Count, 4) { name = "Indices Buffer" };

            PathTracingObject.pathTracingObject[] sceneObjects = new PathTracingObject.pathTracingObject[pathTracingObjects.Length];
            for (int i = 0; i < pathTracingObjects.Length; i++)
            {
                sceneObjects[i] = pathTracingObjects[i]._pathTracingObject;
            }

            objectsBuffer.SetData(sceneObjects);
            vertexBuffer.SetData(vertices);
            indexBuffer.SetData(indices);

            computeShader.SetBuffer(0, "_pathTracingObject", objectsBuffer);
            computeShader.SetBuffer(0, "_Vertices", vertexBuffer);
            computeShader.SetBuffer(0, "_Indices", indexBuffer);
            #endregion

            computeShader.SetMatrix("_CameraToWorld", Camera.main.cameraToWorldMatrix);
            computeShader.SetMatrix("_CameraInverseProjection", Camera.main.projectionMatrix.inverse);

            computeShader.SetTexture(0, "Result", RT);
            computeShader.Dispatch(0, RT.width, RT.height, 24);

            return RT;
        }
        public void buildObjectList()
        {
            int indicesCount = 0;
            int verticesCount = 0;

            foreach (PathTracingObject pto in pathTracingObjects)
            {
                int[] triangles;
                Vector3[] vertices;

                triangles = pto.objectMesh.triangles;//Take a sequence of vertices that form a triangle.
                vertices = pto.objectMesh.vertices;//Take vertex list

                pto._pathTracingObject.indicesOffset = indicesCount;//Offset: Where the list of indices belonging to the object starts. | indicesCount: How many indices were added before these.
                pto._pathTracingObject.indicesCount = triangles.Length;//How many indexes does this object have.

                foreach (Vector3 vertice in vertices)
                    this.vertices.Add(vertice);

                for (int i = 0; i < triangles.Length; i++)
                {
                    this.indices.Add(triangles[i] + verticesCount + 1);//Variable containing all indices of all objects in the scene. | triangles[i] (take an index) +verticesCount(Add to the amount of vetices already added) + 1

                    /*Example:
                    If the previous object has 270 vertices.
                    The first triangle of the next objects will be connected to the vertices(271, 272, 273) instead of(0,1,2).
                    +1 because vertex 270 belongs to a different object.*/
                }

                indicesCount += triangles.Length;//update index
                verticesCount += vertices.Length;//update index
            }
        }
        public void setPathTracingObjects(PathTracingObject[] pto) { pathTracingObjects = pto; }
    }
    public RenderTexture preProcessing()
    {
        PathTracingComputeShader pathTracingCompute = new PathTracingComputeShader();

        PathTracingObject[] objs = new PathTracingObject[pathTracingObjects.Length];
        for (int i = 0; i < pathTracingObjects.Length; i++)
            objs[i] = pathTracingObjects[i].GetComponent<PathTracingObject>();

        pathTracingCompute.setPathTracingObjects(objs);
        return pathTracingCompute.OnRenderComputeShader(computeShader);
    }
}