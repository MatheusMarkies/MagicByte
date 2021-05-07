using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SceneObject
{

    GameObject sceneGameObject;
    public struct sceneObject
    {
        public Vector3 Position;
        public Vector4 Albedo;
        public float Smoothness;
        public float Metallic;
        public Vector4 Emission;
        public float Anisotropy;
        public int RenderType;

        public int ObjectMesh;

        public int indices_offset;
        public int indices_count;
        public Matrix4x4 localToWorldMatrix;
    };

    public struct MeshObject
    {
        public int indices_offset;
        public int indices_count;
        public Matrix4x4 localToWorldMatrix;
    };

    List<Vector3> vertexList = new List<Vector3>();

    public enum RenderType
    {
        Diffuse,
        Refract,
        Metallic
    }
    public enum MeshType
    {
        Mesh,
        Sphere,
        Cube
    }

    sceneObject _sceneObject = new sceneObject();

    public Vector3 getPosition() { return this._sceneObject.Position; }
    public Vector4 getAlbedo() { return this._sceneObject.Albedo; }
    public float getSmoothness() { return this._sceneObject.Smoothness; }
    public float getMetallic() { return this._sceneObject.Metallic; }
    public Vector4 getEmission() { return this._sceneObject.Emission; }
    public float getAnisotropy() { return this._sceneObject.Anisotropy; }
    public int getRenderType() { return this._sceneObject.RenderType; }
    public void setPosition(Vector3 Position) { this._sceneObject.Position = Position; }
    public void setAlbedo(Vector4 Albedo) { this._sceneObject.Albedo = Albedo; }
    public void setSmoothness(float Smoothness) { this._sceneObject.Smoothness = Smoothness; }
    public void setMetallic(float Metallic) { this._sceneObject.Metallic = Metallic; }
    public void setEmission(Vector4 Emission) { this._sceneObject.Emission = Emission; }
    public void setAnisotropy(float Anisotropy) { this._sceneObject.Anisotropy = Anisotropy; }
    public void setRenderType(RenderType RenderType) { this._sceneObject.RenderType = (int)RenderType; }

    public GameObject getGameObject() { return this.sceneGameObject; }
    public void setGameObject(GameObject sceneGameObject) { this.sceneGameObject = sceneGameObject; }
    public sceneObject getSceneObject() { return this._sceneObject; }
    public void setSceneObject(sceneObject _sceneObject) { this._sceneObject = _sceneObject; }

    public void setVertexList(List<Vector3> vertexList) { this.vertexList = vertexList; }
    public List<Vector3> getVertexList() { return this.vertexList; }

    public void setIndexOffSet(int index) { this._sceneObject.indices_offset = index; }
    public int getIndexOffSet() { return this._sceneObject.indices_offset; }
    public void setIndexCount(int index) { this._sceneObject.indices_count = index; }
    public int getIndexCount() { return this._sceneObject.indices_count; }

    public void setLocalToWorldMatrix(Matrix4x4 local2world) { this._sceneObject.localToWorldMatrix = local2world; }
    public Matrix4x4 getLocalToWorldMatrix() { return this._sceneObject.localToWorldMatrix; }

    public int getObjectMeshType() { return this._sceneObject.ObjectMesh; }
    public void setObjectMeshType(MeshType meshType) { this._sceneObject.ObjectMesh = (int)meshType; }

}