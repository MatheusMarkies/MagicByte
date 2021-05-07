using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;

public class ComputeShaderStackBlit
{
	
	ScriptableRenderContext context;
    Camera camera;

	public void Setup(ScriptableRenderContext context, Camera camera)
	{
		this.context = context;
		this.camera = camera;
	}
	int effectsID;
	void createComputeShaderStack(PostProcessingCamera PPC)
	{
		effectsID = Shader.PropertyToID("_Compute0");
		for (int i = 1; i < PPC.getMaterialList().Count; i++)
		{
			Shader.PropertyToID("_Compute" + i);
		}
	}
	CommandBuffer buffer = new CommandBuffer() { name = "Compute Shader Render" };
	public void RenderComputeShader(List<RenderTexture> renderTexture,bool accumulation = false,Material material = null)
    {

			if (!accumulation)
					buffer.Blit(renderTexture[0], BuiltinRenderTextureType.CameraTarget);
			else
				for (int i = 1; i < renderTexture.Count; i++)
				{
				buffer.SetGlobalTexture("_MainTex", renderTexture[i-1]);
					if (material == null)
						buffer.Blit(renderTexture[i - 1], renderTexture[i]);
					else
						buffer.Blit(renderTexture[i - 1], renderTexture[i], material);
					//if (i == renderTexture.Count - 1)
					//{
						//buffer.SetGlobalTexture("_MainTex", renderTexture[i]);
				    buffer.Blit(renderTexture[i], BuiltinRenderTextureType.CameraTarget);
				    //}
			}

		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}

}
