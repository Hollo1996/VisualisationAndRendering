#version 300 es
#define M_PI 3.1415926535897932384626433832795
#define SQR3 1.73205081
#define BOX_MODE 0.0f
#define INTERSECT_MODE 1.0f
#define POSITION_MODE 2.0f
#define GRADIENT_MODE 3.0f
#define PHONG_DIRECTIONAL_MODE 4.0f
#define PHONG_POINT_MODE 5.0f
#define MATCAP_MODE 6.0f
#define ONION_MODE 7.0f
#define SHADOW_MODE 8.0f
precision highp float;
precision highp sampler3D;

in vec2 texPos;
in vec4 rayDir;

out vec4 fragmentColor;

uniform struct {
  sampler3D volume;
  sampler2D matcap;
} scene;

uniform struct {
  mat4 rayDirMatrix;
  vec3 position;
  float mode;
} camera;

const int quadraticCount=1;
uniform struct {
  mat4 surface;
  mat4 clipper;
} quadrics[quadraticCount];

//COUNT OF VEXELS ON ONE AXIS OF CUBIC 3D TEXTURE
const int texSize = 256;
//SIZE OF VEXEL
const float vexelDistance = 1.0f / 256.0f;

//PHONG
//POSITION OF POINT LIGHT
const vec3 lightPos = vec3(3,3,3);
//COLORS
const vec3 ambientCol = vec3(0.1,0.1,0.1);
const vec3 diffCol = vec3(1.0,0.8431,0.0);
const vec3 specCol = vec3(6.0,6.0,6.0);
//CONSTANTS
const float ambRef = 0.3;
const float diffRef = 0.7;
const float specRef = 0.7;
const float shininess = 8.0;

//SHADOW MARCHING CONSTANTS
float stepLength = vexelDistance * 2.0f;
int limit = texSize * 2;

//ONION LEVELS
const float levelStep = 0.2;
vec3 surfaceCols[3];

//COLOR OF BACKGROUND
const vec4 backGroundCol = vec4(0.5,0.5,0.5,1);



//CALCULATION OF NIEREST INTERSECTION WITH A CUBE PARALELL WITH ALL AXIS
vec3 intersectBox(vec3 startPos, vec3 rayDir, bool enter){

  //MULTIPLYER OF RAY DIRECTION TO INTERSECTION
  float times[3];
  vec3 intersections[3];

  for(int i=0; i<3; i++){
    if(  (rayDir[i] > 0.0f && enter)
      || (rayDir[i] <= 0.0f && !enter) )
      times[i] = (0.0f - startPos[i]) / rayDir[i];
    else
      times[i] = (1.0f - startPos[i]) / rayDir[i];
    intersections[i] = startPos + rayDir * times[i];
  }

  //INDEX OF SIDE WITH INTERSECTION OF MINIMAL DISTANCE
  vec3 intersection = startPos;
  float time = 1000000.0;
  for(int i=0; i<3; i++){    
      //IS THE EXISTING INTERSECTION BETTER THAN PREVIOUS AND ON THE SIDE
    if(times[i] < time ){
      int ixCoord1 = (i + 1) % 3;
      int ixCoord2 = (i + 2) % 3;
      if(  intersections[i][ixCoord1] >= 0.0f
        && intersections[i][ixCoord1] <= 1.0f
        && intersections[i][ixCoord2] >= 0.0f
        && intersections[i][ixCoord2] <= 1.0f
        ){
          time = times[i];
          intersection = intersections[i];
        }
    }
  }
  
  return intersection;
}

float intersectQadric(vec4 e, vec4 d, mat4 coeff, mat4 clipper){
  float a = dot(d*coeff,d);
  float b = dot(e*coeff,d) + dot(d*coeff,e);
  float c = dot(e*coeff,e);

  float disc = b*b - 4.0 * a * c;
  if(disc < 0.0)
    return -1.0;

  float t1 = (-b - sqrt(disc)) / (2.0 * a);
  float t2 = (-b + sqrt(disc)) / (2.0 * a);

  vec4 h1 = e+d*t1;
  vec4 h2 = e+d*t2;

  if(dot(h1*clipper,h1) > 0.0)
    t1=-1.0;
  if(dot(h2*clipper,h2) > 0.0)
    t2=-1.0;

  return (t1 < 0.0) ? t2 : (t2 < 0.0 ? t1 : min(t1,t2));
}

vec2 findBestHit(vec4 e, vec4 d){
  float time= -1.0f;
  int index = -1;
  for(int i = 0; i < quadraticCount; i++){
    float actualTime = intersectQadric(e,d,quadrics[i].surface,quadrics[i].clipper);
    if(actualTime > 0.0f && (actualTime < time || time == -1.0 )){
      time = actualTime;
      index = i;
    }
  }

  return vec2( time, float(index) );
  
}

void main(void) {
  //INPUT DATA
  vec4 d = vec4(normalize(rayDir.xyz),0);
  vec4 e = vec4(camera.position.xyz,1);

  vec3 radience = vec3(0,0,0);

  
  vec2 best = findBestHit(e, d);
  float t = best.x;
  int index = int(best.y); 

  if(t > 0.0) {
    vec4 hit = e + d * t;
    vec4 grad = hit * quadrics[0].surface + quadrics[0].surface * hit;
    vec3 norm = normalize(grad.xyz);
    radience = norm; 
    }
  else
    radience = backGroundCol.xyz;


  fragmentColor = vec4(radience,1);
}