#define PROCESSING_LIGHT_SHADER

uniform mat4 modelview;
uniform mat4 transform;
uniform mat3 normalMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texCoord;

attribute vec4 ambient;
attribute vec4 specular;
attribute vec4 emissive;
attribute float shininess;

varying vec4 vertColor;
varying vec3 vertNormal;
varying vec3 ecVertex;
varying vec2 vertTexCoord;

varying vec4 vAmbient;
varying vec4 vSpecular;
varying vec4 vEmissive;
varying float vShininess;

void main() {
  vec4 viewPos = modelview * position;
  ecVertex = viewPos.xyz;
  vertNormal = normalize(normalMatrix * normal);

  vertColor = color;
  vertTexCoord = texCoord;
  vAmbient = ambient;
  vSpecular = specular;
  vEmissive = emissive;
  vShininess = shininess;

  gl_Position = transform * position;
}
