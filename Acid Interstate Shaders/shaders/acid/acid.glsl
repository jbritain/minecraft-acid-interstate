#ifndef HELPERS_INCLUDED
#include "/acid/helpers.glsl"
#define HELPERS_INCLUDED
#endif
#include "/acid/effects.glsl"

#ifdef vsh
out vec3 preAcidWorldPos;
#endif

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


void doAcid(inout vec3 position, in vec3 playerPos){
  #ifdef vsh
    #ifdef composite1
      return 0;
    #endif

  preAcidWorldPos = position;
  #endif
  //return;

  //doRotationEffect(position, 1, 1, 0, 9999, playerPos.x );

  float intensity1 = 0;
  float intensity2 = 0;
  float intensity3 = 8;
  float intensity4 = 0;
  float intensity5 = 0;

  // synced detail for second part
  if(cameraPosition.x >= 1120 && cameraPosition.x <= 3360){
    incrementIntensityBeforeX(1280, playerPos.x, 2, intensity2, 64, 1);
    incrementIntensityBeforeX(1408, playerPos.x, -2, intensity2, 64, 1);
    incrementIntensityBeforeX(1472, playerPos.x, -2, intensity2, 64, 1);
    incrementIntensityBeforeX(1536, playerPos.x, 2, intensity2, 64, 1);

    incrementIntensityBeforeX(1825, playerPos.x, 2, intensity2, 64, 1);
    incrementIntensityBeforeX(1968, playerPos.x, -2, intensity2, 64, 1);
    incrementIntensityBeforeX(2016, playerPos.x, -2, intensity2, 64, 1);
    incrementIntensityBeforeX(2112, playerPos.x, 2, intensity2, 64, 1);


    incrementIntensityBeforeX(2237, playerPos.x, -2, intensity2, 64, 1);
    incrementIntensityBeforeX(2371, playerPos.x, 4, intensity2, 64, 1);
    incrementIntensityBeforeX(2514, playerPos.x, -4, intensity2, 64, 1);
    incrementIntensityBeforeX(2736, playerPos.x, 2, intensity2, 64, 1);

    incrementIntensityBeforeX(2792, playerPos.x, -2, intensity2, 64, 1);
    incrementIntensityBeforeX(2930, playerPos.x, 4, intensity2, 64, 1);
    incrementIntensityBeforeX(3071, playerPos.x, -4, intensity2, 64, 1);
    incrementIntensityBeforeX(3200, playerPos.x, 2, intensity2, 64, 1);
  }

  // fade in intensity in first part
  incrementIntensityAfterX(256, playerPos.x, 0.5, intensity1, 864, 2);
  incrementIntensityBeforeX(1120, playerPos.x, -5, intensity3, 256, 2);

  // synced rotation for second part
  incrementIntensityAfterX(1472, playerPos.x, -1.0, intensity1, 256, 2);
  incrementIntensityAfterX(2112, playerPos.x, -1.0, intensity1, 256, 2);
  incrementIntensityAfterX(2544, playerPos.x, 3.0, intensity1, 512, 2);
  incrementIntensityBeforeX(3360, playerPos.x, -1.5, intensity1, 512, 1);

  // third part
  incrementIntensityAfterX(3360, playerPos.x, 0.5, intensity1, 512, 0);
  incrementIntensityAfterX(3360, playerPos.x, 2, intensity3, 1120, 2);

  
  // fourth part
  incrementIntensityBeforeX(4480, playerPos.x, 3, intensity3, 256, 2);
  incrementIntensityAfterX(4480, playerPos.x, -1, intensity1, 1120, 2);


  // fifth part
  incrementIntensityBeforeX(6144, playerPos.x, 1, intensity1, 512, 2);
  incrementIntensityBeforeX(6720, playerPos.x, 2, intensity5, 512, 2);
  incrementIntensityBeforeX(7296, playerPos.x, -4, intensity5, 512, 2);

  incrementIntensityBeforeX(7840, playerPos.x, 2, intensity5, 128, 2);
  incrementIntensityBeforeX(7840, playerPos.x, -0.5, intensity1, 128, 2);

  // sixth part
  incrementIntensityAfterX(7840, playerPos.x, 0.25, intensity1, 512, 0);
  incrementIntensityAfterX(8960, playerPos.x, -0.25, intensity1, 512, 0);
  incrementIntensityAfterX(8560, playerPos.x, 10, intensity5, 512, 0);
  incrementIntensityBeforeX(10067, playerPos.x, -10, intensity5, 128, 1);

  // seventh part but acid starts in sixth
  incrementIntensityBeforeX(10323, playerPos.x, 3, intensity4, 512, 1);
  incrementIntensityAfterX(12288, playerPos.x, -3, intensity4, 768, 2);
  incrementIntensityAfterX(12288, playerPos.x, 0.2, intensity1, 768, 2);

  incrementIntensityBeforeX(10624, playerPos.x, -5, intensity2, 256, 1);
  incrementIntensityBeforeX(11200, playerPos.x, 10, intensity2, 256, 1);
  incrementIntensityBeforeX(11824, playerPos.x, -10, intensity2, 256, 1);

  // detail for second part
  doWaveAlongX(position, intensity2, 1120, 3360, playerPos.x);

  // rotation effect in every part lol
  doRotationEffect(position, intensity1, intensity3, 0, 14000, playerPos.x);

  // curve effect in fifth part
  doNewCurveYEffect(position, intensity5, intensity5 * 4, 5600, 7840, playerPos.x);

  // scale effect in sixth part
  doScaleYEffect(position, intensity5, 6000, 10067, playerPos.x);

  // spiral effect in seventh part (starts slightly early)
  doSpiralEffect(position, intensity4, intensity2, intensity2, 9067, 14720, playerPos.x);
}