using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;
using UnityEngine.Experimental.GlobalIllumination;
using LightType = UnityEngine.LightType;
using System.IO;
namespace MagicByte
{
	public partial class MagicByteRenderPipeline : RenderPipeline
	{

		CameraRenderer renderer = new CameraRenderer();

		bool DynamicBatching, GPUInstancing;
		float Gamma;
		ShadowSettings shadowSettings;
		public MagicByteRenderPipeline(bool dynamicBatching, bool GPUInstancing, bool SRPBatcher, float Gamma, ShadowSettings shadowSettings)
		{
			this.shadowSettings = shadowSettings;
			this.DynamicBatching = dynamicBatching;
			this.GPUInstancing = GPUInstancing;
			this.Gamma = Gamma;
			GraphicsSettings.useScriptableRenderPipelineBatching = SRPBatcher;
			GraphicsSettings.lightsUseLinearIntensity = true;

			InitializeForEditor();
		}

		protected override void Render(ScriptableRenderContext context, Camera[] cameras)
		{
			GraphicsSettings.lightsUseLinearIntensity = (QualitySettings.activeColorSpace == ColorSpace.Linear);
			GraphicsSettings.lightsUseColorTemperature = true;

			foreach (Camera camera in cameras)
			{
				renderer.Render(context, camera, Gamma, DynamicBatching, GPUInstancing, shadowSettings);
			}
		}
	}

	public partial class MagicByteRenderPipeline
	{

		partial void InitializeForEditor();

#if UNITY_EDITOR

		partial void InitializeForEditor()
		{
			Lightmapping.SetDelegate(lightsDelegate);
		}

		protected override void Dispose(bool disposing)
		{
			base.Dispose(disposing);
			Lightmapping.ResetDelegate();
		}

		static Lightmapping.RequestLightsDelegate lightsDelegate = (Light[] lights, NativeArray<LightDataGI> output) =>
		{
			var lightData = new LightDataGI();
			for (int i = 0; i < lights.Length; i++)
			{
				Light light = lights[i];
				switch (light.type)
				{
					case LightType.Directional:
						var directionalLight = new DirectionalLight();
						LightmapperUtils.Extract(light, ref directionalLight);
						lightData.Init(ref directionalLight);
						break;
					case LightType.Point:
						var pointLight = new PointLight();
						LightmapperUtils.Extract(light, ref pointLight);
						lightData.Init(ref pointLight);
						break;
					case LightType.Spot:
						var spotLight = new SpotLight();
						LightmapperUtils.Extract(light, ref spotLight);
						lightData.Init(ref spotLight);
						break;
					case LightType.Area:
						var rectangleLight = new RectangleLight();
						rectangleLight.mode = LightMode.Baked;
						LightmapperUtils.Extract(light, ref rectangleLight);
						lightData.Init(ref rectangleLight);
						break;
					default:
						lightData.InitNoBake(light.GetInstanceID());
						break;
				}
				lightData.falloff = FalloffType.InverseSquared;
				output[i] = lightData;
			}
		};


#endif

	}
}