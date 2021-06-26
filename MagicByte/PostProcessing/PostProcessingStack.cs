using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
namespace MagicByte
{
	public class PostProcessingStack
	{
		int fxSourceId = Shader.PropertyToID("_PostFXSource");
		CommandBuffer buffer = new CommandBuffer { name = "Post Processing Workflow" };
		ScriptableRenderContext context;

		int pathTracingID = Shader.PropertyToID("_PathTracingFrame");

		CommandBuffer bufferPT = new CommandBuffer { name = "Path Tracing" };
		RenderTexture rt;
		public void setRenderContext(ScriptableRenderContext context)
		{ this.context = context; }

		public void postProcessingDrawing(List<Effect> effects, int sourceId,Camera camera,List<RenderTexture> RTs)
		{
			bufferPT.BeginSample("Path tracing Render");

			if (RTs.Count > 0)
			{
				bufferPT.SetGlobalTexture(pathTracingID, RenderTexturetoTexture2D(RTs[0]));
				bufferPT.SetGlobalFloat("_usePathTracing",1);
			}else
				bufferPT.SetGlobalFloat("_usePathTracing", 0);

			bufferPT.EndSample("Path tracing Render");
			context.ExecuteCommandBuffer(bufferPT);
			bufferPT.Clear();

            startRenderPass(effects, sourceId, camera);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }
		Texture2D RenderTexturetoTexture2D(RenderTexture rTex)
		{
			Texture2D tex = new Texture2D(512, 512, TextureFormat.RGB24, false);

			RenderTexture.active = rTex;
			tex.ReadPixels(new Rect(0, 0, rTex.width, rTex.height), 0, 0);
			tex.Apply();
			return tex;
		}
		public void drawingEffect(RenderTargetIdentifier from, RenderTargetIdentifier to, Material material, int pass,Camera camera)
		{
			buffer.GetTemporaryRT(fxSourceId, camera.pixelWidth, camera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);

			buffer.SetGlobalTexture(fxSourceId, from);
			//buffer.SetGlobalTexture(fxSourceId, RenderTexturetoTexture2D(RenderTexture rTex));
			buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
			buffer.DrawProcedural(Matrix4x4.identity, material, pass, MeshTopology.Triangles, 3);

			buffer.ReleaseTemporaryRT(fxSourceId);
		}
		//Mono Pass
		int effectsID;
		void stackedEffects(List<Effect> effects)
		{
			int offset = 0;
			effectsID = Shader.PropertyToID("_Effect0");

			for (int i = 0; i < effects.Count; i++)
			{
				for (int o = 1; o < effects[i].passes; o++)
				{
					if (i > 0)
					{
						for (int u = 0; u < i - 1; u++)
							offset += effects[u].passes;
						Shader.PropertyToID("_Effect" + offset + o);
					}
					else
						Shader.PropertyToID("_Effect" + o);
				}
			}
		}

		void startRenderPass(List<Effect> effects, int sourceId,Camera camera) 
		{
			stackedEffects(effects);

			int fromId = sourceId, toId = effectsID;

			int i;
			for (i = 0; i < effects.Count; i++)
			{
				buffer.GetTemporaryRT(toId, camera.pixelWidth, camera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);

				effects[i].renderPasses(this, buffer, fromId, toId, camera);

				fromId = effects[i].ToID;
				toId += effects[i].passes;
			}

			drawingEffect(fromId, BuiltinRenderTextureType.CameraTarget, new Material(Shader.Find("Hidden/Standard")), 0,camera);
			for(int o = i; o > 0; o--)
            {
				buffer.ReleaseTemporaryRT(toId - o);
            }
		}

	}
}