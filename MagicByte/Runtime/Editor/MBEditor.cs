using UnityEngine;
using UnityEditor;
using System.Collections;

public class MBEditor : MonoBehaviour
{
    public static string[] MagicByteShaders = new string[] { "Magic Byte/Magic Byte Lit",
        "Magic Byte/Unlit",
        "Magic Byte/BSDF"};

    static ConvertShadersInstance convertShadersInstance = new ConvertShadersInstance();

    [MenuItem("Magic Byte/Convert to Magic Byte Shaders")]
    private static void ConvertToMagicByteShaders()
    {
        GameObject manager = new GameObject();
        convertShadersInstance = manager.AddComponent<ConvertShadersInstance>();
        convertShadersInstance.StartCoroutine(ConvertShadersInstance.ConvertShaders());
        manager.name = "Manager";

        DestroyImmediate(manager);
    }

}

public class ConvertShadersInstance : MonoBehaviour{
    public static IEnumerator ConvertShaders()
    {
        GameObject[] gb = UnityEngine.SceneManagement.SceneManager.GetActiveScene().GetRootGameObjects();
        foreach (GameObject i in gb)
        {
            Material material = null;
            if (i.TryGetComponent(out Renderer render))
            {

                int have = 0;
                for (int o = 0; o < MBEditor.MagicByteShaders.Length; o++)
                {
                    if (render.material.shader == Shader.Find(MBEditor.MagicByteShaders[o]))
                        have++;
                }
                if (have == 0)
                {
                    render.material = new Material(Shader.Find("Magic Byte/BSDF"));

                }

                int children = i.transform.childCount;
                for (int o = 0; o < children; o++)
                {
                    int haveChild = 0;
                    if (i.transform.GetChild(o).TryGetComponent(out Renderer renderChild))
                    {
                        for (int u = 0; u < MBEditor.MagicByteShaders.Length; u++)
                            if (renderChild.material.shader == Shader.Find(MBEditor.MagicByteShaders[u]))
                                haveChild++;

                        if (haveChild == 0)
                        {

                            renderChild.material = new Material(Shader.Find("Magic Byte/BSDF"));

                        }

                    }


                }
            }
        }
        yield return null;
    }

}
