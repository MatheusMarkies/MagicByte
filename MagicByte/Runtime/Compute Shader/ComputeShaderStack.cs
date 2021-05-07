using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ExecuteExample : ExecuteComputeShader {

    public override List<RenderTexture> OnRenderComputeShader()
    {
        LoadRenderTexture();

        computeShader.SetTexture(0,"Result",renderTexture[0]);
        computeShader.Dispatch(0,renderTexture[0].width,renderTexture[0].height,24);

        List<RenderTexture> rt = new List<RenderTexture>();
        rt.Add(renderTexture[0]);

        return rt;
    }

}

[RequireComponent(typeof(Camera)),ExecuteInEditMode]
public class ComputeShaderStack : MonoBehaviour
{
    //public ComputeShader cs;
    //public ComputeShader computeShader;
    List<ExecuteComputeShader> executeStack = new List<ExecuteComputeShader>();

    public void OnRederCamera()
    {
        //ExecuteComputeShader ee = new ExecuteExample();
        //ee.setComputeShader(cs);
        //CleanStack();
        //addComputeShader(ee);
    }

    public void CleanStack()
    {
        executeStack = new List<ExecuteComputeShader>();
    }
    public void addComputeShader(ExecuteComputeShader exe)
    {
        int i = 0;
        foreach (ExecuteComputeShader exec in executeStack)
            if (exe == exec)
                i++;
        if(i == 0)
        executeStack.Add(exe);
    }
    public List<ExecuteComputeShader> getComputeShaderList()
    {
        return executeStack;
    }

}