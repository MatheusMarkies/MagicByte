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

        [Space(5)]
        public bool LensFlare;
        [SerializeField]
        LensFlare lensflare = new LensFlare();

        [Space(5)]
        public bool ChromaticAberration;
        [SerializeField]
        ChromaticAberration chromaticAberration = new ChromaticAberration();

        [Space(5)]
        [HideInInspector]
        public bool LightStreak;
        [SerializeField, HideInInspector]
        LightStreak lightStreak = new LightStreak();

        [Space(5)]
        public bool Bloom;
        [SerializeField]
        Bloom bloom = new Bloom();

        List<Effect> effects = new List<Effect>();
        public void OnRenderCamera()
        {
            clearList();
            //for (int i = 0; i < getMaxQueuePosition(); i++)
            //{
            //    if (Tonemapping && tonemapping.getQueuePosition() == i)
            //    {
            //        effects.Add(tonemapping);
            //        tonemapping.preProcessing();
            //    }
            //    if (Bloom && bloom.getQueuePosition() == i)
            //    {
            //        effects.Add(bloom);
            //        bloom.preProcessing();
            //    }
            //    if (LensFlare && lensflare.getQueuePosition() == i)
            //    {
            //        effects.Add(lensflare);
            //        lensflare.preProcessing();
            //    }
            //    if (ChromaticAberration && chromaticAberration.getQueuePosition() == i)
            //    {
            //        effects.Add(chromaticAberration);
            //        chromaticAberration.preProcessing();
            //    }
            //    if (LightStreak && lightStreak.getQueuePosition() == i)
            //    {
            //        effects.Add(lightStreak);
            //        lightStreak.preProcessing();
            //    }
            //}
            if (Tonemapping)
            {
                effects.Add(tonemapping);
                tonemapping.preProcessing();
            }
            if (LensFlare)
            {
                effects.Add(lensflare);
                lensflare.preProcessing();
            }
            if (Bloom)
            {
                effects.Add(bloom);
                bloom.preProcessing();
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
        public int getMaxQueuePosition()
        {
            int max = 0;
            if (tonemapping.getQueuePosition() > max)
                max = tonemapping.getQueuePosition();
            if (bloom.getQueuePosition() > max)
                max = tonemapping.getQueuePosition();
            if (lensflare.getQueuePosition() > max)
                max = tonemapping.getQueuePosition();
            if (chromaticAberration.getQueuePosition() > max)
                max = tonemapping.getQueuePosition();
            return max;
        }
        public void clearList()
        {
            effects = new List<Effect>();
        }
        public List<Effect> getEffects() { return effects; }
    }
}