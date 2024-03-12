using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MagicByte
{
    [ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
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
        RenderTexture RT;
        public void OnRenderCamera()
        {
            clearList();
            if (PathTracing)
            {
                RT = pathTracing.preProcessing();
                Tonemapping = false;
                LensFlare = false;
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
        }
        public List<Effect> getEffects() { return effects; }
        public RenderTexture getRenderTexture() { return RT; }
    }
}