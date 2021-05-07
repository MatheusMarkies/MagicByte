using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class VectorUtil
{
    public static Vector3 add(this Vector3 vec, float x)
    {
        return new Vector3(vec.x + x, vec.y + x, vec.z + x);
    }
    public static Vector3 add(this Vector3 vec, Vector3 x)
    {
        return new Vector3(vec.x + x.x, vec.y + x.y, vec.z + x.z);
    }
    public static Vector3 remove(this Vector3 vec, float x)
    {
        return new Vector3(vec.x - x, vec.y - x, vec.z - x);
    }
    public static Vector3 remove(this Vector3 vec, Vector3 x)
    {
        return new Vector3(vec.x - x.x, vec.y - x.y, vec.z - x.z);
    }
    public static Vector3 setX(this Vector3 vec, float x)
    {
        return new Vector3(x, vec.y, vec.z);
    }
    public static Vector3 setY(this Vector3 vec, float y)
    {
        return new Vector3(vec.x, y, vec.z);
    }
    public static Vector3 setZ(this Vector3 vec, float z)
    {
        return new Vector3(vec.x, vec.y, z);
    }
    public static Vector3 addX(this Vector3 vec, float x)
    {
        return new Vector3(vec.x + x, vec.y, vec.z);
    }
    public static Vector3 addY(this Vector3 vec, float y)
    {
        return new Vector3(vec.x, vec.y + y, vec.z);
    }
    public static Vector3 addZ(this Vector3 vec, float z)
    {
        return new Vector3(vec.x, vec.y, vec.z + z);
    }
    public static Vector3 removeX(this Vector3 vec, float x)
    {
        return new Vector3(vec.x - x, vec.y, vec.z);
    }
    public static Vector3 removeY(this Vector3 vec, float y)
    {
        return new Vector3(vec.x, vec.y - y, vec.z);
    }
    public static Vector3 removeZ(this Vector3 vec, float z)
    {
        return new Vector3(vec.x, vec.y, vec.z - z);
    }
    public static Vector3 multiply(this Vector3 vec, float x, float y, float z)
    {
        return new Vector3(vec.x * x, vec.y * y, vec.z * z);
    }
    public static Vector3 multiply(this Vector3 vec, Vector3 other)
    {
        return multiply(vec, other.x, other.y, other.z);
    }
    public static Vector3 clampVector3(this Vector3 vec, Vector3 min, Vector3 max)
    {
        vec.x = Mathf.Clamp(vec.x, min.x, max.x);
        vec.y = Mathf.Clamp(vec.y, min.y, max.y);
        vec.z = Mathf.Clamp(vec.z, min.z, max.z);

        return vec;
    }
    public static Vector3 absVector(this Vector3 vec)
    {
        return new Vector3(Mathf.Abs(vec.x), Mathf.Abs(vec.y), Mathf.Abs(vec.z));
    }
    public static Vector3 arithmeticAverage(this Vector3 vec, Vector3 other)
    {
        float x = (vec.x + other.x) / 2;
        float y = (vec.y + other.y) / 2;
        float z = (vec.z + other.z) / 2;

        return new Vector3(x, y, z);
    }
}
