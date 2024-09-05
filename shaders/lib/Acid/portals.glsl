#ifndef PORTALS_GLSL
#define PORTALS_GLSL

#include "/lib/Misc/Euclid.glsl"

// HERE YOU SHOULD PUT THE X COORDINATES OF YOUR PORTALS
const float[3] portals = float[3](
  2304.5,
  3808.5,
  5376.5
);

float getNearestPortalX(float x, out float nearestDistance){
  float nearestPortalX = portals[portals.length() - 1];
  nearestDistance = abs(x - nearestPortalX);
  
  for(int i = 0; i < portals.length(); i++){
    float distance = abs(x - portals[i]);
    if(distance < nearestDistance){
      nearestDistance = distance;
      nearestPortalX = portals[i];
    }
  }

  return nearestPortalX;
}

float getNearestPortalX(float x){
  float nearestDistance;
  return getNearestPortalX(x, nearestDistance);
}


#ifdef vsh
void doPortals(inout vec3 position, vec3 midblock){
#else
void doPortals(vec3 position, vec3 midblock){
#endif
  for(int i = 0; i < portals.length(); i++){
    doPortal(portals[i], position, midblock);
  }
}

#endif