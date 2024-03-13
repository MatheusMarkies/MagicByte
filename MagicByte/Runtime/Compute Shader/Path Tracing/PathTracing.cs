using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable]
public class PathTracing : MonoBehaviour
{
    [SerializeField]
    ComputeShader computeShader;
    [SerializeField]
    GameObject[] pathTracingObjects;
    [SerializeField]
    Texture Skybox;
    [SerializeField]
    int ImageScale = 4;
    [SerializeField]
    Light directionalLight;

    [System.Serializable]
    public class PathTracingComputeShader
    {
        PathTracingObject[] pathTracingObjects;

        public List<Vector3> vertices = new List<Vector3>();
        public List<int> indices = new List<int>();
        
        int ImageScale = 1;

        Texture skyboxTexture;

        Light DirectionalLight;

        RenderTexture renderTexture;
        public void loadRenderTexture()
        {
            renderTexture = new RenderTexture(Mathf.CeilToInt(Screen.width / ImageScale), Mathf.CeilToInt(Screen.height / ImageScale), 0, RenderTextureFormat.DefaultHDR);
            renderTexture.enableRandomWrite = true;
            renderTexture.Create();
        }
        public RenderTexture OnRenderComputeShader(ComputeShader computeShader)
        {
            loadRenderTexture();
            //computeShader.SetInt("_spp", samplesPerPixel);
            #region Mesh Forwarding

            computeShader.SetInt("_pathTracingObjectCount", pathTracingObjects.Length);

            foreach (PathTracingObject pto in pathTracingObjects)
                pto.OnExecutePathTracing();

            buildObjectList();

            ComputeBuffer objectsBuffer = new ComputeBuffer(pathTracingObjects.Length, 124) { name = "Scenes Objects Buffer" };
            ComputeBuffer vertexBuffer = new ComputeBuffer(vertices.Count, 12) { name = "Vertices Buffer" };
            ComputeBuffer indexBuffer = new ComputeBuffer(indices.Count, 4) { name = "Indices Buffer" };

            PathTracingObject.PathTracingObjectStruct[] sceneObjects = new PathTracingObject.PathTracingObjectStruct[pathTracingObjects.Length];
            for (int i = 0; i < pathTracingObjects.Length; i++)
            {
                sceneObjects[i] = pathTracingObjects[i].pathTracingObject;
            }

            objectsBuffer.SetData(sceneObjects);
            vertexBuffer.SetData(vertices);
            indexBuffer.SetData(indices);

            computeShader.SetBuffer(0, "_pathTracingObject", objectsBuffer);
            computeShader.SetBuffer(0, "_Vertices", vertexBuffer);
            computeShader.SetBuffer(0, "_Indices", indexBuffer);
            #endregion

            computeShader.SetTexture(0, "_SkyboxTexture", skyboxTexture);

            computeShader.SetVector("_DirectionalLight", new Vector4(DirectionalLight.transform.forward.x, DirectionalLight.transform.forward.y, DirectionalLight.transform.forward.z, DirectionalLight.intensity));
            computeShader.SetVector("_DirectionalLightColor", new Vector3(DirectionalLight.color.r, DirectionalLight.color.g, DirectionalLight.color.b));

            computeShader.SetMatrix("_CameraToWorld", Camera.main.cameraToWorldMatrix);
            computeShader.SetVector("_WorldSpaceCameraPosition", Camera.main.gameObject.transform.position);
            computeShader.SetMatrix("_CameraInverseProjection", Camera.main.projectionMatrix.inverse);

            computeShader.SetFloat("_Seed", Random.value);

            computeShader.SetTexture(0, "Result", renderTexture);
            computeShader.Dispatch(0, renderTexture.width, renderTexture.height, 8);

            return renderTexture;
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

                pto.pathTracingObject.indicesOffset = indicesCount;//Offset: Where the list of indices belonging to the object starts. | indicesCount: How many indices were added before these.
                pto.pathTracingObject.indicesCount = triangles.Length;//How many indexes does this object have.

                foreach (Vector3 vertice in vertices)
                    this.vertices.Add(vertice);

                for (int i = 0; i < triangles.Length; i++)
                {
                    this.indices.Add(triangles[i] + verticesCount);//Variable containing all indices of all objects in the scene. | triangles[i] (take an index) +verticesCount(Add to the amount of vetices already added) + 1

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
        public void setSkybox(Texture SkyboxTexture) { this.skyboxTexture = SkyboxTexture; }
        public void setImageScale(int ImageScale) { this.ImageScale = ImageScale; }
        public void setDirectionalLight(Light directionalLight) { this.DirectionalLight = directionalLight; }

        //public RenderTexture preProcessing()
        //{
        //    PathTracingComputeShader pathTracingCompute = new PathTracingComputeShader();

        //    PathTracingObject[] objs = new PathTracingObject[pathTracingObjects.Length];
        //    for (int i = 0; i < pathTracingObjects.Length; i++)
        //        objs[i] = pathTracingObjects[i].GetComponent<PathTracingObject>();

        //    pathTracingCompute.setPathTracingObjects(objs);
        //    return pathTracingCompute.OnRenderComputeShader(computeShader);
        //}

    }

    public int samplesPerPixel = 10;

    public RenderTexture renderPathTracingTexture()
    {
        PathTracingComputeShader pathTracingCompute = new PathTracingComputeShader();

        PathTracingObject[] objs = new PathTracingObject[pathTracingObjects.Length];
        for (int i = 0; i < pathTracingObjects.Length; i++)
            objs[i] = pathTracingObjects[i].GetComponent<PathTracingObject>();

        pathTracingCompute.setPathTracingObjects(objs);
        pathTracingCompute.setSkybox(Skybox);
        pathTracingCompute.setImageScale(ImageScale);
        pathTracingCompute.setDirectionalLight(directionalLight);

        return pathTracingCompute.OnRenderComputeShader(computeShader);
    }

    public Shader additiveShader;

    [HideInInspector]
    public Material additiveMaterial;

    bool allFramesHasGenerated = false;
    int samplesGenerated;

    public RenderTexture[] renderTextures;

    public void renderPathTracingTextures(){
         renderTextures = new RenderTexture[samplesPerPixel];
        for (int i = 0; i < samplesPerPixel; i++)
		{
            renderTextures[i] = renderPathTracingTexture();
        }
    }

    public RenderTexture getRenderTexture(int i){
        return renderTextures[i];
    }

}