//# Ashikhmin Shirley 2000 - Anisotropic phong reflectance model
//# [type] [name] [min val] [max val] [default val]

//float Rs 0 1 .1
//float Rd 0 1 1
//float nu 1 1000 100
//float nv 1 1000 100
//bool isotropic 1
//bool coupled_diffuse 1

float sqr( float x )
{
    return x*x;
}

float Fresnel(float f0, float u)
{
    // from Schlick
    return f0 + (1-f0) * pow(1-u, 5);
}

float3 BRDF_AshikhminShirley( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    float3 H = normalize(L+V);
    float HdotV = dot(H,V);
    float HdotX = dot(H,X);
    float HdotY = dot(H,Y);
    float NdotH = dot(N,H);
    float NdotV = dot(N,V);
    float NdotL = dot(N,L);
    
    float F = Fresnel(Rs, HdotV);
    float norm_s = sqrt((nu+1)*((isotropic?nu:nv)+1))/(8*PI);
    float n = isotropic ? nu :(nu*sqr(HdotX) + nv*sqr(HdotY))/(1-sqr(NdotH));
    float rho_s = norm_s * F * pow(max(NdotH,0), n) / (HdotV * max(NdotV, NdotL));

    float rho_d = 28/(23*PI) * Rd * (1-pow(1-NdotV/2, 5)) * (1-pow(1-NdotL/2, 5));
    if (coupled_diffuse) rho_d *= (1-Rs);

    return float3(rho_s + rho_d);
}

//# Blinn implementation of Torrance-Sparrow
//# [type] [name] [min val] [max val] [default val]

//::begin parameters
//float n 1 100 10
//float ior 1 2.5 1.5
//bool include_Fresnel 0
//bool divide_by_NdotL 1

float3 BRDF_Blinn( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    float3 H = normalize(L+V);

    float NdotH = dot(N, H);
    float VdotH = dot(V, H);
    float NdotL = dot(N, L);
    float NdotV = dot(N, V);

    float x = acos(NdotH) * n;
    float D = exp( -x*x);
    float G = (NdotV < NdotL) ? 
        ((2*NdotV*NdotH < VdotH) ?
         2*NdotH / VdotH :
         1.0 / NdotV)
        :
        ((2*NdotL*NdotH < VdotH) ?
         2*NdotH*NdotL / (VdotH*NdotV) :
         1.0 / NdotV);

    // fresnel
    float c = VdotH;
    float g = sqrt(ior*ior + c*c - 1);
    float F = 0.5 * pow(g-c,2) / pow(g+c,2) * (1 + pow(c*(g+c)-1,2) / pow(c*(g-c)+1,2));

    float val = NdotH < 0 ? 0.0 : D * G * (include_Fresnel ? F : 1.0);

    if (divide_by_NdotL)
        val = val / dot(N,L);
    return float3(val);
}

//# Blinn Phong based on halfway-floattor
//# [type] [name] [min val] [max val] [default val]

//float n 1 1000 100
//bool divide_by_NdotL 1

float3 BRDF_BlinnPhong( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    float3 H = normalize(L+V);

    float val = pow(max(0,dot(N,H)),n);
    if (divide_by_NdotL)
        val = val / dot(N,L);
    return float3(val);
}

//CookTorrance
//# [type] [name] [min val] [max val] [default val]

//float m 0.001 .3 .1
//float f0 0 1 .1
//bool include_F 1
//bool include_G 1

float sqr(float x) { return x*x; }

float Beckmann(float m, float t)
{
    float M = m*m;
    float T = t*t;
    return exp((T-1)/(M*T)) / (M*T*T);
}

float Fresnel_Schlick(float f0, float u)
{
    // from Schlick
    return f0 + (1-f0) * pow(1-u, 5);
}

float3 BRDF_CookTorrance( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    // compute the half float3
    float3 H = normalize( L + V );

    float NdotH = dot(N, H);
    float VdotH = dot(V, H);
    float NdotL = dot(N, L);
    float NdotV = dot(N, V);
    float oneOverNdotV = 1.0 / NdotV;

    float D = Beckmann(m, NdotH);
    float F = Fresnel_Schlick(f0, VdotH);

    NdotH = NdotH + NdotH;
    float G = (NdotV < NdotL) ? 
        ((NdotV*NdotH < VdotH) ?
         NdotH / VdotH :
         oneOverNdotV)
        :
        ((NdotL*NdotH < VdotH) ?
         NdotH*NdotL / (VdotH*NdotV) :
         oneOverNdotV);

    if (include_G) G = oneOverNdotV;
    float val = NdotH < 0 ? 0.0 : D * G ;

    if (include_F) val *= F;

    val = val / NdotL;
    return float3(val);
}

//# Beckmann distribution, from Cook-Torrance
//# [type] [name] [min val] [max val] [default val]

//float m 0.001 .7 .1



float Beckmann(float m, float t)
{
    float M = m*m;
    float T = t*t;
    return exp((T-1)/(M*T)) / (PI*M*T*T);
}

float3 BRDF_Beckmann( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    // compute the half float3
    float3 H = normalize( L + V );
    float NdotH = dot(N, H);

    float D = Beckmann(m, NdotH);
    return float3(D);
}

//# Exponential distribution
//# [type] [name] [min val] [max val] [default val]

//float c 0.001 1 .1
//bool normalized 1

float Exponential(float c, float t)
{
    return exp(-t/c);
}

float3 BRDF_Exponential( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    // compute the half float3
    float3 H = normalize( L + V );
    float NdotH = dot(N, H);

    float D = Exponential(c, acos(NdotH));
    if (normalized)
        D *= (1 + 4*c*c)/(2*c*c*(1 + exp(-(PI/(2*c))))*PI);
    return float3(D);
}

//# Gaussian
//# [type] [name] [min val] [max val] [default val]

//float c 0.001 1 .1

float Gaussian(float c, float thetaH)
{
    return exp(-thetaH*thetaH/(c*c));
}

float3 BRDF_Gaussian( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    // compute the half float3
    float3 H = normalize( L + V );
    float NdotH = dot(N, H);

    float D = Gaussian(c, acos(NdotH));
    return float3(D);
}

//# ggx from Walter 07
//# [type] [name] [min val] [max val] [default val]

float alpha 0.001 1 .1

float sqr(float x) { return x*x; }

float GGX(float alpha, float cosThetaM)
{
    float CosSquared = cosThetaM*cosThetaM;
    float TanSquared = (1-CosSquared)/CosSquared;
    return (1.0/PI) * sqr(alpha/(CosSquared * (alpha*alpha + TanSquared)));
}

float3 BRDF_GGX( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    float3 H = normalize( L + V );
    float D = GGX(alpha, dot(N,H));
    return float3(D);
}

//# Nishino 2009, "Directional Statistic BRDF Model"

//float n 1 1000 100
//float k .1 10 1

float3 reflect(float3 I, float3 N)
{
    return 2*dot(I,N)*N - I;
}

float3 Nishino( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    float3 H = normalize(L+V);
    float NdotH = max(0,dot(N,H));
    // note: k in Nishino is assumed negative - negate as used instead
    float epd = 1-exp(-k * pow(NdotH,n));
    // the normalization constant includes gamma functions which are unavailable in glsl
    // float Cn =  pow(n*k,1/n) / (gamma(1/n) - igamma(1/n, k) - pow(n*k, 1/n))
    // some approximation is needed
    float Cn = 1;

    return float3(Cn*epd);
}

//# TrowbridgeReitz (from Blinn 77)
//# [type] [name] [min val] [max val] [default val]

//float c 0.001 1 .1
//bool normalized 1

float sqr(float x) { return x*x; }

float TrowbridgeReitz(float c, float cosAlpha)
{
    float cSquared = c*c;
    return sqr(cSquared / (cosAlpha*cosAlpha*(cSquared-1)+1));
}

float3 BRDF_TrowbridgeReitz( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    // compute the half float3
    float3 H = normalize( L + V );
    float D = TrowbridgeReitz(c, dot(N,H));
    if (normalized) {
        D *= 1/(c*c*PI);
    }
    return float3(D);
}

//# Walter07, w/ GGX
//# [type] [name] [min val] [max val] [default val]

//float Kd 0 1 0
//float Ks 0 1 .1
//float alphaG 0.001 1 .1
//float ior 1.3 3 2
//bool useFresnel 0


float sqr(float x) { return x*x; }

float GGX(float NdotH, float alphaG)
{
    return alphaG*alphaG / (PI * sqr(NdotH*NdotH*(alphaG*alphaG-1) + 1));
}

float smithG_GGX(float Ndotv, float alphaG)
{
    return 2/(1 + sqrt(1 + alphaG*alphaG * (1-Ndotv*Ndotv)/(Ndotv*Ndotv)));
}

float3 BRDF_Walter( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    float NdotL = dot(N, L);
    float NdotV = dot(N, V);
    if (NdotL < 0 || NdotV < 0) return float3(0);

    float3 H = normalize(L+V);
    float NdotH = dot(N, H);
    float VdotH = dot(V, H);

    float D = GGX(NdotH, alphaG);
    float G = smithG_GGX(NdotL, alphaG) * smithG_GGX(NdotV, alphaG);

    // fresnel
    float c = VdotH;
    float g = sqrt(ior*ior + c*c - 1);
    float F = useFresnel ? 0.5 * pow(g-c,2) / pow(g+c,2) * (1 + pow(c*(g+c)-1,2) / pow(c*(g-c)+1,2)) : 1.0;

    float val = Kd/PI + Ks * D * G * F / (4 * NdotL * NdotV);
    return float3(val);
}

//# Ward
//# [type] [name] [min val] [max val] [default val]

//float alpha_x 0 1.0 0.15
//float alpha_y 0 1.0 0.15
//color Cs 1 1 1
//color Cd 1 1 1
//bool isotropic 0

float sqr( float x )
{
    return x*x;
}

float3 BRDF_Ward( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    float3 H = normalize(L + V);

    // specular
    float ax = alpha_x;
    float ay = isotropic ? alpha_x : alpha_y;
    float exponent = -(
        sqr( dot(H,X) / ax ) +
        sqr( dot(H,Y) / ay)
    ) / sqr( dot( H, N ) );

    float spec = 1.0 / (4.0 * 3.14159265 * ax * ay * sqrt( dot(L,N) * dot(V, N) ));
    spec *= exp( exponent );

    return Cd / 3.14159265 + Cs * spec;
}

//# Lambert
//# [type] [name] [min val] [max val] [default val]

//float reflectance 0.0 1.0 1.0

float3 BRDF_Lambert( float3 L, float3 V, float3 N, float3 X, float3 Y )
{
    return float3(reflectance / 3.14159265);
}

    //Ward G
    //float G = pow( dot(N,L) * dot(N,V), 0.5);

    // G Cook-Torrance
    //float G = min(1.0, min(2*NdotH*NdotV / VdotH, 2*NdotH*NdotL / VdotH)); G *= 1/(NdotL*NdotV);


