#define PROCESSING_LIGHT_SHADER

uniform mat4 modelview;
uniform mat4 transform;
uniform mat3 normalMatrix;

attribute vec4 vertex;
attribute vec4 color;
attribute vec3 normal;

varying vec4 vertColor;
varying vec3 ecPosition;

void main() {
  gl_Position = transform * vertex;
  ecPosition = vec3(modelview * vertex);
  vertColor = color;
}