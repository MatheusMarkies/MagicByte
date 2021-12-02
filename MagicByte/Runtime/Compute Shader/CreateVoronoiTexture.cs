using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateVoronoiTexture : MonoBehaviour
{
    Texture2D texture2D;
    public ComputeShader shader;

    void Start()
    {
        RenderTexture tex = new RenderTexture(1024, 1024, 24);
        tex.enableRandomWrite = true;
        tex.Create();

        shader.SetTexture(shader.FindKernel("CSMain"), "Result", tex);
        shader.Dispatch(shader.FindKernel("CSMain"), tex.width, tex.height, 1);
        texture2D = RenderTexturetoTexture2D(tex);
        gameObject.GetComponent<MeshRenderer>().material.SetTexture("_Voronoi", texture2D);
    }
    Texture2D RenderTexturetoTexture2D(RenderTexture rTex)
    {
        Texture2D tex = new Texture2D(512, 512, TextureFormat.RGB24, false);

        RenderTexture.active = rTex;
        tex.ReadPixels(new Rect(0, 0, rTex.width, rTex.height), 0, 0);
        tex.Apply();
        return tex;
    }

}
