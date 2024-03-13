using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.PlayerLoop;
using UnityEngine.Rendering;
[ExecuteInEditMode]
public class Decal : MonoBehaviour
{

	//CommandBuffer buffer = new CommandBuffer() { name = "Decal" };
	public enum _Type
    {
		Normal,
		Diffuse,
	    Dual
    }
    List<Vector3> Bound;
    public Camera camera;
    public _Type type;
	public Material material;

    public void PreLoadDecal(Camera camera)
	{

		//if (material != null && camera != null)
		//{

  //          var normalsID = Shader.PropertyToID("_NormalsCopy");
		//	buffer.GetTemporaryRT(normalsID, -1, -1);

		//	buffer.Blit(BuiltinRenderTextureType.GBuffer2, normalsID);

  //          if (type == _Type.Diffuse)
  //          {
  //              buffer.SetRenderTarget(BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.CameraTarget);
  //          }
  //          if (type == _Type.Normal)
  //          {
  //              buffer.SetRenderTarget(BuiltinRenderTextureType.GBuffer2, BuiltinRenderTextureType.CameraTarget);
  //          }

  //          if (type == _Type.Dual)
  //          {
  //              RenderTargetIdentifier[] RenderId = { BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.GBuffer2 };
  //              buffer.SetRenderTarget(RenderId, BuiltinRenderTextureType.CameraTarget);
  //          }

  //          buffer.ReleaseTemporaryRT(normalsID);

  //      }
	}

    public void OnRederDecal(ScriptableRenderContext context)
    {
        int normalsID = Shader.PropertyToID("_NormalsCopy");
        //buffer.GetTemporaryRT(normalsID, -1, -1);

        //buffer.Blit(BuiltinRenderTextureType.GBuffer2, normalsID);

        if (type == _Type.Diffuse)
        {
            //buffer.SetRenderTarget(BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.CameraTarget);
        }
        if (type == _Type.Normal)
        {
            //buffer.SetRenderTarget(BuiltinRenderTextureType.GBuffer2, BuiltinRenderTextureType.CameraTarget);
        }

        if (type == _Type.Dual)
        {
            RenderTargetIdentifier[] RenderId = { BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.GBuffer2 };
            //buffer.SetRenderTarget(RenderId, BuiltinRenderTextureType.CameraTarget);
        }

        //buffer.ReleaseTemporaryRT(normalsID);
        //context.ExecuteCommandBuffer(buffer);
        //buffer.Clear();
    }

    void OnDrawGizmos()
    {
        if (type == _Type.Diffuse)
            Gizmos.color = Color.blue;
        if (type == _Type.Normal)
            Gizmos.color = Color.green;
        if (type == _Type.Dual)
            Gizmos.color = Color.red;

        Bound = new List<Vector3>();
        Bound.Add(new Vector3(transform.localPosition.x + (transform.localScale.x / 2), transform.localPosition.y - (transform.localScale.y / 2), transform.localPosition.z + (transform.localScale.z / 2)));
        Bound.Add(new Vector3(transform.localPosition.x + (transform.localScale.x / 2), transform.localPosition.y - (transform.localScale.y / 2), transform.localPosition.z - (transform.localScale.z / 2)));
        Bound.Add(new Vector3(transform.localPosition.x - (transform.localScale.x / 2), transform.localPosition.y - (transform.localScale.y / 2), transform.localPosition.z + (transform.localScale.z / 2)));
        Bound.Add(new Vector3(transform.localPosition.x - (transform.localScale.x / 2), transform.localPosition.y - (transform.localScale.y / 2), transform.localPosition.z - (transform.localScale.z / 2)));

        Bound.Add(new Vector3(transform.localPosition.x + (transform.localScale.x / 2), transform.localPosition.y + (transform.localScale.y / 2), transform.localPosition.z + (transform.localScale.z / 2)));
        Bound.Add(new Vector3(transform.localPosition.x + (transform.localScale.x / 2), transform.localPosition.y + (transform.localScale.y / 2), transform.localPosition.z - (transform.localScale.z / 2)));
        Bound.Add(new Vector3(transform.localPosition.x - (transform.localScale.x / 2), transform.localPosition.y + (transform.localScale.y / 2), transform.localPosition.z + (transform.localScale.z / 2)));
        Bound.Add(new Vector3(transform.localPosition.x - (transform.localScale.x / 2), transform.localPosition.y + (transform.localScale.y / 2), transform.localPosition.z - (transform.localScale.z / 2)));

        Gizmos.DrawLine((Bound[0]), Bound[1]);
        Gizmos.DrawLine((Bound[1]), Bound[3]);
        Gizmos.DrawLine((Bound[2]), Bound[3]);
        Gizmos.DrawLine((Bound[0]), Bound[2]);

        Gizmos.DrawLine((Bound[0]), Bound[4]);
        Gizmos.DrawLine((Bound[1]), Bound[5]);
        Gizmos.DrawLine((Bound[2]), Bound[6]);
        Gizmos.DrawLine((Bound[3]), Bound[7]);

        Gizmos.DrawLine((Bound[4]), Bound[5]);
        Gizmos.DrawLine((Bound[5]), Bound[7]);
        Gizmos.DrawLine((Bound[6]), Bound[7]);
        Gizmos.DrawLine((Bound[4]), Bound[6]);

    }

}
