using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ResponsiveScreen : MonoBehaviour
{

    [Header("Canvas")]
    RectTransform canvasSize;
    public GameObject canvas;
    public bool AutoGetCanvas = true;

    //Screen Size
    [Header("Screen Size")]
    public int MainScreenSizeX = 1920;
    public int MainScreenSizeY = 1080;

    //Object Preset
    float Width;
    float Height;
    float ScaleX;
    float ScaleY;

    //Percents
    float PositionXPercent, PositionYPercent, ScaleXPercent, ScaleYPercent;

    //Responsive Set
    float NewWidth;
    float NewHeight;
    float NewScaleX;
    float NewScaleY;

    // Start is called before the first frame update
    void Start()
    {
        if (AutoGetCanvas)
        {
        canvas = GameObject.FindGameObjectWithTag("UICanvas");
        }

        ScaleX = gameObject.GetComponent<RectTransform>().localScale.x;
        ScaleY = gameObject.GetComponent<RectTransform>().localScale.y;

        Width = gameObject.GetComponent<RectTransform>().localPosition.x;
        Height = gameObject.GetComponent<RectTransform>().localPosition.y;

        PositionXPercent = (100 * Width) / MainScreenSizeX;
        ScaleXPercent = (100 * ScaleX) / MainScreenSizeX;

        PositionYPercent = (100 * Height) / MainScreenSizeY;
        ScaleYPercent = (100 * ScaleY) / MainScreenSizeY;

        resizeScreen();

    }

    // Update is called once per frame
    void Update()
    {

       // if (resize_)
        //{

           // resize_ = false;
        //}

    }

    public void resizeScreen()
    {
        canvasSize = canvas.GetComponent<RectTransform>();

        float CanvasX = canvasSize.rect.width;
        float CanvasY = canvasSize.rect.height;

        NewWidth = (PositionXPercent * CanvasX) / 100;
        NewHeight = (PositionYPercent * CanvasY) / 100;

        NewScaleX = (ScaleXPercent * CanvasX) / 100;
        NewScaleY = (ScaleYPercent * CanvasY) / 100;

        gameObject.GetComponent<RectTransform>().localPosition = new Vector2(NewWidth, NewHeight);
        gameObject.GetComponent<RectTransform>().localScale = new Vector2(NewScaleX, NewScaleY);
    }

}
