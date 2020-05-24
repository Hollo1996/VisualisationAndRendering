#version 300 es
precision highp float;

in vec4 rayDir;
out vec4 fragmentColor;

uniform struct {
  mat4 rayDirMatrix;
  vec3 eyePosition;
} camera;

vec4 quatMult( vec4 q1, vec4 q2 ) {
   vec4 r;

   r.x   = q1.x * q2.x - dot( q1.yzw, q2.yzw );
   r.yzw = q1.x * q2.yzw + q2.x * q1.yzw + cross( q1.yzw, q2.yzw );

   return r;
}

vec4 quatSq( vec4 q ) {
   vec4 r;

   r.x   = q.x * q.x - dot( q.yzw, q.yzw );
   r.yzw = 2.0 * q.x * q.yzw;

   return r;
}

void iterateIntersect( inout vec4 q, inout vec4 qp) {
   for( int i = 0; i < 10; i++ ) {
      qp = 2.0 * quatMult(q, qp);
      q = quatSq(q) + vec4(1, 0.5, -0.1, 0.3);

      if( dot( q, q ) > 7.0 ) {
         break;
      }
   }
}

float dist(vec3 p)
{
  vec4 z = vec4( p, 0.0 );
  vec4 zp = vec4( 1, 0.0, 0.0, 0.0 );
  iterateIntersect( z, zp );
  float normZ = length( z );
  return 0.5 * normZ * log( normZ ) / length( zp );
}


vec3 calcgrad(in vec3 pos, in float epsilon){
  vec3 grad = normalize(vec3(dist(pos+vec3(epsilon,0.0f,0.0f))-dist(pos-vec3(epsilon,0.0f,0.0f)),dist(pos+vec3(0.0f,epsilon,0.0f))-dist(pos-vec3(0.0f,epsilon,0.0f)),dist(pos+vec3(0.0f,0.0f,epsilon))-dist(pos-vec3(0.0f,0.0f,epsilon))));
  return grad;
}


void main(void) {
  vec3 pos = camera.eyePosition;
  float epsilon=0.001f;
  float d;
  float b=0.0f;
  vec3 normalizedRayDir = normalize(rayDir.xyz);
  for(int j = 0; j < 300; j++)
  {
    d=dist(pos.xyz);
    pos+=d*normalizedRayDir;
    if(d<epsilon)
    {
      b=1.0f;
      break;

    }
    }
  if(bool(b)){
  fragmentColor = vec4(calcgrad(pos.xyz,epsilon),1.0f);
  }
  else{
  fragmentColor = vec4(0.0f,1.0f,0.0f,1.0f);
  }
}