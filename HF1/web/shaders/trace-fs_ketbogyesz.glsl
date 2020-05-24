#version 300 es
precision highp float;

in vec4 rayDir;
out vec4 fragmentColor;

uniform struct {
  mat4 rayDirMatrix;
  vec3 eyePosition;
} camera;

float dist(in vec3 pos)
{
  float d=min(length(pos-vec3(0.0f,0.0f,-3.0f))-0.1f,length(pos-vec3(0.1f,0.0f,-3.0f))-0.1f);
  return d;
}

vec3 calcgrad(in vec3 pos, in vec3 rayDir, in float epsilon){
vec3 color = vec3(1.0f,1.0f,1.0f);
vec3 grad = normalize(vec3(dist(pos+vec3(epsilon,0.0f,0.0f))-dist(pos-vec3(epsilon,0.0f,0.0f)),dist(pos+vec3(0.0f,epsilon,0.0f))-dist(pos-vec3(0.0f,epsilon,0.0f)),dist(pos+vec3(0.0f,0.0f,epsilon))-dist(pos-vec3(0.0f,0.0f,epsilon))));
grad.x=1.2*grad.x;
grad.y=0.2*grad.y;
grad.z=0.2*grad.z;
return grad;
}

void main(void) {
  vec3 pos = camera.eyePosition;
  float epsilon=0.0001f;
  float d;
  float k=0.0f;
  float b=0.0f;
  vec3 normalizedRayDir = normalize(rayDir.xyz);
  for(int j = 0; j < 150; j++)
  {
    d=dist(pos.xyz);
    pos+=d*normalizedRayDir;
    k+=1.0f/150.0f;
    if(d<epsilon)
    {
      b=1.0f;
      break;

    }
    }
  if(bool(b)){
  fragmentColor = vec4(calcgrad(pos.xyz,normalize(rayDir.xyz),epsilon),1.0f);
  }
  else{
  fragmentColor = vec4(0.0f,1.0f,0.0f,1.0f);
  }
}