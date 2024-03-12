using UnityEngine;
namespace MagicByte
{
	[System.Serializable]
	public class ShadowSettings
	{

		public enum MapSize
		{
			_256 = 256, _512 = 512, _1024 = 1024,
			_2048 = 2048, _4096 = 4096, _8192 = 8192, _16384 = 16384
		}

		public enum FilterMode
		{
			PCF2x2, PCF3x3, PCF5x5, PCF7x7
		}

		[Min(0.001f)]
		public float maxDistance = 100f;

		[Range(0.001f, 1f)]
		public float distanceFade = 1f;

		[Range(0.0f, 1.50f)]
		public float scatteringBorders = 0f;

		[System.Serializable]
		public struct Directional
		{

			public MapSize ShadowMapSize;

			public FilterMode filter;

			public int cascadeCount => 4;

			//public float cascadeRatio1, cascadeRatio2, cascadeRatio3;

			public Vector3 CascadeRatios => new Vector3(0.3f, 0.4f, 0.5f);

			public float cascadeFade => 1f;

			public enum CascadeBlendMode
			{
				Hard, Soft, Dither
			}

			public CascadeBlendMode cascadeBlend;
		}

		public Directional directional = new Directional
		{
			ShadowMapSize = MapSize._1024,
			filter = FilterMode.PCF2x2,
			//cascadeCount = 4,
			//cascadeRatio1 = 0.1f,
			//cascadeRatio2 = 0.25f,
			//cascadeRatio3 = 0.5f,
			//cascadeFade = 1f,
			cascadeBlend = Directional.CascadeBlendMode.Hard
		};
	}
}