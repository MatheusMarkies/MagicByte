using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MagicByte
{
    [ImageEffectAllowedInSceneView, ExecuteInEditMode, RequireComponent(typeof(Camera))]
    public class PostProcessingLayer : MonoBehaviour
    {

        public bool PathTracing;
        [SerializeField]
        PathTracing pathTracing = new PathTracing();

        public bool Tonemapping;
        [SerializeField]
        Tonemapping tonemapping = new Tonemapping();

        public bool LensFlare;
        [SerializeField]
        LensFlare lensflare = new LensFlare();

        List<Effect> effects = new List<Effect>();
        List<RenderTexture> RTs = new List<RenderTexture>();
        public void OnRenderCamera()
        {
            clearList();
            if (PathTracing)
            {
                RTs.Add(pathTracing.preProcessing());
            }
            if (LensFlare)
            {
                effects.Add(lensflare);
                lensflare.preProcessing();
            }
            if (Tonemapping)
            {
                effects.Add(tonemapping);
                tonemapping.preProcessing();
            }
        }
        public void clearList()
        {
            effects = new List<Effect>();
            RTs = new List<RenderTexture>();
        }
        public List<Effect> getEffects() { return effects; }
        public List<RenderTexture> getRenderTextures() { return RTs; }
    }
}