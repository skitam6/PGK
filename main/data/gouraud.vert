#define PROCESSING_TEXLIGHT_SHADER

uniform mat4 texMatrix;
uniform mat4 modelview;
uniform mat4 transform;
uniform mat3 normalMatrix;

uniform vec4 lightPosition[8];
uniform vec3 lightNormal[8];
uniform vec3 lightAmbient[8];
uniform vec3 lightDiffuse[8];
uniform vec3 lightSpecular[8];
uniform vec3 lightFalloff[8];
uniform vec2 lightSpot[8];
uniform int lightCount;

attribute vec4 vertex;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texCoord;

// Zostawiamy dla parsera Processinga, by nie krzyczał błędami:
attribute vec4 ambient;
attribute vec4 specular;
attribute vec4 emissive;
attribute float shininess;

// Nasze autorskie, "twarde" uniformy, które narzuciliśmy z Java:
uniform vec4 myAmbient;
uniform vec4 mySpecular;
uniform vec4 myEmissive;
uniform float myShininess;

varying vec4 vertColor;
varying vec2 vertTexCoord;

const float zero_float = 0.0;
const float one_float = 1.0;

float falloffFactor(vec3 lightPos, vec3 vertPos, vec3 coeff) {
  vec3 lpv = lightPos - vertPos;
  vec3 dist = vec3(one_float, length(lpv), 0.0);
  dist.z = dist.y * dist.y;
  return one_float / dot(dist, coeff);
}

float spotFactor(vec3 lightPos, vec3 vertPos, vec3 lightNorm, float minCos, float spotExp) {
  vec3 lpv = normalize(lightPos - vertPos);
  vec3 nln = -one_float * lightNorm;
  float spotCos = dot(nln, lpv);
  return spotCos <= minCos ? zero_float : pow(spotCos, spotExp);
}

float lambertFactor(vec3 lightDir, vec3 vecNormal) {
  return max(zero_float, dot(lightDir, vecNormal));
}

float blinnPhongFactor(vec3 lightDir, vec3 vecNormal, vec3 viewDir, float shine) {
  vec3 halfV = normalize(viewDir + lightDir);
  float spec = max(zero_float, dot(vecNormal, halfV));
  return pow(spec, shine);
}

void main() {
  vec4 viewPos = modelview * vertex;
  vec3 ecVertex = viewPos.xyz;
  vec3 ecNormal = normalize(normalMatrix * normal);
  vec3 ecNormalInv = ecNormal * -one_float;

  vec3 totalAmbient = vec3(0);
  vec3 totalDiffuse = vec3(0);
  vec3 totalSpecular = vec3(0);

  for (int i = 0; i < 8; i++) {
    if (i >= lightCount) break;

    vec3 lightPos = lightPosition[i].xyz;
    bool isDir = lightPosition[i].w < one_float;
    float falloff = isDir ? one_float : falloffFactor(lightPos, ecVertex, lightFalloff[i]);
    float spotAtten = lightSpot[i].x <= -1.5 ? one_float : spotFactor(lightPos, ecVertex, lightNormal[i], lightSpot[i].x, lightSpot[i].y);

    vec3 lightDir;
    if (isDir) {
      lightDir = -one_float * lightNormal[i];
    } else {
      lightDir = normalize(lightPos - ecVertex);
    }

    vec3 viewDir = normalize(-ecVertex);

    float nDotVP = lambertFactor(lightDir, ecNormal);
    float nDotVPi = lambertFactor(lightDir, ecNormalInv);
    float diffFactor = max(nDotVP, nDotVPi);

    float spec = blinnPhongFactor(lightDir, (nDotVP > nDotVPi ? ecNormal : ecNormalInv), viewDir, myShininess);

    totalAmbient  += lightAmbient[i]  * falloff * spotAtten;
    totalDiffuse  += lightDiffuse[i]  * falloff * spotAtten * diffFactor;
    totalSpecular += lightSpecular[i] * falloff * spotAtten * spec;
  }

  // Używamy myAmbient, mySpecular, myEmissive, by uniknąć defektu czarnego koloru!
  vec3 ambientColor = color.rgb * myAmbient.rgb;
  vec3 totalCol = ambientColor * totalAmbient
                + color.rgb * totalDiffuse
                + mySpecular.rgb * totalSpecular
                + myEmissive.rgb;

  vertColor = vec4(totalCol, color.a);
  vertTexCoord = (texMatrix * vec4(texCoord, 1.0, 1.0)).xy;

  gl_Position = transform * vertex;
}