using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public abstract class EffectObject
{
    public Material material;
    public int passNumber;
    public int toID;
    public int fromID;
    public PostProcessingStack postProcessingStack;
    public int maxStackEffect;

    public int ID;
    public int staticID;

    public abstract void OnStackedEffect(int src, int dst, Material material, Camera camera, CommandBuffer buffer);
    public abstract void OnRelease(CommandBuffer buffer,Material material);
    public abstract void OnExecuteBuffer(int src, int dst, Material material, Camera camera, CommandBuffer buffer);


}