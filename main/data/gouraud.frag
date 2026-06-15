#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;
varying vec4 vertColor;
varying vec2 vertTexCoord;

void main() {
  vec4 texColor = texture2D(texture, vertTexCoord);
  gl_FragColor = vertColor * texColor;
}
