#define PROCESSING_LIGHT_SHADER

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

varying vec4 vertColor;
varying vec3 ecPosition;

uniform int lightCount;
uniform vec4 lightPosition[8];
uniform vec3 lightNormal[8];
uniform vec3 lightAmbient[8];
uniform vec3 lightDiffuse[8];
uniform vec3 lightSpecular[8];
uniform vec3 lightFalloff[8];
uniform vec2 lightSpot[8];

uniform vec4 myAmbient;
uniform vec4 mySpecular;
uniform vec4 myEmissive;
uniform float myShininess;

void main() {
  vec3 u = dFdx(ecPosition);
  vec3 v = dFdy(ecPosition);
  vec3 normal = -normalize(cross(u, v));
  
  vec3 viewDirection = normalize(-ecPosition);

  vec3 totalAmbient = vec3(0.0);
  vec3 totalDiffuse = vec3(0.0);
  vec3 totalSpecular = vec3(0.0);
  
  for (int i = 0; i < 8; i++) {
    if (i >= lightCount) break;
    
    totalAmbient += lightAmbient[i];

    if (length(lightDiffuse[i]) == 0.0 && length(lightSpecular[i]) == 0.0) continue;

    vec3 lightDir;
    float attenuation = 1.0;
    float spotEffect = 1.0;
    
    if (lightPosition[i].w == 0.0) {
      lightDir = -normalize(lightNormal[i]);
    } else {
      vec3 lightPath = lightPosition[i].xyz - ecPosition;
      float dist = length(lightPath);
      lightDir = normalize(lightPath);
      
      attenuation = 1.0 / (lightFalloff[i].x + lightFalloff[i].y * dist + lightFalloff[i].z * dist * dist);
      
      if (lightSpot[i].x > 0.0) {
        float spotCos = dot(lightDir, normalize(-lightNormal[i]));
        if (spotCos < lightSpot[i].x) spotEffect = 0.0;
        else spotEffect = pow(max(0.0, spotCos), lightSpot[i].y);
      }
    }
    
    float intensity = attenuation * spotEffect;
    
    if (intensity > 0.0) {
      float diffuseFactor = max(0.0, dot(normal, lightDir));
      totalDiffuse += lightDiffuse[i] * diffuseFactor * intensity;
      
      if (diffuseFactor > 0.0 && myShininess > 0.0) {
        vec3 reflection = reflect(-lightDir, normal);
        float specularFactor = pow(max(0.0, dot(reflection, viewDirection)), myShininess);
        totalSpecular += lightSpecular[i] * specularFactor * intensity;
      }
    }
  }
  
  vec3 baseColor = vertColor.rgb;
  
  vec3 finalColor = myEmissive.rgb + 
                    baseColor * myAmbient.rgb * totalAmbient + 
                    baseColor * totalDiffuse + 
                    mySpecular.rgb * totalSpecular;

  if (length(myEmissive.rgb) > 0.05) {
    finalColor = baseColor;
  }
  
  gl_FragColor = vec4(finalColor, vertColor.a);
}