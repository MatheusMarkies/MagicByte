using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode, RequireComponent(typeof(Camera)), ImageEffectAllowedInSceneView]
public class PostProcessingCamera : MonoBehaviour
{
    public bool ConsoleDebug;
    PostProcessingStack postStack;
    [SerializeField]
    bool Bloom, LensFlare, Tonemapping, RaymarchingEffects;
    List<EffectObject> EffectMaterials = new List<EffectObject>();
    [SerializeField,Range(2,8)]
    int bloomLevels = 16;

    public void OnRenderCamera()
    {
    resetMaterialList();
        if (this.Bloom)
    //for(int i = 0;i<bloomLevels;i++)
    addMaterial(PreLoadBloom(), bloomLevels, "Bloom");
        if (this.LensFlare)
    addMaterial(PreLoadLensFlare(), 2, "LensFlare");
        if (this.Tonemapping)
    addMaterial(PreLoadTonemmaping(),1, "Tonemapping");
        if(this.RaymarchingEffects)
    addMaterial(PreLoadRaymarching(), 1, "Raymarching");

        if (!Tonemapping && !Bloom && !LensFlare && !RaymarchingEffects)
    addMaterial(new Material(Shader.Find("Hidden/Standard")),1,"Standard");
    }

    public void addMaterial(Material material, int passNumber,string EffectName)
    {
        EffectObject effect = null;
        if (EffectName == "Standard")
            effect = new StandardClass();
        if (EffectName == "Bloom")
        {
            effect = new BloomClass();
            //effect.maxStackEffect = bloomLevels;
        }
        if (EffectName == "LensFlare")
            effect = new LensFlareClass();
        if (EffectName == "Tonemapping")
            effect = new ToneMappingClass();
        if (EffectName == "Raymarching")
            effect = new RaymarchingClass();
        effect.material = material;
        effect.passNumber = passNumber;
        this.EffectMaterials.Add(effect);
    }

    public List<EffectObject> getMaterialList()
    {
        return EffectMaterials;
    }
    public void resetMaterialList()
    {
        EffectMaterials = new List<EffectObject>();
    }

    public PostProcessingStack getPPS() { return postStack; }
    public void setPPS(PostProcessingStack pps) { this.postStack = pps; }

    public enum TonemappingTone
    {
        linear,
        simpleReinhardCurve,
        lumaBasedReinhardCurve,
        Photographic,
        whitePreservingLuma,
        filmic,
        ACES,
        Gray
    }
    public enum Precision
    {
        Low,
        High
    }

    //[SerializeField]
    //private Precision precision;
    [SerializeField]
    private TonemappingTone toneMode;

    [Range(0, 5), SerializeField]
    private float Saturation = 1;
    [Range(-1f, 1), SerializeField]
    private float Vibrance = 1;
    [Range(-0.5f, 0.5f), SerializeField]
    private float HUE = 0;
    [Range(0.01f, 5f), SerializeField]
    private float Exposure = 1;
    [Range(0f, 2f), SerializeField]
    private float Contrast = 1;
    [Range(0f, 3f), SerializeField]
    private float Gamma = 1;
    [Range(-2f, 2f), SerializeField]
    private float Temperature = 0;
    [Range(-2f, 2f), SerializeField]
    private float Tint = 0;
    [Range(.1f,10f), SerializeField]
    private float RedMultiply = 1, GreenMultiply = 1, BlueMultiply = 1;

    Shader shader;

    private float StandardIlluminantY(float x)
    {
        return 2.87f * x - 3f * x * x - 0.27509507f;
    }

    // CIE xy chromaticity to CAT02 LMS.
    // http://en.wikipedia.org/wiki/LMS_color_space#CAT02
    private Vector3 CIExyToLMS(float x, float y)
    {
        float Y = 1f;
        float X = Y * x / y;
        float Z = Y * (1f - x - y) / y;

        float L = 0.7328f * X + 0.4296f * Y - 0.1624f * Z;
        float M = -0.7036f * X + 1.6975f * Y + 0.0061f * Z;
        float S = 0.0030f * X + 0.0136f * Y + 0.9834f * Z;

        return new Vector3(L, M, S);
    }

    private Vector3 GetWhiteBalance()
    {
        float t1 = Temperature;
        float t2 = Tint;

        float x = 0.31271f - t1 * (t1 < 0f ? 0.1f : 0.05f);
        float y = StandardIlluminantY(x) + t2 * 0.05f;

        Vector3 w1 = new Vector3(0.949237f, 1.03542f, 1.08728f);
        Vector3 w2 = CIExyToLMS(x, y);
        return new Vector3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);
    }
    private Material PreLoadTonemmaping()
    {

        shader = Shader.Find("Hidden/TonemappingShader");
        if (shader != null)
        {
            Material material = new Material(shader);

            material.SetVector("_HSV", new Vector3(HUE, Saturation, Vibrance));
            material.SetFloat("_Exposure", Exposure);
            material.SetFloat("_Gamma", Gamma);
            material.SetVector("_WhiteBalance", GetWhiteBalance());
            material.SetFloat("_Contrast", Contrast);

            material.SetFloat("_RedMultiply", RedMultiply);
            material.SetFloat("_GreenMultiply", GreenMultiply);
            material.SetFloat("_BlueMultiply", BlueMultiply);

            switch (toneMode)
            {
                case TonemappingTone.linear:
                    material.SetInt("_Tone", 1);
                    break;
                case TonemappingTone.simpleReinhardCurve:
                    material.SetInt("_Tone", 2);
                    break;
                case TonemappingTone.lumaBasedReinhardCurve:
                    material.SetInt("_Tone", 3);
                    break;
                case TonemappingTone.Photographic:
                    material.SetInt("_Tone", 4);
                    break;
                case TonemappingTone.whitePreservingLuma:
                    material.SetInt("_Tone", 5);
                    break;
                case TonemappingTone.filmic:
                    material.SetInt("_Tone", 6);
                    break;
                case TonemappingTone.ACES:
                    material.SetInt("_Tone", 7);
                    break;
                case TonemappingTone.Gray:
                    material.SetInt("_Tone", 8);
                    break;
            }

            return material;
        }
        return null;
    }

    public float getSaturation() { return this.Saturation; }
    public float getVibrance() { return this.Vibrance; }
    public float getHUE() { return this.HUE; }
    public float getExposure() { return this.Exposure; }
    public float getContrast() { return this.Contrast; }
    public float getGamma() { return this.Gamma; }
    public float getTemperature() { return this.Temperature; }
    public float getTint() { return this.Tint; }

    public void setSaturation(float Saturation) { this.Saturation = Saturation; }
    public void setVibrance(float Vibrance) { this.Vibrance = Vibrance; }
    public void setHUE(float HUE) { this.HUE = HUE; }
    public void setExposure(float Exposure) { this.Exposure = Exposure; }
    public void setContrast(float Contrast) { this.Contrast = Contrast; }
    public void setGamma(float Gamma) { this.Gamma = Gamma; }
    public void setTemperature(float Temperature) { this.Temperature = Temperature; }
    public void setTint(float Tint) { this.Tint = Tint; }

    public TonemappingTone getToneMode() { return this.toneMode; }
    public void setToneMode(TonemappingTone toneMode) { this.toneMode = toneMode; }

    [Range(0.01f, 10f), SerializeField]
    private float Threshold = 0.05f;

    private Material PreLoadLensFlare()
    {

        shader = Shader.Find("Hidden/ScreenSpaceLensFlare");
        if (shader != null)
        {
            Material material = new Material(shader);

            material.SetFloat("_Threshold", Threshold);

            return material;
        }
        return null;
    }
    [SerializeField]
    float bloomThreshold;
    private Material PreLoadBloom()
    {

        shader = Shader.Find("Hidden/Bloom");
        if (shader != null)
        {
            Material material = new Material(shader);

            Vector4 threshold = new Vector4();

            //threshold.x = Mathf.GammaToLinearSpace(bloomThreshold);
            //threshold.y = threshold.x * 0.5f;
            //threshold.z = 2f * threshold.y;
            //threshold.w = 0.25f / (threshold.y + 0.00001f);
            //threshold.y -= threshold.x;

            //material.SetVector("_Threshold", threshold);
            return material;
        }
        return null;
    }

    private Material PreLoadRaymarching()
    {

        shader = Shader.Find("Hidden/Raymarching");
        if (shader != null)
        {
            Material material = new Material(shader);

            float fov = Mathf.Tan(gameObject.GetComponent<Camera>().fieldOfView * 0.5f * Mathf.Deg2Rad);

            Vector3 UpAspect = Vector3.up * fov;
            Vector3 SideAspect = Vector3.right * fov * gameObject.GetComponent<Camera>().aspect;

            Matrix4x4 Corners = Matrix4x4.identity;

            Corners.SetRow(0, -Vector3.forward - SideAspect + UpAspect);
            Corners.SetRow(1, -Vector3.forward + SideAspect + UpAspect);
            Corners.SetRow(2, -Vector3.forward + SideAspect - UpAspect);
            Corners.SetRow(3, -Vector3.forward - SideAspect - UpAspect);

            material.SetMatrix("CameraCorners", Corners);
            material.SetMatrix("CameraToWorld", gameObject.GetComponent<Camera>().cameraToWorldMatrix);
            material.SetVector("CameraPosition", gameObject.GetComponent<Camera>().transform.position);

            return material;
        }
        return null;
    }

}
