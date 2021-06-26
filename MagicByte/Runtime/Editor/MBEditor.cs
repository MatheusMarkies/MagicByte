using UnityEngine;
using UnityEditor;

public class MBEditor
{

    static string[] magicByteShaders = new string[] { "Magic Byte/Magic Byte Lit",
        "Magic Byte/Crystal",
        "Magic Byte/Vertex Paint",
        "Magic Byte/Metallic",
        "Magic Byte/Water",
        "Magic Byte/Iridescence",
        "Magic Byte/Hair",
        "Magic Byte/Mesh Grass",
        "Magic Byte/Eye",
        "Magic Byte/Fur",
        "Magic Byte/Cloth",
        "Magic Byte/Grass",
        "Magic Byte/Mesh Grass",
        "Magic Byte/SurfaceScattering",
        "Magic Byte/Unlit",
        "Magic Byte/Rainy Surface"};

    [MenuItem("Magic Byte/Convert to Magic Byte Shaders")]
    private static void Convert2MagicByteShaders()
    {
        GameObject[] gb = UnityEngine.SceneManagement.SceneManager.GetActiveScene().GetRootGameObjects();
        foreach (GameObject i in gb)
        {
            Material material = null;
            if (i.TryGetComponent(out Renderer render))
            {
         
                int have = 0;
                for (int o = 0; o < magicByteShaders.Length; o++)
                {
                    if (render.material.shader == Shader.Find(magicByteShaders[o]))
                    have++;
                }
                    if (have == 0)
                    {
                        render.material = new Material(Shader.Find("Magic Byte/BSSRDF"));

                    }

                    int children = i.transform.childCount;
                    for (int o = 0; o < children; o++)
                    {
                        int haveChild = 0;
                        if (i.transform.GetChild(o).TryGetComponent(out Renderer renderChild))
                        {
                            for (int u = 0; u < magicByteShaders.Length; u++)
                            if (renderChild.material.shader == Shader.Find(magicByteShaders[u]))
                            haveChild++;

                            if (haveChild == 0)
                            {

                                renderChild.material = new Material(Shader.Find("Magic Byte/BSSRDF"));

                            }

                        }
                    

               }
            }
        }
    }

}
