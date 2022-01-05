using System;
using UnityEngine;
using UnityEngine.Rendering;
namespace MagicByte
{
	public partial class CameraRenderer
	{

		const string bufferName = "Render";

		CommandBuffer buffer = new CommandBuffer { name = bufferName };

		static readonly int frameBufferId = Shader.PropertyToID("_CameraFrameBuffer");

		Decal dacals;

		Shader depthShader = Shader.Find("Hidden/DepthTexture");
		float depthLevel = 4;

		int _GBuffer0 = Shader.PropertyToID("_CameraGBufferTexture0");
		int _GBuffer1 = Shader.PropertyToID("_CameraGBufferTexture1");
		int _GBuffer2 = Shader.PropertyToID("_CameraGBufferTexture2");
		int _GBuffer3 = Shader.PropertyToID("_CameraGBufferTexture3");
	
		static ShaderTagId
			unlitShaderTagId = new ShaderTagId("MBUnlit"),
			litShaderTagId = new ShaderTagId("MBLit"),
		    standardShaderTagId = new ShaderTagId("Deferred");
		static int cameraColorTextureId;

		ScriptableRenderContext context;
		Camera camera;

		CullingResults cullingResults;
		Lighting lighting = new Lighting();
		PostProcessingStack postProcessingStack = new PostProcessingStack();
		PathTracingStack pathTracingStack = new PathTracingStack();
		public void Render(ScriptableRenderContext context, Camera camera, float Gamma, bool useDynamicBatching, bool useGPUInstancing, ShadowSettings shadowSettings)
		{
			this.context = context;
			this.camera = camera;

			buffer.SetGlobalFloat("_Gamma", Gamma);
			buffer.SetGlobalFloat("_FarPlane", camera.farClipPlane);
			buffer.SetGlobalFloat("_NearPlane", camera.nearClipPlane);

			camera.renderingPath = RenderingPath.DeferredShading;
			camera.allowMSAA = false;
			camera.allowHDR = true;

			context.SetupCameraProperties(camera);

			PrepareBuffer();
			PrepareForSceneWindow();

			if (!Cull(shadowSettings.maxDistance)){ return; }

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

			if (camera.TryGetComponent<PathTracing>(out PathTracing pathTracing))
			{
				pathTracingStack.setRenderContext(context);
				pathTracingStack.pathTracingDrawing(pathTracing, frameBufferId, camera);
			}else
			if (camera.TryGetComponent<PostProcessingLayer>(out PostProcessingLayer postProcessingLayer))
            {
                postProcessingStack.setRenderContext(context);

                postProcessingLayer.OnRenderCamera();
                postProcessingStack.postProcessingDrawing(postProcessingLayer.getEffects(), frameBufferId, camera);
            }

            DrawingGBuffers();

			DrawGizmos();
			Cleanup();
			Submit();
		}

		void Cleanup()
		{
			lighting.Cleanup();

			buffer.ReleaseTemporaryRT(frameBufferId);

			buffer.ReleaseTemporaryRT(_GBuffer0);
			buffer.ReleaseTemporaryRT(_GBuffer1);
			buffer.ReleaseTemporaryRT(_GBuffer2);
			buffer.ReleaseTemporaryRT(_GBuffer3);
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

            if (camera.TryGetComponent<PostProcessingLayer>(out PostProcessingLayer postProcessingLayer) || camera.TryGetComponent<PathTracing>(out PathTracing pathTracing))
			{ 
                if (flags > CameraClearFlags.Color)
                {
                    flags = CameraClearFlags.Color;
                }

                buffer.GetTemporaryRT(frameBufferId, camera.pixelWidth, camera.pixelHeight, 32, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);//Pegar textura de renderizacao
                buffer.SetRenderTarget(frameBufferId, RenderBufferLoadAction.Load, RenderBufferStoreAction.StoreAndResolve);//Renderizar efeitos
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

			drawingSettings.SetShaderPassName(1, litShaderTagId);
			drawingSettings.SetShaderPassName(2, standardShaderTagId);

			var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

			context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

			context.DrawSkybox(camera);

			sortingSettings.criteria = SortingCriteria.CommonTransparent;
			drawingSettings.sortingSettings = sortingSettings;
			filteringSettings.renderQueueRange = RenderQueueRange.transparent;
			
			context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
		}
		void DrawingGBuffers()
        {
			buffer.BeginSample("Drawing GBuffers");

			buffer.GetTemporaryRT(_GBuffer0, camera.pixelWidth, camera.pixelHeight);
			buffer.Blit(BuiltinRenderTextureType.GBuffer0 , _GBuffer0);

			buffer.GetTemporaryRT(_GBuffer1, camera.pixelWidth, camera.pixelHeight);
			buffer.Blit(BuiltinRenderTextureType.GBuffer1, _GBuffer1);

			buffer.GetTemporaryRT(_GBuffer2, camera.pixelWidth, camera.pixelHeight);
			buffer.Blit(BuiltinRenderTextureType.GBuffer2, _GBuffer2);

			buffer.GetTemporaryRT(_GBuffer3, camera.pixelWidth, camera.pixelHeight);
			buffer.Blit(BuiltinRenderTextureType.GBuffer3, _GBuffer3);
			
			RenderTargetIdentifier[] gbuffersRenderTarget = { BuiltinRenderTextureType.GBuffer0,
										   BuiltinRenderTextureType.GBuffer1,
										   BuiltinRenderTextureType.GBuffer2,
										   BuiltinRenderTextureType.GBuffer3};
			buffer.SetRenderTarget(gbuffersRenderTarget, BuiltinRenderTextureType.CameraTarget);

			buffer.SetGlobalTexture("_GBufferTexture0", _GBuffer0);
			buffer.SetGlobalTexture("_GBufferTexture1", _GBuffer1);
			buffer.SetGlobalTexture("_GBufferTexture2", _GBuffer2);
			buffer.SetGlobalTexture("_GBufferTexture3", _GBuffer3);

			buffer.EndSample("Drawing GBuffers");
		}
	}
}