#define PROCESSING_TEXLIGHT_SHADER

uniform mat4 texMatrix;
uniform mat4 modelview;
uniform mat4 transform;
uniform mat3 normalMatrix;

attribute vec4 vertex;
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

void main() {
  vec4 viewPos = modelview * vertex;
  ecVertex = viewPos.xyz;
  vertNormal = normalize(normalMatrix * normal);

  vertColor = color;
  vertTexCoord = (texMatrix * vec4(texCoord, 1.0, 1.0)).xy;

  gl_Position = transform * vertex;
}