using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
public class PostProcessingStack
{

	const string bufferName = "PostProcessingEffects";
	int fxSourceId = Shader.PropertyToID("_PostFXSource"),
	fxSource2Id = Shader.PropertyToID("_PostFXSource2");
	CommandBuffer buffer = new CommandBuffer
	{
		name = bufferName
	};

	ScriptableRenderContext context;

	Camera camera;

	public bool IsActive = true;
	int effectsID;
	void createPostProcessingStack(PostProcessingCamera PPC)
	{
		effectsID = Shader.PropertyToID("_Effect0");
		for (int i = 1; i < PPC.getMaterialList().Count; i++)
		{
			Shader.PropertyToID("_Effect" + i);
		}
	}

	public void Setup(ScriptableRenderContext context, Camera camera)
	{
		this.context = context;
		this.camera = camera;
	}

	public void PostProcessingDrawing(PostProcessingCamera PPC, int sourceId)
	{
		createStack(PPC, sourceId);
		List<EffectObject> effects = PPC.getMaterialList();
		for (int i = 0; i < effects.Count; i++)
		effects[i].OnExecuteBuffer(sourceId, (int)BuiltinRenderTextureType.CameraTarget, effects[i].material, camera, buffer);
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}

	public void Drawing(RenderTargetIdentifier from, RenderTargetIdentifier to, Material material, int pass)
	{
		buffer.SetGlobalTexture(fxSourceId, from);
		buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
		buffer.DrawProcedural(Matrix4x4.identity, material, pass,MeshTopology.Triangles, 3);
		
		buffer.ReleaseTemporaryRT(fxSourceId);
	}
	public void Drawing(RenderTargetIdentifier from, RenderTargetIdentifier to, int pass)
	{
		buffer.SetGlobalTexture(fxSourceId, from);
		buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
		buffer.DrawProcedural(Matrix4x4.identity, null, pass, MeshTopology.Triangles, 3);

		buffer.ReleaseTemporaryRT(fxSourceId);
	}


	void createStack(PostProcessingCamera PPC, int sourceId)
    {
		createPostProcessingStack(PPC);

		buffer.BeginSample("ProcessingEffects");
		List<EffectObject> effects = PPC.getMaterialList();

		int fromId = sourceId, toId = effectsID;

		for (int i = 0;i < effects.Count;i++)
		{
			buffer.GetTemporaryRT(toId, camera.pixelWidth, camera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);

			effects[i].toID = toId;
			effects[i].fromID = fromId;
			effects[i].postProcessingStack = this;

			effects[i].OnStackedEffect(fromId, toId, effects[i].material, camera, buffer);

			//fromId = toId;
			fromId = effects[i].toID;
			toId += 1;
		}

		for (int i = 0; i < effects.Count; i++)
			effects[i].OnRelease(buffer,effects[i].material);

		//buffer.SetGlobalTexture(fxSource2Id, sourceId);
		Drawing(fromId, BuiltinRenderTextureType.CameraTarget, new Material(Shader.Find("Hidden/Standard")), 0);
		buffer.ReleaseTemporaryRT(fromId);

		buffer.EndSample("ProcessingEffects");
	}


}
