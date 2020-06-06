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

const int quadraticCount=5;
uniform struct {
  mat4 surface;
  mat4 clipper;
  float materialIndex;
} quadrics[quadraticCount];

const int materialCount=3;
uniform struct {
  vec3 kd;
  vec3 ks;
  vec3 indexOfRefraction;
  vec3 extinctionCoefficient;
  float shininess;
} materials[materialCount];

const int lightCount=3;
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

vec3 shade(vec3 normal, vec3 viewDir, vec3 lightDir,vec3 powerDensity, int materialIx){
  vec3 halfway = normalize(viewDir + lightDir);
  float cosa = max(dot(normal,lightDir),0.0f);
  float cosb = max(dot(normal,viewDir),0.0f);
  return  powerDensity * materials[materialIx].kd * cosa
        + powerDensity * materials[materialIx].ks * cosa
        * max(pow(dot(halfway, normal),materials[materialIx].shininess),0.0f)
        / max(cosa, cosb);
}

vec3 lighting(vec4 pos, vec3 normal, vec3 viewDir, int materialIx){
  vec3 radiance;
  for(int i=0;i<lightCount;i++){
    vec3 lightDiff = lights[i].position.xyz - pos.xyz * lights[i].position.w;
    vec3 lightDir = normalize(lightDiff);
    vec3 powerDensity = lights[i].powerDensity.xyz / dot(lightDiff,lightDiff);
    Hit shadowHit = findBestHit(pos + vec4(normal,0) * 0.01f,vec4(lightDir,0));
    if(shadowHit.time < 0.0f)
      radiance += shade(normal, viewDir, lightDir, powerDensity, materialIx);
  }  
  return radiance;
}

//Freshnel by sirmay's method
vec3 fresnel(vec3 normal, vec3 inDir, int materialIx, bool reverseMu){
  vec3 ior = materials[materialIx].indexOfRefraction;
  if(reverseMu)
    ior = vec3(1.0f/ior[0], 1.0f/ior[1], 1.0f/ior[2]);
  vec3 extinction = materials[materialIx].extinctionCoefficient;

  float mu = (ior[0]+ior[1]+ior[2])/3.0f;
  float cosa = dot(-normal,refract(inDir,normal,mu));
  vec3 ior_minus = ior - vec3(1.0f, 1.0f, 1.0f);
  vec3 ior_plus =  ior + vec3(1.0f, 1.0f, 1.0f);
  vec3 k2 = extinction * extinction;

  return (  (ior_minus * ior_minus) + k2
            + 4.0f * ior * pow(1.0f - cosa, 5.0f)
          ) / ( ior_plus * ior_plus + k2 );
}


//Ray Casting process
vec3 raycast(vec4 e, vec4 d){
  const int depth = 4;
  const int maxLeafCount = int(pow(2.0f,float(depth)));
  vec3 extinction[maxLeafCount];
  extinction[0] = vec3(1.0f, 1.0f, 1.0f);
  vec4 positions[maxLeafCount];
  positions[0] = e;
  vec4 directions[maxLeafCount];
  directions[0] = d;
  vec3 radiance = vec3(0,0,0);
  
  for(int level=0; level < depth; level++){

    for(int vertex = int(pow(2.0f,float(level))) - 1 ; vertex >= 0; vertex-- ){
      if(extinction[vertex] == vec3(0.0,0.0,0.0)){
        extinction[vertex * 2] = vec3(0.0,0.0,0.0);
        extinction[vertex * 2 + 1] = vec3(0.0,0.0,0.0);
        continue;
      }
      Hit best = findBestHit(positions[vertex], directions[vertex]);

      if(best.time > 0.0){

        vec4 hit = positions[vertex] + directions[vertex] * best.time;
        vec3 normal = getQuadraticNormal(quadrics[best.index].surface, hit);
        int materialIx = int(quadrics[best.index].materialIndex);
        vec3 ior = materials[materialIx].indexOfRefraction;
        float mu = (ior[0] + ior[1] + ior[2]) / 3.0f;
        bool reversMu = false;
        if(dot(normal, directions[vertex].xyz) > 0.0f){
          normal = -normal;
          mu = 1.0f / mu;
          reversMu = true;
        }

        vec3 reflectance = fresnel(normal, directions[vertex].xyz, materialIx, reversMu);
        vec3 transmitance = vec3(1.0f,1.0f,1.0f) - reflectance;
        radiance += extinction[vertex] * lighting(hit, normal, -directions[vertex].xyz, materialIx);


        extinction[2 * vertex + 1] = extinction[vertex] * transmitance;
        directions[2 * vertex + 1].xyz = normalize(refract(directions[vertex].xyz, normal, mu ));
        positions[2 * vertex + 1] = hit - vec4(normal,0) * 0.001;

        if(length( materials[materialIx].kd) > 0.5f)
          extinction[2 * vertex] = extinction[vertex] * materials[materialIx].ks;
        else
          extinction[2 * vertex] = extinction[vertex] * reflectance;
        directions[2 * vertex].xyz = normalize(reflect(directions[vertex].xyz, normal));
        positions[2 * vertex] = hit + vec4(normal,0) * 0.001;
      
      }
      else{
        radiance += extinction[vertex] * texture(scene.env, directions[vertex].xyz).rgb;
        extinction[vertex * 2] = vec3(0.0,0.0,0.0);
        extinction[vertex * 2 + 1] = vec3(0.0,0.0,0.0);
      }


    }
  }

  return radiance;

}

void main(void) {
  vec4 d = vec4(normalize(rayDir.xyz),0);
  vec4 e = vec4(camera.position.xyz,1);

  vec3 radiance = raycast(e, d);

  fragmentColor = vec4(radiance,1);
}