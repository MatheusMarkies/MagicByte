using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public abstract class ExecuteComputeShader
{
    public ComputeShader computeShader;
    public RenderTexture[] renderTexture = new RenderTexture[10];
    public bool isCreateRT = false;
    public bool isAccumulation = false;
    public CullingResults cullingResults;

    public float currentSample;

    public Material filterMaterial = null;

    public void LoadRenderTexture()
    {
        renderTexture[0] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.DefaultHDR);
        renderTexture[0].enableRandomWrite = true;
        renderTexture[0].Create();
        isCreateRT = true;
    }
    public abstract List<RenderTexture> OnRenderComputeShader();
    public void setComputeShader(ComputeShader cs) { this.computeShader = cs; }
    public void setRenderTexture(RenderTexture rt) { this.renderTexture[0] = rt; }
    public bool getAccumulation() { return isAccumulation; }
    public Material getFilterMaterial() { return filterMaterial; }
    public void setCulling(CullingResults cr) { this.cullingResults = cr; }
}
