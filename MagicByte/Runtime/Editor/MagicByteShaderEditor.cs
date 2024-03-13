using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class MagicByteShaderEditor : ShaderGUI {

	MaterialEditor editor;
	Object[] materials;
	MaterialProperty[] properties;

	bool showLightingPresets = true;
	bool showMaterialsPresets = true;

	#region Property and Values:
	Color BaseColor
	{
		set => FindProperty("_BaseColor", properties, false).colorValue = value;
	}
	float Metallic
	{
		set => SetProperty("_Metallic", value);
	}
	float Smoothness
	{
		set => SetProperty("_Smoothness", value);
	}
	float Occlusion
	{
		set => SetProperty("_Occlusion", value);
	}
	float Sheen
	{
		set => SetProperty("_Sheen", value);
	}
	float SheenTint
	{
		set => SetProperty("_SheenTint", value);
	}
	float SubSurface
	{
		set => SetProperty("_SubSurface", value);
	}
	float Anisotropic
	{
		set => SetProperty("_Anisotropic", value);
	}
	float Transmission
	{
		set => SetProperty("_Transmission", value);
	}
	bool Clipping {
		set => SetProperty("_Clipping", "_CLIPPING", value);
	}

	bool HasPremultiplyAlpha => HasProperty("_PremulAlpha");

	bool PremultiplyAlpha {
		set => SetProperty("_PremulAlpha", "_PREMULTIPLY_ALPHA", value);
	}

	BlendMode SrcBlend {
		set => SetProperty("_SrcBlend", (float)value);
	}

	BlendMode DstBlend {
		set => SetProperty("_DstBlend", (float)value);
	}

	bool ZWrite {
		set => SetProperty("_ZWrite", value ? 1f : 0f);
	}
    #endregion

    enum ShadowMode {
		On, Clip, Dither, Off
	}

	ShadowMode Shadows {
		set {
			if (SetProperty("_Shadows", (float)value)) {
				SetKeyword("_SHADOWS_CLIP", value == ShadowMode.Clip);
				SetKeyword("_SHADOWS_DITHER", value == ShadowMode.Dither);
			}
		}
	}

	RenderQueue RenderQueue {
		set {
			foreach (Material m in materials) {
				m.renderQueue = (int)value;
			}
		}
	}

	bool showAlpha = false;
	bool showHeight = false;
	bool showNormal = false;
	bool showMetallic = false;
	bool showSmoothness = false;
	bool showOcclusion = false;
	bool showEmission = false;
	bool showSheen = false;
	bool showScattering = false;
	bool showClearCoat = false;

	public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] properties) {

		EditorGUI.BeginChangeCheck();
		//base.OnGUI(materialEditor, properties);

		editor = materialEditor;
		materials = materialEditor.targets;
		this.properties = properties;

		MaterialProperty AlbedoMap = FindProperty("_BaseMap", properties);
		GUIContent AlbedoGUI = new GUIContent(AlbedoMap.displayName);
		editor.TexturePropertySingleLine(AlbedoGUI, AlbedoMap, FindProperty("_BaseColor", properties));

		showAlpha = EditorGUILayout.Foldout(showAlpha, "Alpha", true);
		if (showAlpha)
			ShowAlpha();

		showHeight = EditorGUILayout.Foldout(showHeight, "Paralax", true);
		if (showHeight)
			ShowHeight();

		showNormal = EditorGUILayout.Foldout(showNormal, "Normal Map", true);
		if (showNormal)
			ShowNormal();

		showMetallic = EditorGUILayout.Foldout(showMetallic, "Metallic", true);
		if (showMetallic)
			ShowMetallic();

		showSmoothness = EditorGUILayout.Foldout(showSmoothness, "Smoothness", true);
		if (showSmoothness)
			ShowSmoothness();

		showOcclusion = EditorGUILayout.Foldout(showOcclusion, "Occlusion", true);
		if (showOcclusion)
			ShowOcclusion();

		showEmission = EditorGUILayout.Foldout(showEmission, "Emission", true);
		if (showEmission)
			ShowEmission();

		showSheen = EditorGUILayout.Foldout(showSheen, "Sheen", true);
		if (showSheen)
			ShowSheen();

		showScattering = EditorGUILayout.Foldout(showScattering, "Light Scattering", true);
		if (showScattering)
			ShowScattering();

		showClearCoat = EditorGUILayout.Foldout(showClearCoat, "Clear Coat", true);
		if (showClearCoat)
			ShowClearCoat();

		EditorGUILayout.Space();
		BakedEmission();

		EditorGUILayout.Space();
		showLightingPresets = EditorGUILayout.Foldout(showLightingPresets, "Lighting Presets", true);
		if (showLightingPresets) {
			OpaquePreset();
			TransparentPreset();
		}

		EditorGUILayout.Space();
		showMaterialsPresets = EditorGUILayout.Foldout(showMaterialsPresets, "Color Presets", true);
		if (showMaterialsPresets)
		{
			GUILayout.Label("Metallic:");
			if (PresetButton("Silver"))
            {
				if (ColorUtility.TryParseHtmlString("#aaa9ad", out Color color))
					BaseColor = color;
            }
			if (PresetButton("Aluminum"))
			{
				if (ColorUtility.TryParseHtmlString("#faf5f5", out Color color))
					BaseColor = color;
			}
			if (PresetButton("Platinum"))
			{
				if (ColorUtility.TryParseHtmlString("#d6d1c8", out Color color))
					BaseColor = color;
			}
			if (PresetButton("Iron"))
			{
				if (ColorUtility.TryParseHtmlString("#c0bdba", out Color color))
					BaseColor = color;
			}
			if (PresetButton("Titanium"))
			{
				if (ColorUtility.TryParseHtmlString("#cec8c2", out Color color))
					BaseColor = color;
			}
			if (PresetButton("Copper"))
			{
				if (ColorUtility.TryParseHtmlString("#B87333", out Color color))
					BaseColor = color;
			}
			if (PresetButton("Gold"))
			{
				if (ColorUtility.TryParseHtmlString("#fedc9d", out Color color))
					BaseColor = color;
			}
			if (PresetButton("Brass"))
			{
				if (ColorUtility.TryParseHtmlString("#f4e4ad", out Color color))
					BaseColor = color;
			}
			GUILayout.Label("Non Metallic:");
		}

		if (EditorGUI.EndChangeCheck()) {
			SetShadowCasterPass();
			CopyLightMappingProperties();
		}
	}

	void ShowAlpha()
    {
		MaterialProperty AlphaMap = FindProperty("_AlphaMap", properties);
		GUIContent AlphaGUI = new GUIContent(AlphaMap.displayName);
		editor.TexturePropertySingleLine(AlphaGUI, AlphaMap);

		MaterialProperty AlphaCutoff = FindProperty("_Cutoff", properties);
		editor.ShaderProperty(AlphaCutoff, "Alpha Cutoff");

		MaterialProperty Alpha = FindProperty("_Clipping", properties);
		editor.ShaderProperty(Alpha, "Alpha Clipping");
	}

	void ShowHeight()
	{
		editor.ShaderProperty(FindProperty("_HeightMode", properties), "Height Mode");
		MaterialProperty HeightMap = FindProperty("_HeightMap", properties);
		GUIContent HeightMapGUI = new GUIContent(HeightMap.displayName);
		editor.TexturePropertySingleLine(HeightMapGUI, HeightMap, FindProperty("_Height", properties));
	}


	void ShowNormal()
	{
		MaterialProperty NormalMap = FindProperty("_NormalMap", properties);
		GUIContent NormalGUI = new GUIContent(NormalMap.displayName);
		editor.TexturePropertySingleLine(NormalGUI, NormalMap, FindProperty("_NormalStrength", properties));
		editor.VectorProperty(FindProperty("_TillingNormal", properties), "Tilling Normal");
	}

	void ShowMetallic()
	{
		MaterialProperty MetalMap = FindProperty("_MetalMap", properties);
		GUIContent MetalMapGUI = new GUIContent(MetalMap.displayName);
		editor.TexturePropertySingleLine(MetalMapGUI, MetalMap, FindProperty("_Metallic", properties));
	}
	void ShowSmoothness()
	{
		MaterialProperty SmoothnessMap = FindProperty("_SmoothnessMap", properties);
		GUIContent SmoothnessMapGUI = new GUIContent(SmoothnessMap.displayName);
		
		MaterialProperty UseRoughness = FindProperty("_UseRoughness", properties);
		editor.ShaderProperty(UseRoughness, "Map Input Format");
		editor.TexturePropertySingleLine(SmoothnessMapGUI, SmoothnessMap);
		editor.ShaderProperty(FindProperty("_Smoothness", properties), "Smoothness");
		editor.ShaderProperty(FindProperty("_Anisotropic", properties), "Anisotropic");
	}

	void ShowOcclusion()
	{
		MaterialProperty OcclusionMap = FindProperty("_OcclusionMap", properties);
		GUIContent OcclusionMapGUI = new GUIContent(OcclusionMap.displayName);
		editor.TexturePropertySingleLine(OcclusionMapGUI, OcclusionMap, FindProperty("_Occlusion", properties));
	}
	void ShowEmission()
	{
		MaterialProperty EmissionMapMap = FindProperty("_EmissionMap", properties);
		GUIContent EmissionMapMapGUI = new GUIContent(EmissionMapMap.displayName);
		editor.TexturePropertySingleLine(EmissionMapMapGUI, EmissionMapMap, FindProperty("_EmissionColor", properties));
	}
	void ShowSheen()
	{
		editor.ShaderProperty(FindProperty("_Sheen", properties), "Sheen");
		editor.ShaderProperty(FindProperty("_SheenTint", properties), "Sheen Tint");
	}

	void ShowScattering()
	{
		GUILayout.Label("BTDF");
		editor.ShaderProperty(FindProperty("_SubSurfaceColor", properties), "SubSurface Color");
		editor.ShaderProperty(FindProperty("_Transmission", properties), "Transmission");
		editor.ShaderProperty(FindProperty("_SubSurface", properties), "Sub Surface");
		EditorGUILayout.Space();
		GUILayout.Label("Scattering");
		editor.ShaderProperty(FindProperty("_IOR", properties), "IOR");
		editor.ShaderProperty(FindProperty("_ScatteringScale", properties), "Scattering Scale");
	}
	void ShowClearCoat()
	{
		editor.ShaderProperty(FindProperty("_UseClearCoat", properties), "Use ClearCoat");
		editor.ShaderProperty(FindProperty("_ClearCoatRoughness", properties), "ClearCoat Roughness");
		editor.ShaderProperty(FindProperty("_ClearCoat", properties), "ClearCoat Intensity");
	}

	void CopyLightMappingProperties () {
		MaterialProperty mainTex = FindProperty("_MainTex", properties, false);
		MaterialProperty baseMap = FindProperty("_BaseMap", properties, false);
		if (mainTex != null && baseMap != null) {
			mainTex.textureValue = baseMap.textureValue;
			mainTex.textureScaleAndOffset = baseMap.textureScaleAndOffset;
		}
		MaterialProperty color = FindProperty("_Color", properties, false);
		MaterialProperty baseColor =
			FindProperty("_BaseColor", properties, false);
		if (color != null && baseColor != null) {
			color.colorValue = baseColor.colorValue;
		}
	}

	void BakedEmission () {
		EditorGUI.BeginChangeCheck();
		editor.LightmapEmissionProperty();
		if (EditorGUI.EndChangeCheck()) {
			foreach (Material m in editor.targets) {
				m.globalIlluminationFlags &=
					~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
			}
		}
	}

	void OpaquePreset () {
		if (PresetButton("Opaque")) {
			Clipping = false;
			Shadows = ShadowMode.On;
			PremultiplyAlpha = false;
			SrcBlend = BlendMode.One;
			DstBlend = BlendMode.Zero;
			ZWrite = true;
			RenderQueue = RenderQueue.Geometry;
		}
	}

	void TransparentPreset () {
		if (PresetButton("Transparent")) {
			Clipping = false;
			Shadows = ShadowMode.On;
			PremultiplyAlpha = true;
			SrcBlend = BlendMode.One;
			DstBlend = BlendMode.OneMinusSrcAlpha;
			ZWrite = false;
			RenderQueue = RenderQueue.Transparent;
		}
	}

	bool PresetButton (string name) {
		if (GUILayout.Button(name)) {
			editor.RegisterPropertyChangeUndo(name);
			return true;
		}
		return false;
	}

	bool HasProperty (string name) =>
		FindProperty(name, properties, false) != null;

	void SetProperty (string name, string keyword, bool value) {
		if (SetProperty(name, value ? 1f : 0f)) {
			SetKeyword(keyword, value);
		}
	}

	bool SetProperty (string name, float value) {
		MaterialProperty property = FindProperty(name, properties, false);
		if (property != null) {
			property.floatValue = value;
			return true;
		}
		return false;
	}

	void SetKeyword (string keyword, bool enabled) {
		if (enabled) {
			foreach (Material m in materials) {
				m.EnableKeyword(keyword);
			}
		}
		else {
			foreach (Material m in materials) {
				m.DisableKeyword(keyword);
			}
		}
	}

	void SetShadowCasterPass () {
		MaterialProperty shadows = FindProperty("_Shadows", properties, false);
		if (shadows == null || shadows.hasMixedValue) {
			return;
		}
		bool enabled = shadows.floatValue < (float)ShadowMode.Off;
		foreach (Material m in materials) {
			m.SetShaderPassEnabled("ShadowCaster", enabled);
		}
	}
}