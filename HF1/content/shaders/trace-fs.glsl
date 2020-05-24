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

in vec4 rayDir;

out vec4 fragmentColor;

uniform struct {
  sampler3D volume;
  sampler2D matcap;
} scene;

uniform struct {
  mat4 rayDirMat;
  vec3 eyePos;
  float level;
  float mode;
} camera;

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

//INTERPOLATION FROM NEARBY PIXELS BASED ON SQUARE OF DISTANCE
float sampleTexAt(vec3 pos){
  for(int i=0;i<3;i++)
    if( pos[i]<=0.0f || pos[i]>=1.0f) return 0.0f;
  return texture(scene.volume, pos).r;
}

//CHECK IF POSITION IS IN THE HIGH INTENSITY AREA

bool isInsideAt(vec3 pos){
  return sampleTexAt( pos ) > 0.1f;
}

//BASIC GRADIENT CALCULATION FROM DIFFERENCIAL OF NEARBY POSITIONS
vec3 calcGradient(vec3 pos){
  vec3 gradient = vec3(0);
  
  //27 DIRECTIONAL GRADIENT
  /*
  for(int xSign=-1; xSign<2; xSign++)
    for(int ySign=-1; ySign<2; ySign++)
      for(int zSign=-1; zSign<2; zSign++){
        vec3 dir = normalize(vec3(xSign,ySign,zSign)) / float(texSize * 4);
        gradient += dir*sampleTexAt(pos+dir);
      }
  */  
      
   
  //6 DIRECTIONAL GRADIENT
  
  for(int coordIx=0; coordIx<3; coordIx++){
        vec3 diffDir = vec3(0);
        diffDir[coordIx] = 1.0f / float(texSize * 4);
        gradient[coordIx] += 
          ( sampleTexAt(pos+diffDir)
          - sampleTexAt(pos-diffDir) );
  }
  
  
  /*
  //3 DIRECTIONAL GRADIENT
  float intensity = sampleTexAt(pos);
  float diff = vexelDistance / 2.0f;
  for(int coordIx=0; coordIx<3; coordIx++){
        vec3 diffDir = vec3(0);
        diffDir[coordIx] = diff;
        gradient[coordIx] = (sampleTexAt(pos+diffDir) - intensity );
  }
  */
  
  
  return -normalize(gradient);
}

vec3 calcPhong_directional(vec3 pos, vec3 rayDir, vec3 normalDir){
  vec3 lightDir = normalize(vec3(1,1,1));
  vec3 lightRef = normalize( 2.0f * dot(lightDir , normalDir) * lightDir - lightDir );
  return ambientCol * ambRef 
    + 0.5f * max(dot( lightDir , normalDir ),0.0) * diffCol
    + 0.5f * pow(dot( lightRef , -rayDir ),shininess) * vec3(1,1,1) ;
}

vec3 calcPhong_point(vec3 pos, vec3 rayDir, vec3 normalDir){
  vec3 lightDir = normalize(lightPos-pos);
  vec3 lightRef = normalize( 2.0f * dot(lightDir , normalDir) * lightDir - lightDir );
  return ambientCol * ambRef 
    + diffRef * max(dot( lightDir , normalDir ),0.0) * diffCol
    + specRef * pow(dot( lightRef , -rayDir ),shininess) * specCol / pow(length(pos-lightPos),2.0f) ;
}

bool isInShadow(vec3 pos){
  //return false;
  vec3 lightDir = normalize(vec3(1,1,1));
  vec3 rayPos = pos + lightDir * stepLength;
  for(int i =0 ; i < limit ;i++){
    if(isInsideAt(rayPos))
      return true;
    else if(length(rayPos)>1.5f) //Kihasznalva, hogy a textura a (0,0,0) -> (1,1,1) koordinatakon van es a feny a (3,3,3)-ban
      return false;
    else{
      rayPos += lightDir * stepLength;
    }
    
  }
  return false;
}


vec4 calcMatcap(vec3 pos){
  return texture(scene.matcap, calcGradient(pos).xy / 2.0 + vec2(0.5f,0.5f));
}



float includedAngle(vec3 normalDir, vec3 rayDir){
  float sin = length( normalDir-rayDir ) /2.0f;
  float angle = asin(sin)*2.0f;
  if(angle > M_PI / 2.0f)
    angle = M_PI - angle;
  return angle;
}

float alphaBasedOnAngle(float angle){
  return angle / M_PI;
}


vec4 addColors(vec4 frontCol, vec4 backCol){
  float alpha = 1.0f - (1.0f - frontCol[3]) * (1.0f - backCol[3]); // alpha
  vec3 frontComponent = frontCol.xyz * frontCol[3] / alpha;
  vec3 backComponent = backCol.xyz * backCol[3] * (1.0f - frontCol[3]) / alpha;
  return vec4( backComponent + frontComponent, alpha );
}


int calcLevel(vec3 rayPos){
  return min(int(sampleTexAt( rayPos )/levelStep),3);
}


vec4 box_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  return addColors(vec4(enterPos,0.5f),vec4(leavePos,1.0f));
}

vec4 intersect_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const int detail = 4;
  vec3 stepVec = rayDir3 / float(texSize*detail)/max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z)));
  int stepLimit = int( leaveDistance / length(stepVec) );
  bool found = false;
  for(int i=0; i < stepLimit ; i++){
    if(isInsideAt(rayPos)){
      found = true;
      break;
    }
    rayPos += stepVec;
  }
  
  if(found)
    return vec4(1,0,0,1);
  else 
    return backGroundCol;
}

vec4 position_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const int detail = 4;
  vec3 stepVec = rayDir3 / float(texSize*detail)/max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z)));
  int stepLimit = int( leaveDistance / length(stepVec) );
  bool found = false;
  for(int i=0; i < stepLimit ; i++){
    if(isInsideAt(rayPos)){
      found = true;
      break;
    }
    rayPos += stepVec;
  }
  
  
  if(!found)
    return backGroundCol;
  
  
  for(int j=0; j < 4 ; j++){
    stepVec/=2.0f;
      if(isInsideAt(rayPos-stepVec))
        rayPos -= stepVec;
    } 

  return vec4(rayPos,1);
}

vec4 gradient_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const float detail = 2.0f;
  vec3 stepVec = rayDir3 * vexelDistance / (detail * max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z))));
  int stepLimit = int( leaveDistance / length(stepVec) );
  bool found = false;
  for(int i=0; i < stepLimit ; i++){
    if(isInsideAt(rayPos)){
      found = true;
      break;
    }
    rayPos += stepVec;
  }
  
  if(!found)
    return backGroundCol;
  
  
  for(int j=0; j < 4 ; j++){
    stepVec/=2.0f;
      if(isInsideAt(rayPos-stepVec))
        rayPos -= stepVec;
    }
   
           
  vec3 gradient = calcGradient(rayPos);
  return vec4(abs(gradient),1);
}

vec4 phong_directional_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const float detail = 2.0f;
  vec3 stepVec = rayDir3 * vexelDistance / (detail * max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z))));
  int stepLimit = int( leaveDistance / length(stepVec) );
  bool found = false;
  for(int i=0; i < stepLimit ; i++){
    if(isInsideAt(rayPos)){
      found = true;
      break;
    }
    rayPos += stepVec;
  }
  
  if(!found)
    return backGroundCol;
  
  
  for(int j=0; j < 4 ; j++){
    stepVec/=2.0f;
      if(isInsideAt(rayPos-stepVec))
        rayPos -= stepVec;
    }
   
           
  vec3 gradient = calcGradient(rayPos);
  return vec4(calcPhong_directional(rayPos, rayDir3, gradient),1);
}

vec4 phong_point_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const float detail = 2.0f;
  vec3 stepVec = rayDir3 * vexelDistance / (detail * max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z))));
  int stepLimit = int( leaveDistance / length(stepVec) );
  bool found = false;
  for(int i=0; i < stepLimit ; i++){
    if(isInsideAt(rayPos)){
      found = true;
      break;
    }
    rayPos += stepVec;
  }
  
  if(!found)
    return backGroundCol;
  
  
  for(int j=0; j < 4 ; j++){
    stepVec/=2.0f;
      if(isInsideAt(rayPos-stepVec))
        rayPos -= stepVec;
    }
   
           
  vec3 gradient = calcGradient(rayPos);
  return vec4(calcPhong_point(rayPos, rayDir3, gradient),1);
}

vec4 matcap_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const float detail = 2.0f;
  vec3 stepVec = rayDir3 * vexelDistance / (detail * max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z))));
  int stepLimit = int( leaveDistance / length(stepVec) );
  bool found = false;
  for(int i=0; i < stepLimit ; i++){
    if(isInsideAt(rayPos)){
      found = true;
      break;
    }
    rayPos += stepVec;
  }
  
  if(!found)
    return backGroundCol;
  
  
  for(int j=0; j < 4 ; j++){
    stepVec/=2.0f;
      if(isInsideAt(rayPos-stepVec))
        rayPos -= stepVec;
    }
   
  return calcMatcap(rayPos);
}

vec4 onion_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  surfaceCols[0] = vec3(1,0,0);
  surfaceCols[1] = vec3(0,1,0);
  surfaceCols[2] = vec3(0,0,1);
  
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const float detail = 2.0f;
  vec3 stepVec = rayDir3 * vexelDistance / (detail * max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z))));
  int stepLimit = int( leaveDistance / length(stepVec) );
  int maxLevel =0;
  int level = 0;
  vec4 sumCol = vec4(0,0,0,0.0001f);
  for(int i=0; i < stepLimit ; i++){
    int newLevel = calcLevel(rayPos);
    if(newLevel != level){
      if( newLevel > maxLevel )
        maxLevel=newLevel;
      vec3 normalDir = calcGradient(rayPos);
      float angle = includedAngle(normalDir, rayDir3);
      float alpha = alphaBasedOnAngle(angle);
      if(newLevel > level)
        sumCol = addColors( sumCol, vec4( surfaceCols[level], alpha ) );
      else
        sumCol = addColors( sumCol, vec4( surfaceCols[newLevel], alpha ) );
      

      level = newLevel;
    }
    rayPos += stepVec;
  }
   
  return addColors( sumCol, backGroundCol );
}

vec4 shadow_shader(vec3 rayDir3, vec3 eyePos, vec3 enterPos, vec3 leavePos, float leaveDistance){
  //RAY PARAMETERS
  vec3 rayPos = enterPos;
  const float detail = 2.0f;
  vec3 stepVec = rayDir3 * vexelDistance / (detail * max(abs(rayDir3.x),max(abs(rayDir3.y),abs(rayDir3.z))));
  int stepLimit = int( leaveDistance / length(stepVec) );
  bool found = false;
  
  for(int i=0; i < stepLimit ; i++){
    if(isInsideAt(rayPos)){
      found = true;
      break;
    }
    rayPos += stepVec;
  }
  
  if(!found)
    return backGroundCol;
  
  
  for(int j=0; j < 2 ; j++){
    stepVec/=2.0f;
      if(isInsideAt(rayPos-stepVec))
        rayPos -= stepVec;
    }

  if(isInShadow(rayPos)){
    return vec4(0,0,0,1);
  }
   
           
  vec3 gradient = calcGradient(rayPos);
  return vec4(calcPhong_directional(rayPos, rayDir3, gradient),1);
}

void main(void) {
 //INPUT DATA
  vec3 rayDir3 = normalize(rayDir.xyz);
  vec3 eyePos = (camera.eyePos.xyz + vec3(0.5,0.5,2.0) );
  vec3 enterPos = intersectBox( eyePos, rayDir3, true);
  vec3 leavePos = intersectBox( eyePos, rayDir3, false);
  float leaveDistance = length(leavePos-eyePos);

  if(eyePos == enterPos){
    fragmentColor = backGroundCol;
    return;
  }

  if(camera.mode == BOX_MODE){
    fragmentColor = box_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == INTERSECT_MODE){
    fragmentColor = intersect_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == POSITION_MODE){
    fragmentColor = position_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == GRADIENT_MODE){
    fragmentColor = gradient_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == PHONG_DIRECTIONAL_MODE){
    fragmentColor = phong_directional_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == PHONG_POINT_MODE){
    fragmentColor = phong_point_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == MATCAP_MODE){
    fragmentColor = matcap_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == ONION_MODE){
    fragmentColor = onion_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }

  if(camera.mode == SHADOW_MODE){
    fragmentColor = shadow_shader(rayDir3,eyePos,enterPos,leavePos,leaveDistance);
    return;
  }
  
  fragmentColor = backGroundCol;
}