using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

class StandardClass : EffectObject
{
    public override void OnStackedEffect(int src, int dst, Material material, Camera camera, CommandBuffer buffer)
	{
		buffer.BeginSample("Standard");
		int width = camera.pixelWidth, height = camera.pixelHeight;

		int fromId = fromID, toId = toID;
		int i;
		//for (i = 0; i < maxStackEffect; i++)
		//{
		//	if (height < 1 || width < 1)
		//	{
		//		break;
		//	}
		//buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
		//postProcessingStack.Drawing(fromId, toId, material,0);

		postProcessingStack.Drawing(fromId, toId, material, 0);

		//	width /= 2;
		//	height /= 2;
		//}
		buffer.EndSample("Standard");
	}
	public override void OnRelease(CommandBuffer buffer, Material material)
	{
		int i = passNumber;
		for (i -= 1; i >= 0; i--)
		{
			buffer.ReleaseTemporaryRT(ID + i);
		}
	}
	public override void OnExecuteBuffer(int src, int dst, Material material, Camera camera, CommandBuffer buffer) { }
}
class BloomClass : EffectObject
{
	int fxSource2Id = Shader.PropertyToID("_PostFXSource2");
	int fxSourceId = Shader.PropertyToID("_PostFXSource");
	int bloomThresholdId = Shader.PropertyToID("_BloomThreshold");
	int bloomPrefilterId = Shader.PropertyToID("_BloomPrefilter");
	public override void OnStackedEffect(int src, int dst, Material material, Camera camera, CommandBuffer buffer)
    {
		ID = Shader.PropertyToID("_BloomPyramid0");

		for (int y = 0; y < passNumber * 2; y++)
		{
			Shader.PropertyToID("_BloomPyramid" + y);
		}

		buffer.BeginSample("Bloom");
		int width = camera.pixelWidth / 2, height = camera.pixelHeight / 2;
		RenderTextureFormat format = RenderTextureFormat.DefaultHDR;
		int fromId = fromID, toId = ID + 1;

		//buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, format);
		//postProcessingStack.Drawing(fromId, toId, material,0);

		//buffer.GetTemporaryRT(bloomPrefilterId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
		//postProcessingStack.Drawing(fromId, bloomPrefilterId, material, 5);

		int i =0;
		for (i = 0; i < passNumber; i++)
		{

			//if (height < 2 || width < 2)
			//{
			//	break;
			//}

			buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
			postProcessingStack.Drawing(fromId, toId, material, (int)EffectsCompose.Pass.Copy);
			postProcessingStack.Drawing(fromId, toId, material, 2);

			int midId = toId - 1;
			buffer.GetTemporaryRT(midId, width, height, 0, FilterMode.Bilinear, format);
			buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, format);
			postProcessingStack.Drawing(fromId, midId, material, 2);
			postProcessingStack.Drawing(midId, toId, material, 3);
			//if(i == passNumber)
			//postProcessingStack.Drawing(fromId, toId, material, 4);

			fromId = toId;
			staticID = fromId;
			toId += 2;

			width /= 2;
			height /= 2;
            if (height < 2 || width < 2)
            {
                postProcessingStack.Drawing(fromId, BuiltinRenderTextureType.CameraTarget, material, 1);
                buffer.EndSample("Bloom");
                return;
            }
        }
		if (i > 1)
		{
			buffer.ReleaseTemporaryRT(fromId - 1);
			toId -= 5;
			for (i -= 1; i > 0; i--)
			{
				buffer.SetGlobalTexture(fxSource2Id, toId + 1);
			    postProcessingStack.Drawing(fromId, toId,material, 4);
				buffer.ReleaseTemporaryRT(fromId);
				buffer.ReleaseTemporaryRT(toId + 1);
				fromId = toId;
				toId -= 2;
			}
		}
		else
		{
			buffer.ReleaseTemporaryRT(ID);
		}

		postProcessingStack.Drawing(fromId, BuiltinRenderTextureType.CameraTarget,material, 4);
			buffer.ReleaseTemporaryRT(fromId);

			toID = toId;
		buffer.EndSample("Bloom");
	}
	public override void OnRelease(CommandBuffer buffer, Material material)
	{
		int fromId = staticID, toId = ID + 1;
		int i = passNumber;
		for (i -= 1; i > 0; i--)
		{
			buffer.SetGlobalTexture(fxSource2Id, toId + 1);
			postProcessingStack.Drawing(fromId, toId, material, 4); ;
			buffer.ReleaseTemporaryRT(fromId);
			buffer.ReleaseTemporaryRT(toId + 1);
			fromId = toId;
			toId -= 2;
		}
	}
	public override void OnExecuteBuffer(int src, int dst, Material material, Camera camera, CommandBuffer buffer) 
	{

	}
}
class ToneMappingClass : EffectObject
{
    public override void OnStackedEffect(int src, int dst, Material material, Camera camera, CommandBuffer buffer)
    {
		buffer.BeginSample("ToneMapping");
		int width = camera.pixelWidth, height = camera.pixelHeight;

		int fromId = fromID, toId = toID;
		int i;
		//for (i = 0; i < maxStackEffect; i++)
		//{
		//	if (height < 1 || width < 1)
		//	{
		//		break;
		//	}
			//buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
			//postProcessingStack.Drawing(fromId, toId, material,0);

			postProcessingStack.Drawing(fromId, toId, material, 0);

		//	width /= 2;
		//	height /= 2;
		//}
		postProcessingStack.Drawing(toId, BuiltinRenderTextureType.CameraTarget, new Material(Shader.Find("Hidden/Standard")), 0);
		buffer.EndSample("ToneMapping");
	}
	public override void OnRelease(CommandBuffer buffer, Material material)
	{
		int i = passNumber;
		for (i -= 1; i >= 0; i--)
		{
			buffer.ReleaseTemporaryRT(ID + i);
		}
	}
	public override void OnExecuteBuffer(int src, int dst, Material material, Camera camera, CommandBuffer buffer) { }
}
class LensFlareClass : EffectObject
{
	int fxSourceId = Shader.PropertyToID("_PostFXSource");
	public override void OnStackedEffect(int src, int dst, Material material, Camera camera, CommandBuffer buffer)
	{
		buffer.BeginSample("LensFlare");
		int width = camera.pixelWidth, height = camera.pixelHeight;

		int fromId = fromID, toId = toID;
		int i;
		for (i = 0; i < passNumber; i++)
		{

			buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
			postProcessingStack.Drawing(fromId, toId, material, (int)EffectsCompose.Pass.Copy);

			buffer.SetGlobalTexture(fxSourceId, toId);
			postProcessingStack.Drawing(fromId, toId, material, 1);

			fromId = toId;
			staticID = fromId;
			toId += 1;

				buffer.EndSample("Bloom");
		}
	}
	public override void OnRelease(CommandBuffer buffer, Material material)
	{
		int i = passNumber;
		for (i -= 1; i >= 0; i--)
		{
			buffer.ReleaseTemporaryRT(ID + i);
		}
	}
	public override void OnExecuteBuffer(int src, int dst, Material material, Camera camera, CommandBuffer buffer) { }
}
class RaymarchingClass : EffectObject
{

	public override void OnStackedEffect(int src, int dst, Material material, Camera camera, CommandBuffer buffer)
	{
		buffer.BeginSample("Raymarching");
		int width = camera.pixelWidth, height = camera.pixelHeight;

		int fromId = fromID, toId = toID;
		int i;
		//for (i = 0; i < maxStackEffect; i++)
		//{
		//	if (height < 1 || width < 1)
		//	{
		//		break;
		//	}
		//buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
		//postProcessingStack.Drawing(fromId, toId, material,0);

		postProcessingStack.Drawing(fromId, toId, material, 0);

		//	width /= 2;
		//	height /= 2;
		//}
		buffer.EndSample("Raymarching");
	}
	public override void OnRelease(CommandBuffer buffer, Material material)
	{
		int i = passNumber;
		for (i -= 1; i >= 0; i--)
		{
			buffer.ReleaseTemporaryRT(ID + i);
		}
	}
	public override void OnExecuteBuffer(int src, int dst, Material material, Camera camera, CommandBuffer buffer) {

		//GL.PushMatrix();
		//GL.LoadOrtho();
		//GL.Begin(GL.QUADS);

		//GL.MultiTexCoord2(0, 0.0f, 0.0f);
		//GL.Vertex3(0.0f,0.0f,3.0f);

		//GL.MultiTexCoord2(0, 1.0f, 0.0f);
		//GL.Vertex3(1.0f, 0.0f, 2.0f);

		//GL.MultiTexCoord2(0, 1.0f, 1.0f);
		//GL.Vertex3(1.0f, 1.0f, 1.0f);

		//GL.MultiTexCoord2(0, 0.0f,1.0f);
		//GL.Vertex3(0.0f, 1.0f, 0.0f);

		//GL.End();
		//GL.PopMatrix();
	}

}

public class EffectsCompose { 

	public enum Pass
    {
		Copy = 0
    }
	public Pass pass;

}
