#version 300 es 
precision highp float;
in vec2 tex;
in vec4 rayDir;
out vec4 fragmentColor;


void main(void) {
  fragmentColor = vec4(normalize(rayDir.xyz),1);
}