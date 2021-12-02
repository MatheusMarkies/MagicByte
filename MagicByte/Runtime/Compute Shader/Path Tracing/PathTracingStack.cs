using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class PathTracingStack
{
	int fxSourceId = Shader.PropertyToID("_PathTracingSource");
	CommandBuffer buffer = new CommandBuffer { name = "Path Tracing" };
	ScriptableRenderContext context;

	public void setRenderContext(ScriptableRenderContext context)
	{ this.context = context; }

	public void pathTracingDrawing(PathTracing pathTracing, int sourceId, Camera camera)
	{
		renderEffect(pathTracing,sourceId, camera);
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}
	public void drawingEffect(RenderTargetIdentifier from, RenderTargetIdentifier to, Material material, int pass, Camera camera)
	{
		buffer.GetTemporaryRT(fxSourceId, camera.pixelWidth, camera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);

		buffer.SetGlobalTexture(fxSourceId, from);

		buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
		buffer.DrawProcedural(Matrix4x4.identity, material, pass, MeshTopology.Triangles, 3);

		buffer.ReleaseTemporaryRT(fxSourceId);
	}
	//Mono Pass
	int effectsID = Shader.PropertyToID("_PathTracing"+0);

	void renderEffect(PathTracing pathTracing,int sourceId, Camera camera)
	{
		int fromId = sourceId, toId = effectsID;

		pathTracing.additiveMaterial = new Material(pathTracing.additiveShader);
		pathTracing.additiveMaterial.SetFloat("_Sample", pathTracing.samplesPerPixel);

		int i;
		for (i = 0; i < pathTracing.samplesPerPixel; i++)
		{

			buffer.Blit(pathTracing.renderPathTracingTexture(), fromId);

			buffer.GetTemporaryRT(toId, camera.pixelWidth, camera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
			drawingEffect(fromId, toId, pathTracing.additiveMaterial, 0, camera);

			fromId = toId;
			toId += toId + 1;
		}

		drawingEffect(fromId, BuiltinRenderTextureType.CameraTarget, pathTracing.additiveMaterial, 0, camera);
		for (int o = i; o > 0; o--)
		{
			buffer.ReleaseTemporaryRT(toId - o);
		}
	}

}
