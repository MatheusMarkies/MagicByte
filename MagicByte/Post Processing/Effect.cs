using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace MagicByte
{
    public abstract class Effect
    {
        [HideInInspector]
        public Material effectMaterial;
        [HideInInspector]
        public int passes;
        [HideInInspector]
        public int ToID;
        public abstract void preProcessing();
        public abstract void renderPasses(PostProcessingStack postProcessingStack, CommandBuffer buffer, int fromID, int toID, Camera camera);

    }
    [System.Serializable]
    class Tonemapping : Effect
    {
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
        [Range(.1f, 10f), SerializeField]
        private float RedMultiply = 1, GreenMultiply = 1, BlueMultiply = 1;

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

        public override void preProcessing()
        {
            this.passes = 1;

            Shader shader = Shader.Find("Hidden/TonemappingShader");
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
                this.effectMaterial = material;
            }
            else
                Debug.LogError("It was not possible to create the effect material");
        }

        public override void renderPasses(PostProcessingStack postProcessingStack, CommandBuffer buffer, int fromID, int toID, Camera camera)
        {
            buffer.BeginSample("ToneMapping");

            //this.toID = Shader.PropertyToID("_Tonemapping");
            if (this.effectMaterial)
            {
                postProcessingStack.drawingEffect(fromID, toID, this.effectMaterial, 0, camera);

                ToID = toID;
            }
            else
                Debug.LogError("Impossible to render the effect (Tonemapping)");
            buffer.EndSample("ToneMapping");
        }
    }

    [System.Serializable]
    class LensFlare : Effect
    {
        [SerializeField, Range(0, 8)]
        private float Threshold = 0.17f;
        [SerializeField, Range(0, 6)]
        private float GhostIntensity = 1;
        [SerializeField, Min(0.0f)]
        public float HaloIntensity = 1.0f;
        [SerializeField, Range(0f, 1f)]
        public float DirtyIntensity = 1.0f;
        [SerializeField, Range(-1f, 1f)]
        public float HaloWidth = 0.5f;
        [SerializeField, Min(0.0f)]
        public float Delta = 1.0f;

        [SerializeField, Min(0.0f)]
        public float Distortion = 1.0f;

        [SerializeField]
        public Texture StarBrush;

        [SerializeField]
        public Texture LensDirty;

        public override void preProcessing()
        {
            this.passes = 7;

            Shader shader = Shader.Find("Hidden/ScreenSpaceLensFlare");
            if (shader != null)
            {
                Material material = new Material(shader);

                material.SetFloat("_Bias", Threshold * 10);
                material.SetFloat("_GhostIntensity", GhostIntensity);
                material.SetFloat("_HaloIntensity", HaloIntensity);
                material.SetFloat("_DirtyIntensity", DirtyIntensity);
                material.SetFloat("_DirtyOffset", 1);
                material.SetFloat("_HaloWidth", HaloWidth);
                material.SetFloat("_Delta", Delta);

                material.SetFloat("_Distortion", Distortion);

                material.SetTexture("_StarBrush", StarBrush);
                material.SetTexture("_LensDirty", LensDirty);

                this.effectMaterial = material;
            }
            else
                Debug.LogError("It was not possible to create the effect material");

        }
        public override void renderPasses(PostProcessingStack postProcessingStack, CommandBuffer buffer, int fromID, int toID, Camera camera)
        {
            buffer.BeginSample("LensFlare");

            if (this.effectMaterial)
            {
                buffer.SetGlobalTexture("_OldPostFXSource", fromID);
                postProcessingStack.drawingEffect(fromID, toID, this.effectMaterial, 0, camera);

                buffer.GetTemporaryRT(toID + 1, camera.pixelWidth / 1, camera.pixelHeight / 1, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                postProcessingStack.drawingEffect(toID, toID + 1, this.effectMaterial, 4, camera);

                buffer.GetTemporaryRT(toID + 2, camera.pixelWidth / 1, camera.pixelHeight / 1, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                buffer.SetGlobalTexture("_RadialFXSource", toID + 1);
                postProcessingStack.drawingEffect(toID, toID + 2, this.effectMaterial, 5, camera);

                buffer.GetTemporaryRT(toID + 3, camera.pixelWidth / 1, camera.pixelHeight / 1, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                postProcessingStack.drawingEffect(toID + 2, toID + 3, this.effectMaterial, 1, camera);

                buffer.GetTemporaryRT(toID + 4, camera.pixelWidth / 1, camera.pixelHeight / 1, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                postProcessingStack.drawingEffect(toID + 3, toID + 4, this.effectMaterial, 2, camera);

                buffer.GetTemporaryRT(toID + 5, camera.pixelWidth / 1, camera.pixelHeight / 1, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                postProcessingStack.drawingEffect(toID + 4, toID + 5, this.effectMaterial, 3, camera);

                buffer.GetTemporaryRT(toID + 6, camera.pixelWidth / 1, camera.pixelHeight / 1, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                postProcessingStack.drawingEffect(toID + 5, toID + 6, this.effectMaterial, 6, camera);


                ToID = toID + 6;
            }
            else
                Debug.LogError("Impossible to render the effect (LensFlare)");
            buffer.EndSample("LensFlare");
        }
    }

    [System.Serializable]
    class ChromaticAberration : Effect
    {
        [SerializeField, Range(0, 10)]
        private float Distortion = 0.1f;

        public override void preProcessing()
        {
            this.passes = 1;

            Shader shader = Shader.Find("Hidden/ChromaticAberration");
            if (shader != null)
            {
                Material material = new Material(shader);

                material.SetFloat("_Distortion", Distortion * 2);

                this.effectMaterial = material;
            }
            else
                Debug.LogError("It was not possible to create the effect material");

        }
        public override void renderPasses(PostProcessingStack postProcessingStack, CommandBuffer buffer, int fromID, int toID, Camera camera)
        {
            buffer.BeginSample("ChromaticAberration");

            if (this.effectMaterial)
            {
                postProcessingStack.drawingEffect(fromID, toID, this.effectMaterial, 0, camera);

                ToID = toID;
            }
            else
                Debug.LogError("Impossible to render the effect (ChromaticAberration)");
            buffer.EndSample("ChromaticAberration");
        }
    }

    [System.Serializable]
    class LightStreak : Effect
    {
        [SerializeField]
        float Attenuation;
        [SerializeField]
        Vector4 Direction;
        [SerializeField]
        float Offset;

        public override void preProcessing()
        {
            this.passes = 1;

            Shader shader = Shader.Find("Hidden/LightStreak");
            if (shader != null)
            {
                Material material = new Material(shader);

                material.SetFloat("_Attenuation", Attenuation);
                material.SetFloat("_Offset", Offset);
                material.SetVector("_Direction", Direction);

                this.effectMaterial = material;
            }
            else
                Debug.LogError("It was not possible to create the effect material");

        }
        public override void renderPasses(PostProcessingStack postProcessingStack, CommandBuffer buffer, int fromID, int toID, Camera camera)
        {
            buffer.BeginSample("LightStreak");

            if (this.effectMaterial)
            {
                postProcessingStack.drawingEffect(fromID, toID, this.effectMaterial, 0, camera);

                ToID = toID;
            }
            else
                Debug.LogError("Impossible to render the effect (LightStreak)");
            buffer.EndSample("LightStreak");
        }
    }

    [System.Serializable]
    class Bloom : Effect
    {
        [SerializeField, Range(2,16)]
        int Levels = 16;
        [Min(0f)]
        public float Threshold;
        [Range(0f, 1f)]
        public float ThresholdKnee;
        [Min(0.1f)]
        public float Intensity;
        [Range(0f, 1f)]
        public float Scattering;

        public override void preProcessing()
        {
            this.passes = 1;

            Shader shader = Shader.Find("Hidden/Bloom");
            if (shader != null)
            {
                Material material = new Material(shader);

                material.SetInt("_Levels", Levels);
                Vector4 threshold = new Vector4();
                threshold.x = Mathf.GammaToLinearSpace(Threshold);
                threshold.y = threshold.x * ThresholdKnee;
                threshold.z = 2f * threshold.y;
                threshold.w = 0.25f / (threshold.y + 0.00001f);
                threshold.y -= threshold.x;
                material.SetVector("_BloomThreshold", threshold);
                
                material.SetFloat("_BloomIntensity", Intensity);
                material.SetFloat("_BloomScattering", Scattering);

                this.effectMaterial = material;
            }
            else
                Debug.LogError("It was not possible to create the effect material");

        }
        int bloomID = Shader.PropertyToID("_Bloom0");
        public override void renderPasses(PostProcessingStack postProcessingStack, CommandBuffer buffer, int fromID, int toID, Camera camera)
        {
            buffer.BeginSample("Bloom");

            bloomID = Shader.PropertyToID("_Bloom0");

            if (this.effectMaterial)
            {
                int width = camera.pixelWidth, height = camera.pixelHeight;
                buffer.SetGlobalTexture("_OldPostFXSource", fromID);

                int forID = fromID;
                int i = 0;

                for (i = 0; i <= Levels;)
                {
                    int PreFilterId = Shader.PropertyToID("_Bloom" + i);
                    buffer.GetTemporaryRT(PreFilterId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                    postProcessingStack.drawingEffect(fromID, PreFilterId, this.effectMaterial, 0, camera);

                    int SampleBoxId = Shader.PropertyToID("_Bloom" + (i + 1));
                    buffer.GetTemporaryRT(SampleBoxId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                    postProcessingStack.drawingEffect(PreFilterId, SampleBoxId, this.effectMaterial, 1, camera);

                    int HBlurId = Shader.PropertyToID("_Bloom" + (i + 2));
                    buffer.GetTemporaryRT(HBlurId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                    postProcessingStack.drawingEffect(SampleBoxId, HBlurId, this.effectMaterial, 2, camera);

                    int VBlurId = Shader.PropertyToID("_Bloom" + (i + 3));
                    buffer.GetTemporaryRT(VBlurId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                    postProcessingStack.drawingEffect(HBlurId, VBlurId, this.effectMaterial, 3, camera);

                    if (i>0) {
                        int AddtiveId = Shader.PropertyToID("_Bloom" + (i + 4));
                        buffer.GetTemporaryRT(AddtiveId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                        postProcessingStack.drawingEffect(VBlurId, AddtiveId, this.effectMaterial, 4, camera);

                        buffer.SetGlobalTexture("_OldBloomSource", AddtiveId);
                        forID = AddtiveId;
                        i += 5;
                    }
                    else
                    {
                        buffer.SetGlobalTexture("_OldBloomSource", VBlurId);
                        forID = VBlurId;
                        i += 4;
                    }

                    width = (int)Mathf.Ceil(width / 2f);
                    height = (int)Mathf.Ceil(height / 2f); ;

                    if (height <= 1 || width <= 1)
                    {
                        break;
                    }
                }

                buffer.GetTemporaryRT(toID, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
                postProcessingStack.drawingEffect(forID, toID, this.effectMaterial, 5, camera);

                ToID = toID;
            }
            else
                Debug.LogError("Impossible to render the effect (Bloom)");
            buffer.EndSample("Bloom");
        }
    }

}