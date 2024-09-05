
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
  float p1RotationIntensity = 0;
  float p1SinIntensity = 2.0;
  float p1SinStretchIntensity = 0;

  incrementIntensityAfterX(11 * 64, cameraPosition.x, 0.5, p1RotationIntensity, 64, 0);
  incrementIntensityAfterX(12 * 64, cameraPosition.x, 10.0, p1SinStretchIntensity, 512, 0);
  incrementIntensityAfterX(17 * 64, cameraPosition.x, -1.0, p1RotationIntensity, 3 * 64, 2);

  incrementIntensityBeforeX(2304.5, cameraPosition.x, -2.0, p1SinIntensity, 3 * 64, 2);
  incrementIntensityBeforeX(2304.5, cameraPosition.x, 0.5, p1RotationIntensity, 3 * 64, 2);

  doSinAlongX(position, p1SinIntensity, p1SinStretchIntensity, 0, 2304.5, cameraPosition.x);
  doRotationEffect(position, p1RotationIntensity, 2.0, 0, 2304.5, cameraPosition.x);



  float p2Intensity = 0.0;

  incrementIntensityAfterX(2304.5, cameraPosition.x, 1.0, p2Intensity, 4 * 64, 2);
  incrementIntensityBeforeX(3808.5, cameraPosition.x, -1.0, p2Intensity, 4 * 64, 2);

  doWeirdSpiralEffect(position, 100, 1.0, p2Intensity, 2304.5, 3808.5, cameraPosition.x);



  float p3Intensity = 0.0;
  float p3YOffset = -0.5;
  float p3ZOffset = -0.5;

  incrementIntensityAfterX(3808.5, cameraPosition.x, 8.0, p3Intensity, 4 * 64, 0);

  incrementIntensityBeforeX(66 * 64, cameraPosition.x, -8.0, p3Intensity, 2 * 64, 2);
  incrementIntensityAfterX(66 * 64, cameraPosition.x, -8.0, p3Intensity, 4 * 64, 0);

  incrementIntensityBeforeX(69.5 * 64, cameraPosition.x, 8.0, p3Intensity, 2 * 64, 2);
  incrementIntensityAfterX(69.5 * 64, cameraPosition.x, 8.0, p3Intensity, 4 * 64, 0);

  doSpiralEffect(position, p3Intensity, p3YOffset, p3ZOffset, 3808.5, 5376.5, cameraPosition.x);
}