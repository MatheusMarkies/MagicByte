using System;
using UnityEngine;
using UnityEngine.Rendering;
namespace MagicByte
{
	public partial class CameraRenderer
	{

		const string bufferName = "RenderCamera";

		CommandBuffer buffer = new CommandBuffer { name = bufferName };

		//static int deepBufferId = Shader.PropertyToID("_CameraDeepBuffer");
		static int frameBufferId = Shader.PropertyToID("_CameraFrameBuffer");

		Decal dacals;

		static ShaderTagId
			unlitShaderTagId = new ShaderTagId("MBUnlit"),
			litShaderTagId = new ShaderTagId("MBLit");
		static int cameraColorTextureId;

		ScriptableRenderContext context;
		Camera camera;

		CullingResults cullingResults;
		Lighting lighting = new Lighting();
		PostProcessingStack postProcessingStack = new PostProcessingStack();
		public void Render(ScriptableRenderContext context, Camera camera, bool useDynamicBatching, bool useGPUInstancing, ShadowSettings shadowSettings)
		{
			this.context = context;
			this.camera = camera;

			camera.renderingPath = RenderingPath.DeferredShading;
			camera.allowMSAA = false;
			camera.allowHDR = true;

			context.SetupCameraProperties(camera);

			PrepareBuffer();
			PrepareForSceneWindow();
			if (!Cull(shadowSettings.maxDistance))
			{
				return;
			}

			buffer.BeginSample(bufferName);
			ExecuteBuffer();
			lighting.Setup(context, cullingResults, shadowSettings);
			buffer.EndSample(bufferName);

			Setup();
			DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
			DrawUnsupportedShaders();


			//DecalLoad decalLoad = camera.GetComponent<DecalLoad>();
			//if (decalLoad)
			//{
			//	foreach (Decal decal in decalLoad.getDecalList())
			//	{
			//		decal.PreLoadDecal(this.camera);
			//		decal.OnRederDecal(context);
			//	}

			//}

			if (camera.TryGetComponent<PostProcessingLayer>(out PostProcessingLayer postProcessingLayer))
			{
				postProcessingStack.setRenderContext(context);

				postProcessingLayer.OnRenderCamera();
				postProcessingStack.postProcessingDrawing(postProcessingLayer.getEffects(), frameBufferId, camera, postProcessingLayer.getRenderTextures());
			}

			DrawGizmos();
			Cleanup();
			Submit();
		}

		void Cleanup()
		{
			lighting.Cleanup();
			//if(PostProcessActive)
			buffer.ReleaseTemporaryRT(frameBufferId);
		}

		bool Cull(float maxShadowDistance)
		{
			if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
			{
				p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
				cullingResults = context.Cull(ref p);
				return true;
			}
			return false;
		}

		void Setup()
		{
			context.SetupCameraProperties(camera);
			CameraClearFlags flags = camera.clearFlags;

			if (camera.TryGetComponent<PostProcessingLayer>(out PostProcessingLayer postProcessingLayer))
			{
				if (flags > CameraClearFlags.Color)
				{
					flags = CameraClearFlags.Color;
				}

				buffer.GetTemporaryRT(frameBufferId, camera.pixelWidth, camera.pixelHeight, 32, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);//Pegar textura de renderizacao
				buffer.SetRenderTarget(frameBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);//Renderizar efeitos
			}

			buffer.ClearRenderTarget(flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color, flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);

			buffer.BeginSample(SampleName);
			ExecuteBuffer();
		}

		void Submit()
		{
			buffer.EndSample(SampleName);
			ExecuteBuffer();
			try
			{
				context.Submit();
            }
            catch (Exception e) { }
		}

		void ExecuteBuffer()
		{
			context.ExecuteCommandBuffer(buffer);
			buffer.Clear();
		}

		void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing)
		{

			//RenderTexture rt0 = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.ARGB32);
			//RenderTexture rt1 = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.ARGB32);
			//RenderTexture rt2 = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.ARGB2101010);
			//RenderTexture rt3 = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 24, RenderTextureFormat.DefaultHDR);

			//RenderBuffer[] colorBuffers = new RenderBuffer[4];
			//colorBuffers[0] = rt0.colorBuffer;
			//colorBuffers[1] = rt1.colorBuffer;
			//colorBuffers[2] = rt2.colorBuffer;
			//colorBuffers[3] = rt3.colorBuffer;
			//camera.SetTargetBuffers(colorBuffers, rt3.depthBuffer);

			var sortingSettings = new SortingSettings(camera)
			{
				criteria = SortingCriteria.CommonOpaque
			};
			var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings)
			{
				enableDynamicBatching = useDynamicBatching,
				enableInstancing = useGPUInstancing,
				perObjectData = PerObjectData.ReflectionProbes |
					PerObjectData.Lightmaps | PerObjectData.ShadowMask |
					PerObjectData.LightProbe | PerObjectData.OcclusionProbe |
					PerObjectData.LightProbeProxyVolume |
					PerObjectData.OcclusionProbeProxyVolume
			};

			//Shader.SetGlobalTexture("_CameraGBufferTexture0", rt0);
			//Shader.SetGlobalTexture("_CameraGBufferTexture1", rt1);
			//Shader.SetGlobalTexture("_CameraGBufferTexture2", rt2);
			//Shader.SetGlobalTexture("_CameraGBufferTexture3", rt3);

			drawingSettings.SetShaderPassName(1, litShaderTagId);

			var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

			context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

			context.DrawSkybox(camera);

			sortingSettings.criteria = SortingCriteria.CommonTransparent;
			drawingSettings.sortingSettings = sortingSettings;
			filteringSettings.renderQueueRange = RenderQueueRange.transparent;

			context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
		}
	}
}