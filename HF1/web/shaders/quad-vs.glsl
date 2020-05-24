#version 300 es

layout (location = 0) in vec4 vertexPos;

out vec4 rayDir;

uniform struct {
	mat4 rayDirMat;
	vec3 eyePos;
	float level;
  	float mode;
} camera;

void main(void) {
  gl_Position = vertexPos;
  rayDir = vertexPos*camera.rayDirMat;
}
