#include "/acid/helpers.glsl"
#include "/acid/effects.glsl"

 // modifies an intensity value by adding the increment to it
 // with a cubic transition which happens BEFORE the transition point over a specified distance
void incrementIntensityBeforeX(in float startX, in float playerX, in float increment, inout float intensity, in float transitionDistance, in int easingMode){
  float enableMultiplier = 0;
  enableMultiplier += clamp(ceil(playerX - (startX - transitionDistance)), 0.0, 1.0);
  float distanceAlongTransition = 0;
  
  switch (easingMode) {
    case 0:
      distanceAlongTransition = easeCubicOut(1.0 - clamp((startX - playerX)/transitionDistance, 0.0, 1.0));
      break;
    case 1:
      distanceAlongTransition = easeCubicIn(1.0 - clamp((startX - playerX)/transitionDistance, 0.0, 1.0));
      break;
    case 2:
      distanceAlongTransition = easeCubicInOut(1.0 - clamp((startX - playerX)/transitionDistance, 0.0, 1.0));
      break;
  }

  intensity = intensity + enableMultiplier * clamp(increment * distanceAlongTransition, -increment, increment);
}

 // modifies an intensity value by adding the increment to it
 // with a cubic transition which happens AFTER the transition point over a specified distance
 // easing mode 0 is ease out, 1 is ease in, 2 is ease in out
void incrementIntensityAfterX(in float startX, in float playerX, in float increment, inout float intensity, in float transitionDistance, in int easingMode){
  float enableMultiplier = 0;
  enableMultiplier += clamp(ceil(playerX - (startX - transitionDistance)), 0.0, 1.0);

  float distanceAlongTransition = 0;

  switch (easingMode) {
    case 0: 
      distanceAlongTransition = easeCubicOut(clamp((playerX - startX) / transitionDistance, 0.0, 1.0));
      break;
    case 1:
      distanceAlongTransition = easeCubicIn(clamp((playerX - startX) / transitionDistance, 0.0, 1.0));
      break;
    case 2:
      distanceAlongTransition = easeCubicInOut(clamp((playerX - startX) / transitionDistance, 0.0, 1.0));
      break;
  }
  

  intensity = intensity + enableMultiplier * clamp(increment * distanceAlongTransition, -increment, increment);
}


void doAcid(inout vec3 position, in vec3 playerPos){

  float intensity1 = 0;
  float intensity2 = 0;
  float intensity3 = 0;
  float intensity4 = 0;

  

}