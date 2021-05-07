using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
//using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;

public class RayTracingComputeShader : ExecuteComputeShader
{
    Camera camera;
    Texture skyTexture;
    Light lightDirectional;

    bool antiMonteCarlo = false;
    int samplesPerPixel = 1;
    int maxHits = 6;

    int renderScale = 8;

    List<Vector3> _vertices = new List<Vector3>();
    List<int> _indices = new List<int>();

    List<RenderTexture> MonteCarloRemover = new List<RenderTexture>();
    List<SceneObject> SceneObjects = new List<SceneObject>();

    public void setSky(Texture sky)
    {
        this.skyTexture = sky;
    }
    public void setCamera(Camera camera)
    {
        this.camera = camera;
    }
    public void setDirectional(Light light)
    {
        this.lightDirectional = light;
    }
    int lateSamples;
    public override List<RenderTexture> OnRenderComputeShader()
    {
        RebuildMeshObjectBuffers();
        if (!isCreateRT)
            LoadRenderTexture();

        if (lateSamples != samplesPerPixel)
        {
            MonteCarloRemover = new List<RenderTexture>();
            antiMonteCarlo = false;
            lateSamples = samplesPerPixel;
        }

        if (!antiMonteCarlo)
        {
            RenderTexture renderTextureK = null;
            for (int i = 0; i < samplesPerPixel; i++)
            { 
                renderTextureK = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.DefaultHDR);
                renderTextureK.enableRandomWrite = true;
                renderTextureK.Create();
                MonteCarloRemover.Add(renderTextureK);
            }
            antiMonteCarlo = true;
        }

        computeShader.SetInt("_rayMaxHits", maxHits);
        computeShader.SetMatrix("_CameraToWorld", camera.cameraToWorldMatrix);
        computeShader.SetMatrix("_CameraInverseProjection", camera.projectionMatrix.inverse);

        computeShader.SetVector("_DirectionalLight", new Vector4(lightDirectional.transform.forward.x, lightDirectional.transform.forward.y, lightDirectional.transform.forward.z,0));

        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight visibleLight = visibleLights[i];
            if (visibleLight.lightType == LightType.Directional)
                computeShader.SetVector("_DirectionalLightDirection", -visibleLight.localToWorldMatrix.GetColumn(2));
        }

        computeShader.SetVector("_LightColor", lightDirectional.color);
        computeShader.SetFloat("_LightIntensity", lightDirectional.intensity);

        computeShader.SetFloat("_Seed", Random.value);

        computeShader.SetTexture(0, "_SkyboxTexture", skyTexture);

        ComputeBuffer objectsBuffer = new ComputeBuffer(SceneObjects.Count, 136) { name = "Scenes Objects Buffer" };
        ComputeBuffer _vertexBuffer = new ComputeBuffer(_vertices.Count, 12);
        ComputeBuffer _indexBuffer = new ComputeBuffer(_indices.Count, 4);

        SceneObject.sceneObject[] sceneObjects = new SceneObject.sceneObject[SceneObjects.Count];
        for (int i = 0; i < SceneObjects.Count; i++)
        {
            sceneObjects[i] = SceneObjects[i].getSceneObject();
            Debug.Log("count "+sceneObjects[i].indices_count);
            Debug.Log("offset " + sceneObjects[i].indices_offset);
        }

        objectsBuffer.SetData(sceneObjects);
        _vertexBuffer.SetData(_vertices);
        _indexBuffer.SetData(_indices);
        Debug.Log("All indices: "+ _indices.Count);
        Debug.Log("All vertex: " + _vertices.Count);
        computeShader.SetInt("_SceneObjectsCount", SceneObjects.Count);

        //vertexBuffer.SetData(vertices);

        computeShader.SetBuffer(0, "_Objects", objectsBuffer);
        computeShader.SetBuffer(0, "_Vertices", _vertexBuffer);
        computeShader.SetBuffer(0, "_Indices", _indexBuffer);
        //if (vertices.Count > 0)
        //computeShader.SetBuffer(0, "_Vertices", vertexBuffer);

        int X = Mathf.CeilToInt(Screen.width / renderScale);
        int Y = Mathf.CeilToInt(Screen.height / renderScale);
        computeShader.SetTexture(0, "Result", renderTexture[0]);
        computeShader.Dispatch(0, X, Y, 1);

        if (filterMaterial == null)
            filterMaterial = new Material(Shader.Find("Hidden/Denoiser"));
        
        isAccumulation = true;

        List<RenderTexture> rts = new List<RenderTexture>();
        rts.Add(renderTexture[0]);

        for (int i = 0; i < samplesPerPixel; i++)
        {
            ////computeShader.SetFloat("_Seed", Random.value);
            //computeShader.SetTexture(0, "Result", MonteCarloRemover[i]);
            //X = Mathf.CeilToInt(X / 128.0f);
            //Y = Mathf.CeilToInt(Y / 128.0f);
            //computeShader.Dispatch(0, X, Y, 1);
            rts.Add(MonteCarloRemover[i]);
        }

        filterMaterial.SetFloat("_Sample", currentSample);
        return rts;
    }

    private void RebuildMeshObjectBuffers()
    {
        _vertices.Clear();
        _indices.Clear();

        foreach (SceneObject obj in SceneObjects)
        {
            Mesh mesh = obj.getGameObject().GetComponent<MeshFilter>().sharedMesh;
            int firstVertex = _vertices.Count;
            _vertices.AddRange(mesh.vertices);

            int firstIndex = _indices.Count;
            var indices = mesh.GetIndices(0);
            _indices.AddRange(indices.Select(index => index + firstVertex));

            obj.setIndexCount(indices.Length);
            obj.setIndexOffSet(firstIndex);
        }
    }

    public void setFilterSample(float sample) { this.currentSample = sample; }
    public void setSamplePerPixel(int per) { this.samplesPerPixel = per; }
    public void setSceneObjectsArray(List<SceneObject> obj) { this.SceneObjects = obj; }
    public void setMaxHits(int max) { this.maxHits = max; }
    public void setRenderScale(int RenderScale) { this.renderScale = RenderScale; }
}

[RequireComponent(typeof(Camera)), ExecuteInEditMode]
public class RayTracing : MonoBehaviour
{
    RayTracingComputeShader RTcs = new RayTracingComputeShader();
    public ComputeShader RayTracingComputeShader;
    public Texture SkyTexture;
    [Range(1,16)]
    public int samplesPerPixel = 1;
    [Range(1, 32)]
    public int maxHits = 4;
    [Range(1,32)]
    public int renderScale = 8;

    void Update()
    {
        RTcs.setComputeShader(RayTracingComputeShader);
        RTcs.setCamera(GetComponent<Camera>());
        RTcs.setSky(SkyTexture);

        RTcs.setMaxHits(maxHits);

        RTcs.setDirectional(RenderSettings.sun);
        RTcs.setSamplePerPixel(samplesPerPixel);

        if (renderScale % 2 != 0 && renderScale != 1)
            renderScale += 1;
        RTcs.setRenderScale(renderScale);

        List<SceneObject> SceneObjects = new List<SceneObject>();
        GameObject[] gameObjects = UnityEngine.Object.FindObjectsOfType<GameObject>();

        foreach (GameObject obj in gameObjects)
        {
            if (obj.TryGetComponent<MeshRenderer>(out MeshRenderer renderer))
            {
            bool isAdd = false;
            if (SceneObjects.Count != 0)
            {
                for (int i = 0; i < SceneObjects.Count; i++)
                    if (SceneObjects[i].getGameObject() == obj)
                        isAdd = true;
            }

            if (!isAdd)
            {
               SceneObject OBJ = new SceneObject();

                    OBJ.setGameObject(obj);
                    OBJ.setPosition(obj.transform.position);
                    OBJ.setAlbedo(new Vector4(1, renderer.material.GetVector("_BaseColor").x, renderer.material.GetVector("_BaseColor").y, renderer.material.GetVector("_BaseColor").z));
                    OBJ.setSmoothness(renderer.material.GetFloat("_Smoothness"));
                    OBJ.setMetallic(renderer.material.GetFloat("_Metallic"));
                    OBJ.setEmission(new Vector4(1, renderer.material.GetVector("_EmissionColor").x, renderer.material.GetVector("_EmissionColor").y, renderer.material.GetVector("_EmissionColor").z));

                    OBJ.setLocalToWorldMatrix(obj.transform.localToWorldMatrix);

                    if (obj.GetComponent<MeshFilter>().sharedMesh.isReadable) {
                        List<Vector3> vertex = new List<Vector3>();
                        foreach (Vector3 v in obj.GetComponent<MeshFilter>().sharedMesh.vertices)
                            vertex.Add(v);
                        List<int> index = new List<int>();
                    foreach (int i in obj.GetComponent<MeshFilter>().sharedMesh.GetIndices(0))
                        index.Add(i);

                        OBJ.setVertexList(vertex);
                        OBJ.setObjectMeshType(SceneObject.MeshType.Mesh);
                        //OBJ.setIndexCount(index.Count);
                    }
                    else
                    {
                        //OBJ.setIndexStart(0);
                        OBJ.setVertexList(new List<Vector3>());
                        //OBJ.setIndexCount(0);
                        OBJ.setObjectMeshType(SceneObject.MeshType.Sphere);

                        switch (obj.GetComponent<MeshFilter>().sharedMesh.name)
                        {
                            case "Sphere":
                                OBJ.setObjectMeshType(SceneObject.MeshType.Sphere);
                                break;
                            case "Cube":
                                OBJ.setObjectMeshType(SceneObject.MeshType.Cube);
                                break;
                            default:
                                OBJ.setObjectMeshType(SceneObject.MeshType.Sphere);
                                break;
                        }
                    }

                    if (renderer.material.shader == Shader.Find("Magic Byte/Metallic"))
                    {

                        OBJ.setAnisotropy(renderer.material.GetFloat("_Anisotropic"));
                        OBJ.setRenderType(SceneObject.RenderType.Metallic);
                    }
                    else
                    {
                        OBJ.setAnisotropy(0);
                        OBJ.setRenderType(SceneObject.RenderType.Diffuse);
                    }

                    SceneObjects.Add(OBJ);
                RTcs.setSceneObjectsArray(SceneObjects);
            }
          }
        }

        if (transform.hasChanged)
        {
            RTcs.setFilterSample(0f);
            transform.hasChanged = false;
        }

        if (TryGetComponent<ComputeShaderStack>(out ComputeShaderStack stack))
        {
            stack.addComputeShader(RTcs);
        }

    }
}
