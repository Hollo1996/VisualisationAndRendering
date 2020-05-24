#version 300 es
precision highp float;

in vec4 rayDir;
out vec4 fragmentColor;

uniform struct {
  mat4 rayDirMatrix;
  vec3 eyePosition;
} camera;


float noise(vec3 r) {
  r.xz *= 10.0;
  vec3 s = vec3(7502, 22777, 4767);
  float f = 0.0;
  for(int i=0; i<16; i++) {
    f += sin( dot(s - vec3(32768, 32768, 32768), r)
                                 / 65536.0);
    s = mod(s, 32768.0) * 2.0 + floor(s / 32768.0);
  }
  return 1.0f*f / 32.0 + 0.5 - r.y;
}


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


vec3 calcgrad(in vec3 pos){
  float epsilon = 0.05f*tanh(pos.x);
  vec3 grad = normalize(
    vec3(
      0.08f+0.9f*(noise(pos+vec3(epsilon,0.0f,0.0f))-noise(pos-vec3(epsilon,0.0f,0.0f))),
      0.10f+0.2f*(noise(pos+vec3(0.0f,epsilon,0.0f))-noise(pos-vec3(0.0f,epsilon,0.0f))),
      -0.05f+0.2f*(noise(pos+vec3(0.0f,0.0f,epsilon))-noise(pos-vec3(0.0f,0.0f,epsilon)))
      )
  );
  return grad;
}


void main(void) {
  vec3 d = normalize(rayDir.xyz);

  float t1 = (1.0 - camera.eyePosition.y) / d.y;
  float t2 = (0.0 - camera.eyePosition.y) / d.y;
  float tstart = max(min(t1, t2), 0.0);
  float tend = max(max(t1, t2), 0.0);

  float scalefact = 1.01;

  vec3 p = camera.eyePosition + d * tstart;
  vec3 step =
    d * (tend-tstart)*(scalefact-1.0)/(pow(scalefact,256.0)-1.0);
  float h;
  bool underSurface = false;
  for(int i=0; i<256; i++){
    h = noise(p);
    if(h > 0.0) {
      underSurface = true;
      break;
    }
    p += step;
    step *= scalefact;
  }

   p -=step*0.5;
   for (int i=0; i<32; i++){
   step*=0.5;
   h = noise(p);
   if (h>0.0){
   p -= step;

   }
   else{
   p+=step;

   }


   }


  if (underSurface)
    fragmentColor = vec4(calcgrad(p),1.0f);
  else
    fragmentColor = vec4(0.5f,0.5f,0.8f,1.0f);
}