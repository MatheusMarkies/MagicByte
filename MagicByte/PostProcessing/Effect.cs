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

            this.passes = 2;

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
        [SerializeField]
        private float Threshold = 1;
        public override void preProcessing()
        {
            this.passes = 1;

            Shader shader = Shader.Find("Hidden/ScreenSpaceLensFlare");
            if (shader != null)
            {
                Material material = new Material(shader);

                material.SetFloat("_Threshold", Threshold);

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

                postProcessingStack.drawingEffect(fromID, ToID, this.effectMaterial, 0, camera);
                postProcessingStack.drawingEffect(fromID, ToID + 1, this.effectMaterial, 1, camera);

                ToID = ToID + 1;
            }
            else
                Debug.LogError("Impossible to render the effect (LensFlare)");
            buffer.EndSample("LensFlare");
        }
    }

}