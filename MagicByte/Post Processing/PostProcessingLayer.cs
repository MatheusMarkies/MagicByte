using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MagicByte
{
    [ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
    public class PostProcessingLayer : MonoBehaviour
    {
        public bool Tonemapping;
        [SerializeField]
        Tonemapping tonemapping = new Tonemapping();

        public bool LensFlare;
        [SerializeField]
        LensFlare lensflare = new LensFlare();

        public bool ChromaticAberration;
        [SerializeField]
        ChromaticAberration chromaticAberration = new ChromaticAberration();
        
        [HideInInspector]
        public bool LightStreak;
        [SerializeField, HideInInspector]
        LightStreak lightStreak = new LightStreak();

        public bool Bloom;
        [SerializeField]
        Bloom bloom = new Bloom();

        List<Effect> effects = new List<Effect>();
        public void OnRenderCamera()
        {
            clearList();
            if (Tonemapping)
            {
                effects.Add(tonemapping);
                tonemapping.preProcessing();
            }
            if (Bloom)
            {
                effects.Add(bloom);
                bloom.preProcessing();
            }
            if (LensFlare)
            {
                effects.Add(lensflare);
                lensflare.preProcessing();
            }
            if (ChromaticAberration)
            {
                effects.Add(chromaticAberration);
                chromaticAberration.preProcessing();
            }
            if (LightStreak)
            {
                effects.Add(lightStreak);
                lightStreak.preProcessing();
            }
        }
        public void clearList()
        {
            effects = new List<Effect>();
        }
        public List<Effect> getEffects() { return effects; }
    }
}