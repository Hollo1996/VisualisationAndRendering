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
  //sampler3D volume;
  //sampler2D matcap;
  samplerCube env;
} scene;

uniform struct {
  mat4 rayDirMatrix;
  vec3 position;
  float mode;
} camera;

const int quadraticCount=3;
uniform struct {
  mat4 surface;
  mat4 clipper;
  vec4 kd;
} quadrics[quadraticCount];

const int lightCount=2;
uniform struct {
  vec4 position; //dir -> w=0.0f, pos -> w=1.0f
  vec3 powerDensity;
} lights[lightCount];

float intersectQadric(vec4 e, vec4 d, mat4 coeff, mat4 clipper){
  float a = dot(d*coeff,d);
  float b = dot(e*coeff,d) + dot(d*coeff,e);
  float c = dot(e*coeff,e);

  float disc = b*b - 4.0 * a * c;
  if(disc < 0.0)
    return -1.0f;

  float t1 = (-b - sqrt(disc)) / (2.0f * a);
  float t2 = (-b + sqrt(disc)) / (2.0f * a);

  vec4 h1 = e+d*t1;
  vec4 h2 = e+d*t2;

  if(dot(h1*clipper,h1) > 0.0)
    t1=-1.0f;
  if(dot(h2*clipper,h2) > 0.0)
    t2=-1.0f;

  return (t1 < 0.0) ? t2 : (t2 < 0.0 ? t1 : min(t1,t2));
}

struct Hit {
  float time;
  int index;
};

Hit findBestHit(vec4 e, vec4 d){
  Hit h;
  h.time= -1.0f;
  h.index = -1;
  for(int i = 0; i < quadraticCount; i++){
    float actualTime = 
      intersectQadric(e,d,quadrics[i].surface,quadrics[i].clipper);
    if(actualTime > 0.0f && (actualTime < h.time || h.time < 0.0 )){
      h.time = actualTime;
      h.index = i;
    }
  }

  return h;
  
}

vec3 getQuadraticNormal(mat4 coeff, vec4 hit){
  return normalize((hit*coeff + coeff*hit).xyz);
}

vec3 shade(vec3 normal, vec3 viewDir, vec3 lightDir,vec3 powerDensity, vec3 kd){
  vec3 halfway = normalize(viewDir + lightDir);
  float cosa = max(dot(normal,lightDir),0.0f);
  float cosb = max(dot(normal,viewDir),0.0f);
  return powerDensity * kd * cosa
    + 
    powerDensity * vec3(3,3,3) * pow(max(dot(halfway, normal),0.0f),25.0f) * cosa / max(cosa, cosb);
}

vec3 directLighting(vec4 pos, vec3 normal, vec3 viewDir, vec3 kd){
  vec3 radiance;
  for(int i=0;i<lightCount;i++){
    vec3 lightDiff = lights[i].position.xyz - pos.xyz * lights[i].position.w;
    vec3 lightDir = normalize(lightDiff);
    vec3 powerDensity = lights[i].powerDensity.xyz / dot(lightDiff,lightDiff);
    Hit shadowHit = findBestHit(pos + vec4(normal,0) * 0.01f,vec4(lightDir,0));
    if(shadowHit.time < 0.0f)
      radiance += shade(normal, viewDir, lightDir, powerDensity, kd);
  }  
  return radiance;
}

void main(void) {
  //INPUT DATA
  vec4 d = vec4(normalize(rayDir.xyz),0);
  vec4 e = vec4(camera.position.xyz,1);


  vec3 radiance = vec3(0,0,0);
  vec3 reflectanceProduct=vec3(1,1,1);

  for(int iBounce=0; iBounce < 6; iBounce++){
    Hit best = findBestHit(e, d);
    if(best.time > 0.0) {
      vec4 hit = e + d * best.time;
      vec3 normal = getQuadraticNormal(quadrics[best.index].surface, hit);
      if(dot(normal,d.xyz)>0.0f)
        normal = -normal;
      radiance += reflectanceProduct * directLighting(hit, normal, -d.xyz, quadrics[best.index].kd.rgb);
      reflectanceProduct *= 0.5f;
      //reflectanceProduct *= quadrics[best.index].reflectance;
      //reflectanceProduct *= reflectanceFromFrener; //szogfuggo, pl tukor
      //kezeljuk a sugarat, mint fat
      // d.xyz = refract(d.xyz, normal, mu);
      //ha nulla vagy kissebb epsilon a refract, akkor reflect
      d.xyz = reflect(d.xyz, normal);
      //if() dot(normal, d.xyz) < 0.0) normal = -normal;
      e = hit + vec4(normal,0) * 0.01; // refract eseten - vec4(normal,0) * 0.01, de egyszerubb a normalt szorozni -1-gyel
      }
    else{
      radiance += reflectanceProduct * texture(scene.env, d.xyz).rgb;
      break;
    }
    
  }



  fragmentColor = vec4(radiance,1);
}