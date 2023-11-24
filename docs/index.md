![](https://i.ibb.co/7z3WTYx/Horologium-Logo-DEFIN.png)

![](https://i.ibb.co/7Wr7QQj/IMG-3299.jpg)

# Horologium


## 12/03/2021

____

Matheus da Costa Caffer Markies

Quasar Studio


# Visão geral:

Esse tópico tem o intuito de mostrar o processo de criação de um jogo relativamente grande. Aqui vou postar atualizações (No caso, minhas partes no projeto) e dicas para quem quiser seguir este caminho. Já deixo avisado que algumas partes do tema abordado exigem conhecimentos específicos do leitor. No entanto, em geral esse documento pode ser apreciado por qualquer um.

. 


# Links Relevantes:


[Facebook](https://www.facebook.com/EquipeQuasarStudios/)

[Instagram](https://www.instagram.com/quasar.studiosbrasil/)

[Youtube](https://www.youtube.com/channel/UCkngjEDMx9y_vW0t7Io05gg)

[Twitter](https://twitter.com/MarkiesMatheus)

[Patreon](https://www.patreon.com/matheusmarkies)

[Deviantart](https://www.deviantart.com/matheusmarkies)


# Dito isso mãos à obra!

Bom, primeiramente preciso atualizar vocês até o estado atual do projeto. 

Estamos em 24/12/2019 quando eu tive a ideia de reunir alguns colegas que eu considero bastante capacitados (Luan Tomimoto e Wesley Rodrigues) em um projeto para um jogo que inicialmente seria um mundo aberto estilo Shadow of the Colossus. 

O projeto acabou não dando certo logo no primeiro mês de produção, então eu pedi para que o Luan fizesse um primeiro esboço de uma ideia de um jogo single player e de preferência que possuísse traços de Steam Punk. 

Ele nos apresentou duas ideias, a primeira era um jogo de batalhas com seres mágicos estilo pokemon, mas com suas peculiaridades, e o outro é o projeto que estamos agora.


# Sinopse 
##### Horologium 

Em um universo magic-steam punk, o jovem Phillip deseja seguir os passos de seu falecido irmão e se tornar um inventor famoso. Está em sua oficina desenhando um projeto. Certa hora, algo misterioso cai em sua garagem, uma garota chamada Horo que estava sendo perseguida pelo governo por ser parte de um relógio mágico muito importante, o Horologium. Após uma primeira conversa, os militares rastreiam a garota até a casa, e Phillip é forçado a sair em uma jornada com a garota e recuperar as partes do relógio e impedir a convergência temporal.

Embarque nessa jornada misteriosa, engraçada e emocionante desse jovem inventor e a garota relógio, enfrentando inimigos de um tempo em convergência.


# Primeiras Etapas 
##### Primeiro semestre de 2020 

Após definirmos a primeira ideia a seguir, era a hora de designar algumas tarefas e melhorar o trabalho individual. Como eu possuo já uma boa bagagem na Unity Engine e também com shaders e afins, eu fiquei com as  tarefas de artista digital além de programador de sistemas físicos, roteirista junto com o Luan e um tempo depois eu também ficaria com a parte de concept art do projeto. 


## Gráficos 

Para agilizar o trabalho eu precisava estabelecer alguns shaders padrões do projeto, de modo a criar uma identidade gráfica para o jogo. E por esse motivo também precisávamos de uma Render Pipeline que se adaptasse ao projeto, em primeira análise, a Universal Render Pipeline da própria Unity parecia uma boa opção, mas logo se mostrou inviável pela falta de controle gráfico e de performance que ela retornava, estando quase sempre presa ao Shader Graph ou ao Visual Effects Graph. Sendo assim, a única alternativa era criar o nosso próprio RP usando o sistema de Scriptable Render Pipeline da unity,  até o momento eu não tinha ideia de como prosseguir com a implementação de um SRP, já que, nem a própria unity explica muito como fazer isso. 

Pesquisei projetos que possuíam implementações semelhantes, e me baseei neles para começar a minha. Foi aí que eu comecei a trabalhar na Magic Byte Render Pipeline focando em uma abordagem mais amigável para os artistas, além de uma grande gama de tipos de superfícies. E suas abordagens serão explicadas nos próximos tópicos.


## Iluminação Bruta

Como dito acima, estou utilizando um SRP, logo preciso criar toda a iluminação dos meus objetos. Então precisamos adicionar à luz da [Directional Light](https://docs.unity3d.com/Manual/Lighting.html), faremos isso a partir dos dados que o pipeline está mandando para a GPU.

```
buffer.SetGlobalInt(_directionalLightCount, count);
buffer.SetGlobalVectorArray(_directionalLightColor, lightColor);
buffer.SetGlobalVectorArray(_directionalLightDirection, lightDirection);
buffer.SetGlobalVectorArray(_directionalLightShadowData, shadowData);
```
Command Buffer responsável por enviar as características de cada luz até a GPU

A iluminação bruta será calculada a partir do produto escalar (cosseno) entre o vetor normal e o vetor de direção da luz vezes a atenuação da luz (definida individualmente em cada luz). Depois disso, multiplicamos pela cor da luz, assim as partes escuras permanecem escuras (pois na escala de cor o preto é igual a 0), as partes claras ganham cor.

Para o cálculo do produto escalar usamos a função dot:

![](https://i.ibb.co/BZ98nzq/Code-Cogs-Eqn-1.png)
![](https://i.ibb.co/FW1Lxh9/Code-Cogs-Eqn-2.png)

Estamos lidando com vetores unitários, nesse caso o produto dos módulos será igual a um, então a função dot será a multiplicação vetorial.


```
color += saturate(dot(surface.normal, light.direction) * light.attenuation) * light.color;//Adicionar sombra propria
```
![](https://i.ibb.co/kXxqNvC/Xbfg2FV.png)

Resultado da iluminação por Directional Light

O mesmo é efeito para outros tipos de luz. Porém nas spotlights são adicionados um fator de ângulo para corrigir o efeito visual para algo como uma elipse.


# Renderização Baseada em Física

PBR ou Physically based rendering (Renderização baseada em física) são técnicas de renderização que tem como objetivo simular aproximações físicas do mundo real na iluminação gerada em computador

Para que um modelo de iluminação seja considerado fisicamente baseado ele deve seguir 3 condições básicas.

1- Conservar sua energia
2- Simulação de microfacetes
3- Modelo de BRDF fisicamente baseado


## Simulação de Microfacetes:

A teoria de microfacetes nos mostra que toda superfície em uma escala microscópica possui pequenas ranhuras que funcionam como espelhos perfeitamente reflexivos. Em algumas superfícies chamadas de dielétricas, essas ranhuras não são alinhadas espalhando a luz de forma aleatória, assim mantendo uma iluminação difusa.

Já as superfícies metálicas espelham a luz de forma uniforme, criando um brilho especular.

![](https://i.ibb.co/YPb4vjG/8FgWji6.png)
![](https://i.ibb.co/LrWrw35/tzuDL3H.png)

# Difusa/Metálica

Em resumo, quanto mais áspera for a superfície, mais desalinhado as microfissuras estarão.

Precisamos juntar as 3 condições em uma equação que retorne a irradiância. Para isso vamos usar essa função:

![](https://i.ibb.co/zxvFXBy/Code-Cogs-Eqn.png)
![](https://i.ibb.co/xJMTpwW/Soda-PDF-converted-Code-Cogs-Eqn.png)

D(h,n): Função de distribuição BRDF
G(n,l,v): Termo geométrico
F(n,v): Termo Fresnel

Para materiais com uma iluminação padrão, a função BRDF escolhida foi o GGX, tanto por aspectos gráficos quanto por performance.

![](https://i.ibb.co/MGD06sC/ggx-vs-Phong.jpg)

Exemplos de funções de distribuição e seus aspectos especulares
Função GGX:

![](https://i.ibb.co/3f0ZFvS/Code-Cogs-Eqn-8.png)
![](https://i.ibb.co/8bs1xJp/Code-Cogs-Eqn-4.png)
![](https://i.ibb.co/YL2MBjn/Code-Cogs-Eqn-5.png)

```
float GGX(Surface surface, BRDF brdf, Light light) {
  float3 h = SafeNormalize(light.direction + surface.viewDirection);
  float NoH = dot(surface.normal, h);
  float3 NxH = cross(surface.normal, h);
  float a = NoH * brdf.roughness;
  float k = brdf.roughness / (dot(NxH, NxH) + a * a);
  float d = k * k * (1.0 / PI);
  return saturateMediump(d);
}
```


A divisão por PI garante que a energia refletida nunca será maior que 1, ou seja, não estamos criando mais energia do nada, garantindo o realismo físico.

![](https://i.ibb.co/ZcnPvRZ/deacd57-f19ca70d-057f-41ef-9db5-54f989e5acb5-1.png)

No entanto, para diferentes materiais precisamos de diferentes funções de distribuição, já que, a luz se comporta de maneiras diferentes, tanto refletida quanto a transmitida, mesmo que essa última não esteja sempre sendo simulada.

Por esse motivo, usamos outros tipos de BRDF para roupas, metais, cabelo, etc.


## Correção de Cor Difusa

Também abordagens que alteram sua cor difusa. Como visto em shaders de tecido e folhas onde a cor difusa recebe traços de Scattering para adicionar realismo à iluminação.

Para tecidos:


```
float3 diffuse = brdf.diffuse * (1.0f / dot(float3(0.3f,0.6f,1.0f),brdf.diffuse)) * saturate((LoV * fresnel + NoL) * light.color);
```

![](https://i.ibb.co/Rcd1SgN/Sem-Diffuse.png)
![](https://i.ibb.co/sgWJHfk/Com-Diffuse.png)
Sem alteração/Com alteração

Ainda utilizaremos a correção de gamma nos materiais com iluminação Standard, e para completar o nosso BRDF adicionaremos o Shilick Fresnel que utiliza 2 dimensões, uma é a reflectância quando se olha o objeto perpendicularmente conhecida como f0, é a outra e o cosseno entre a luz e o vetor mediano (h).

Correção de gamma: Definimos 2.2 como a gamma padrão do sistema sRGB e usamos uma função power para elevar a cor a 2.2.


```
float3 GammaController(float3 color)
{
  return float3(pow(color.r, 2.2), pow(color.g, 2.2), pow(color.b, 2.2));
}
```

![](https://i.ibb.co/9ZHfPcy/Code-Cogs-Eqn-21.png)
![](https://i.ibb.co/7y72SQy/Sem-Correcao.png)![](https://i.ibb.co/DwsKyvf/Com-Correcao.png)
Sem correção/Com correção

Fresnel: Adotaremos f0 como um valor único, mesmo que para metais esse valor represente uma cor.

Para esses metais multiplicaremos o fresnel pela interpolação entre a cor normal e a cor especular usando a função lerp controlada pelo nível metálico.


```
  float f0 = pow((surface.fresnelStrength) / (surface.fresnelStrength + 2), 2);
  float F = FresnelBRDF(f0, LoH) * surface.occlusion;

  if (surface.anisotropic == 0) {
  return (1 / PI) * (SpecularStrength(surface, brdf, light)* G * (F * lerp(light.color*surface.color,brdf.specular,surface.metallic))) * energyCompensation + GammaController(brdf.diffuse);
```

![](https://i.ibb.co/X20N0fW/Code-Cogs-Eqn-20.png)

Função lerp garantindo que quando t = 0 o resultado = a


## Metais

Com os metais a técnica de distribuição também precisa de ajustes, já que a luz se comporta de maneira anisotrópica em metálicos. Para corrigi-la vamos utilizar as tangentes da geometria para criar um brilho especular elíptico em vez de circular.

![](https://i.ibb.co/Cw1pBXH/Code-Cogs-Eqn-12.png)
![](https://i.ibb.co/4djgsz6/Code-Cogs-Eqn-16.png)
![](https://i.ibb.co/n8VwqQ8/Code-Cogs-Eqn-19.png)

```
//Anisotropy Surfaces
float GGXAnisotropy(Surface surface, BRDF brdf, Light light) {
  float x = max(brdf.roughness * (1.0 + surface.anisotropic), 0.005);
  float y = max(brdf.roughness * (1.0 - surface.anisotropic), 0.005);

  float3 h = SafeNormalize(light.direction + surface.viewDirection);
  float NoH = sqrt(1-dot(normalize(surface.normal), h)* dot(normalize(surface.normal), h));

  float ToH = dot(shiftTangent(normalize(surface.tangent), normalize(surface.normal), 0.1), h);

  float3 b = normalize(cross(normalize(surface.normal), surface.tangent));

  float BoH = dot(b, h);
  float a2 = x * y;
  float3 v = float3(y * ToH, x * BoH, a2 * NoH);
  float v2 = dot(v, v);
  float w2 = a2 / v2;
  return a2 * w2 * w2 * (1.0 / PI);
}
```

![](https://i.ibb.co/847szqH/Wiv61ly.png)
Iluminação em metais

# Iluminação Global

Bom, já conseguimos uma iluminação básica e direta, mas a iluminação real de uma cena precisa também de luz indireta, ou seja, a luz refletida pelos objetos da cena.

Para isso, é usado um path tracing que simula os raios emitidos pelas fontes de luz e com isso cria um mapa de textura chamado de lightmap. Essa é uma iluminação assada e não em tempo real, por isso só pode ser usada em objetos estáticos.

Atualmente estou utilizando a iluminação global interna da Unity, no entanto não estou gostando muito dos resultados, então estou estudando meios alternativos.

No entanto, vou apresentar a implementação, e como podemos chegar em resultados com reflexão e refração usando a Reflections Probe.

A Unity nos envia os dados da iluminação global e o próprio lightmap por buffers até a GPU, assim como é feito com os dados das luzes da cena. Então precisamos ler esses dados e jogá-los nos materiais.

Primeiro criamos um método chamado getGI, que vai nos retornar uma estrutura de mesmo nome.


```
struct GI {
  float3 diffuse;
  float3 specular;
  float3 reflect;
  float3 refract;
};

GI getGI(float2 lightMapUV, Surface surface, BRDF brdf,float clearCoatRoughness) {
  GI gi;

  gi.diffuse = SampleLightMap(lightMapUV) + SampleLightProbe(surface);
  gi.specular = SampleEnvironment(surface, brdf);
  gi.reflect = SampleReflect(surfaceWS, clearCoatRoughness);
  gi.refract = SampleRefract(surface);

  return gi;
}
```


O método SampleLightMap vai ler o lightMap e coletar a cor difusa para o objeto em questão

Já os outros vão coletar informações da Reflection Probe.


```
float3 SampleLightMap(float2 lightMapUV) {
#if defined(LIGHTMAP_ON)//Se o GI estiver ativado
  return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightMapUV,float4(1.0, 1.0, 0.0, 0.0),true,float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0));
#else//Se o GI nao estiver ativado retorne preto
  return 0.0;
#endif
}
```


No  gi.specular teremos:


```
float3 SampleEnvironment(Surface surface, BRDF brdf) {
  float3 uvw = reflect(-surface.viewDirection, surface.normal);
  float mip = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
  float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);

  return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}
```


Muito semelhante com o usado em gi.reflect, porém para ele usaremos o roughness do clearCoat como Mip, já que ele serve somente de reflexo para o sistema de verniz.

Já para as refrações usamos um método diferente para adicionar o valor de IOR (índice de refração) do material. 


```
GI getGlassGI(float2 lightMapUV, Surface surface, BRDF brdf, float IOR, float refraction = 1) {
  GI gi;
  gi.diffuse = SampleLightMap(lightMapUV) + SampleLightProbe(surface);
  gi.specular = SampleEnvironment(surface, brdf);
  gi.reflect = SampleReflect(surface);
  gi.refract = SampleRefract(surface, IOR, refraction);

  return gi;
}
```


E em vez de utilizar reflect usamos refract e um efeito de chromatic aberration na imagem refratada.


```
float4 ChromaticAberrationRefraction(float2 chromaticAberration, float3 uvw, float mip) {
  float colR = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x - chromaticAberration.x, uvw.y - chromaticAberration.x, uvw.z - chromaticAberration.x), mip).r;
  float colG = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x, uvw.y, uvw.z), mip).g;
  float colB = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x + chromaticAberration.x, uvw.y + chromaticAberration.x, uvw.z + chromaticAberration.x), mip).b;

return float4(lerp(float3(lerp(colR, colG, 0.1), lerp(colG, colB, 0.1), lerp(colR, colB, 0.1)), SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, float3(uvw.x, uvw.y, uvw.z), mip), 0.5), 1);
}

float3 SampleRefract(Surface surface, float IOR, float refraction) {
  float3 uvw = refract(-surface.viewDirection, surface.normal, IOR);
  float mip = PerceptualRoughnessToMipmapLevel(0);
  float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);
return DecodeHDREnvironment(environment + ChromaticAberrationRefraction(float2(0.002, 0.0005), uvw, mip), unity_SpecCube0_HDR) * refraction;
}
```


E assim temos a iluminação global funcionando e adicionando realismo à cena.

Já possuímos uma grande variedade de shaders, mesmo que ainda não chegamos no objetivo principal (Uma identidade gráfica), já que para isso precisamos de artes e sketchs para ter uma visão mais palpável para seguir. Então vamos pular direto para a parte artística deste artigo.

![](https://i.ibb.co/wW0GJFr/Shaders.png)

### Design e Sketchs
