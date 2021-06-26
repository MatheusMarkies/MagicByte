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
		ShadowSettings realtimeShadows = default;
		protected override RenderPipeline CreatePipeline()
		{
			if (File.Exists(Application.dataPath + "Library\\PackageCache\\com.unity.render-pipelines.core@7.3.1"))
			{
				File.Delete(Application.dataPath + "Assets\\MagicByte\\Unity-RenderPipelineCore");
			}

			return new MagicByteRenderPipeline(DynamicBatching, GPUInstancing, SRPBatcher, realtimeShadows);
		}
	}
}