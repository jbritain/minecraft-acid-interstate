
#include "/lib/Acid/helpers.glsl"
 // modifies an intensity value by adding the increment to it
 // with a cubic transition which happens BEFORE the transition point over a specified distance
void incrementIntensityBeforeX(in float startX, in float playerX, in float increment, inout float intensity, in float transitionDistance, in int easingMode){
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

  intensity = intensity + clamp(increment * distanceAlongTransition, -abs(increment), abs(increment));
}

 // modifies an intensity value by adding the increment to it
 // with a cubic transition which happens AFTER the transition point over a specified distance
 // easing mode 0 is ease out, 1 is ease in, 2 is ease in out
void incrementIntensityAfterX(in float startX, in float playerX, in float increment, inout float intensity, in float transitionDistance, in int easingMode){

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
  

  intensity += clamp(increment * distanceAlongTransition, -abs(increment), abs(increment));
}

#include "/lib/Acid/effects.glsl"


// HERE YOU SHOULD PUT YOUR ACID/DEFORM CODE
void doAcid(inout vec3 position, in vec3 playerPos){
  doRotationEffect(position, 0.5, 1.0, 0.0, 999999.0, 1.0);
}