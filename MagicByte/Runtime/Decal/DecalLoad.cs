using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[RequireComponent(typeof(Camera))]
public class DecalLoad : MonoBehaviour
{
    public List<Decal> Decals = new List<Decal>();
    public List<Decal> getDecalList()
    {
        return Decals;
    }
}
