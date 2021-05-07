using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class RandomHSV : MonoBehaviour
{

    // Start is called before the first frame update
    void Start()
    {
        gameObject.GetComponent<MeshRenderer>().material.SetColor("_BaseColor",Random.ColorHSV());   
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
