#ifndef BSSRDF_INCLUDED
#define BSSRDF_INCLUDED

struct BRDF {
	float3 diffuse;
	float3 specular;
	float perceptualRoughness;
	float roughness;
	float fresnel;
};

#define MIN_REFLECTIVITY 0.04

#define MEDIUMP_FLT_MAX    65504.0
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

float OneMinusReflectivity (float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

BRDF GetBRDF (Surface surface) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);

    brdf.perceptualRoughness = max(PerceptualSmoothnessToPerceptualRoughness(surface.smoothness),0.01);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

BRDF GetBRDF(Surface surface, bool PremultiplyAlpha) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity * surface.alpha;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
	
	brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}
//GGX
float SpecularStrength(Surface surface, BRDF brdf,float3 L,float3 V,float3 N,float3 H) {
	float3 h = H;
	float NoH = dot(N, h);
	float3 NxH = cross(N, h);
	float a = NoH * brdf.roughness;
	float k = brdf.roughness / (dot(NxH, NxH) + a * a);
	float d = k * k * (1.0 / PI);
	return saturateMediump(d);
}

float3 shiftTangent(float3 T, float3 N, float shift)
{
	return normalize((T + shift)*N);
}

float3 irradianceOclusion(float3 n) {
return unity_SHAr + unity_SHAg * (n.y) + unity_SHAb * (n.z) + unity_SHBr * (n.x) + unity_SHBg * (n.y * n.x) + unity_SHBb * (n.y * n.z) + unity_SHC * (3.0 * n.z * n.z - 1.0);
}

float schlickWeight(float cosTheta) {
	float m = clamp(1.0 - cosTheta, 0.0, 1.0);
	return (m * m) * (m * m) * m;
}

float3 Subsurface(float NoL, float NoV, float LoH, float roughness, Surface surface) {

	float FL = schlickWeight(NoL), FV = schlickWeight(NoV);
	float Fss90 = LoH * LoH * roughness;
	float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
	float ss = 1.25 * (Fss * (1.0 / (NoL + NoV) - 0.5) + 0.5);

	return ss * surface.subSurfaceColor;
}

float SpecularStrengthAnisotropy(Surface surface, BRDF brdf, Light light) {
	float at = max(brdf.roughness * (1.0 + surface.anisotropic), 0.005);
	float ab = max(brdf.roughness * (1.0 - surface.anisotropic), 0.005);

	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float NoH = sqrt(1 - dot(normalize(surface.normal), h) * dot(normalize(surface.normal), h));

	float ToH = dot(shiftTangent(normalize(surface.tangent), normalize(surface.normal), 0.3), h);

	float3 b = normalize(cross(normalize(surface.normal), surface.tangent));//normalize(cross(surface.normal, surface.tangent.xyz) * surface.tangent.w);

	float BoH = dot(b, h);
	float a2 = at * ab;
	float3 v = float3(ab * ToH, at * BoH, a2 * NoH);
	float v2 = dot(v, v);
	float w2 = a2 / v2;
	return a2 * w2 * w2 * (1.0 / PI);
}

float3 OrenNayar( float3 l,float3 n,  float3 v, float r, Surface surface)
{
	float r2 = r * r;
	float a = 1.0 - 0.5 * (r2 / (r2 + 0.57));
	float b = 0.45 * (r2 / (r2 + 0.09));

	float nl = dot(n, l);
	float nv = dot(n, v);

	float ga = dot(v - n * nv, n - n * nl);

	return max(0.0, nl) * (a + b * max(0.0, ga) * sqrt((1.0 - nv * nv) * (1.0 - nl * nl)) / max(nl, nv));
}

float FresnelTransmissionBRDF(float f0, float f90, float u)
{
//energyCompensation = 1.0 + NoL * (1.0 / (1.1 - brdf.roughness) - 1.0);
	float x = 1.0 - u;
	float x2 = x * x;
	float x5 = x * x2 * x2;
	return (1.0 - f90 * x5) - f0 * (1.0 - x5);

//float f90 = 0.5 + (brdf.perceptualRoughness + brdf.perceptualRoughness * LoV);

}

float FresnelBRDF(Surface surface) {
	float NoV = dot(surface.normal, surface.viewDirection);
	float f = pow(1.0 - NoV, 4.0);
	return f * 0.5 + NoV * (1.0 - f) * surface.metallic;
}

float FresnelSchlick(float f0, float f90, float u)
{
	float x = 1.0 - u;
	float x2 = x * x;
	float x5 = x * x2 * x2;
	return (f90 - f0) * x5 + f0;
}

float3 Sheen(float LdotH, Surface material) {
	float FH = schlickWeight(LdotH);
	float Cdlum = .3 * material.color.r + .6 * material.color.g + .1 * material.color.b;

	float3 Ctint = material.color / Cdlum;
	float3 Csheen = lerp(float3(1,1,1), Ctint, material.sheenTint);
	float3 Fsheen = FH * material.sheen * Csheen;
	return FH * material.sheen * Csheen;
}

float3 CharlieD(float roughness, float ndoth, Surface material)
{
	float Cdlum = .3 * material.color.r + .6 * material.color.g + .1 * material.color.b;
	float3 Ctint = material.color / Cdlum;
	float3 Csheen = lerp(float3(1, 1, 1), Ctint, material.sheenTint);

	float invR = 1. / roughness;
	float cos2h = ndoth * ndoth;
	float sin2h = 1. - cos2h;

	return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI) * Csheen;
}

float AshikhminV(float ndotv, float ndotl)
{
	return 1. / (4. * (ndotl + ndotv - ndotl * ndotv));
}
float3 TransmissionBRDF_Foliage(float3 SSS_Color, float3 L, float3 V, float3 N)
{
	float Wrap = 0.5;
	float NoL = saturate((dot(-N, L) + Wrap) / Square(1 + Wrap));

	float VoL = saturate(dot(V, -L));
	float a = 0.6;
	float a2 = a * a;
	float d = (VoL * a2 - VoL) * VoL + 1;
	float GGX = (a2 / PI) / (d * d);
	return NoL * GGX * SSS_Color;
}
float3 DirectBSSRDF (Surface surface, BRDF brdf, Light light,float ior) {

	float NoL = dot(surface.normal, light.direction);

	float3 energyCompensation = 1.0 + NoL * (1.0 / (1.1-brdf.roughness) - 1.0);

	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float LoH = dot(light.direction, h);
	float LoV = dot(light.direction, surface.viewDirection);
	float NoH = dot(surface.normal, h);
	float NoV = dot(surface.normal, surface.viewDirection);

	float f90 = 0.5 + (brdf.perceptualRoughness + brdf.perceptualRoughness * LoV);

	float D = 0;
	if (surface.anisotropic == 0)
		D = SpecularStrength(surface, brdf, light.direction, surface.viewDirection, surface.normal, SafeNormalize(light.direction + surface.viewDirection)) * FresnelTransmissionBRDF(IORtoF0(ior), f90, dot(h, surface.viewDirection));
	else
		D = SpecularStrengthAnisotropy(surface, brdf, light) * FresnelTransmissionBRDF(IORtoF0(ior), f90, dot(h, surface.viewDirection));

	D = lerp(D, CharlieD(brdf.roughness, NoH, surface), surface.sheen) * (surface.metallic);

	float3 l = light.direction + 2 * surface.normal * (-light.direction * surface.normal);
	//D += surface.transmission * SpecularStrength(surface, brdf, l, surface.viewDirection, surface.normal, SafeNormalize(l + surface.viewDirection)) * (1-FresnelTransmissionBRDF(IORtoF0(ior), f90, dot(h, surface.viewDirection)));
	D += surface.transmission * TransmissionBRDF_Foliage(surface.subSurfaceColor, l, surface.viewDirection, surface.normal) * (1 - FresnelTransmissionBRDF(IORtoF0(ior), f90, dot(h, surface.viewDirection)));

	D += FresnelSchlick(IORtoF0(ior), f90, dot(h, surface.viewDirection)) * light.color;

	return (D +
		((lerp(OrenNayar(light.direction, surface.normal, surface.viewDirection, brdf.roughness, surface) * surface.color, Subsurface(NoL, NoV, LoH, brdf.roughness, surface), surface.subsurface)) * max((1. - surface.metallic), MIN_REFLECTIVITY))
		* AshikhminV(NoV, NoL)) * (1.0f/PI);

}
float3 IndirectBRDF(Surface surface, BRDF brdf, float3 diffuse, float3 specular, float ior) {

	float3 reflection = specular * brdf.fresnel;
	reflection /= brdf.roughness * brdf.roughness + 1.0;

	return lerp(diffuse,reflection, surface.metallic) * surface.color * surface.occlusion;
}

#endif