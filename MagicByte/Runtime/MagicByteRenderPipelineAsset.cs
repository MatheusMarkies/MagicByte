using UnityEngine;
using UnityEngine.Rendering;
using System.IO;
namespace MagicByte
{
	[CreateAssetMenu(menuName = "Magic Byte RP/MBRP Asset")]
	public class MagicByteRenderPipelineAsset : RenderPipelineAsset
	{

		[SerializeField]
		bool DynamicBatching = true, GPUInstancing = true, SRPBatcher = true;
		[SerializeField]
		float Gamma = 2.2f;

		[SerializeField]
		ShadowSettings realtimeShadows = default;
		protected override RenderPipeline CreatePipeline()
		{
			//if (!File.Exists(Application.dataPath + "Library\\PackageCache\\com.unity.render-pipelines.core@7.3.1"))
			//{
			//	Debug.LogError("Missing package: com.unity.render-pipelines.core");
			//}

			return new MagicByteRenderPipeline(DynamicBatching, GPUInstancing, SRPBatcher, Gamma, realtimeShadows);
		}
	}
}