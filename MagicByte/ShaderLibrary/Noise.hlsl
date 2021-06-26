#ifndef NOISE_INCLUDED
#define NOISE_INCLUDED

float hash(float n)
{
    return frac(sin(n) * 43758.5453);
}

float Noise(float3 x)
{

    float3 p = floor(x);
    float3 f = frac(x);

    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;

    return lerp(lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
        lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
        lerp(lerp(hash(n + 113.0), hash(n + 114.0), f.x),
            lerp(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
}

float3 Voronoi(float3 pos)
{
	float3 d[8];
	d[0] = float3(0, 0, 0);
	d[1] = float3(1, 0, 0);
	d[2] = float3(0, 1, 0);
	d[3] = float3(1, 1, 0);
	d[4] = float3(0, 0, 1);
	d[5] = float3(1, 0, 1);
	d[6] = float3(0, 1, 1);
	d[7] = float3(1, 1, 1);

	const float maxDisplacement = .7;//.518; //tweak this to hide grid artefacts

	float3 pf = floor(pos);

	const float phi = 1.61803398875;

	float closest = 12.0;
	float3 result;
	for (int i = 0; i < 8; i++)
	{
		float3 v = (pf + d[i]);
		float3 r = frac(phi * v.yzx + 17. * frac(v.zxy * phi) + v * v * .03);
		float3 p = d[i] + maxDisplacement *(r.xyz - .5);

		p -= frac(pos);
		float lsq = dot(p, p);

		if (lsq < closest)
		{
			closest = lsq;
			result = r;
		}
	}
	float3 grayscale = (frac(result.xyz).r+ frac(result.xyz).g+ frac(result.xyz).b)/3;
	return grayscale;
}
float4 GrayscaleToNormal(float3 pos) {
	float2 size = float2(1.0, 0.0);
	const float3 off = float3(-1, 0, 1);

	float s11 = Voronoi(pos).x;
	float s01 = Voronoi(pos + float3(off.x, off.y,0)).x;
	float s21 = Voronoi(pos + float3(0, off.y, off.z)).x;
	float s10 = Voronoi(pos + float3(off.x, off.y, 0)).x;
	float s12 = Voronoi(pos + float3(0, off.y, off.z)).x;

	float3 va = normalize(float3(size.xy, s21 - s01));
	float3 vb = normalize(float3(size.yx, s12 - s10));
	return float4(cross(va, vb), s11);
}
#endif