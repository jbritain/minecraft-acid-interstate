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

  // ---INTENSITY---
  // PART 1
  incrementIntensityAfterX(0, playerPos.x, -5, intensity1, 0, 0);
  incrementIntensityBeforeX(78, playerPos.x, 5, intensity1, 39, 2);
  incrementIntensityAfterX(176, playerPos.x, 5, intensity1, 160, 0);
  incrementIntensityAfterX(416, playerPos.x, -5, intensity1, 160, 0);
  incrementIntensityAfterX(480, playerPos.x, -5, intensity1, 160, 0);
  incrementIntensityAfterX(592, playerPos.x, 10, intensity1, 360, 2);
  incrementIntensityAfterX(1040, playerPos.x, -5, intensity1, 304, 2);

  // PART 2
    // y axis curve
  incrementIntensityAfterX(1344, playerPos.x, -5, intensity2, 304, 2);
  incrementIntensityAfterX(1344, playerPos.x, 2, intensity1, 144, 0);
  incrementIntensityAfterX(1576, playerPos.x, -4, intensity1, 144, 2);
  incrementIntensityAfterX(1576, playerPos.x, 10, intensity2, 144, 2);
  incrementIntensityAfterX(1792, playerPos.x, 2, intensity1, 144, 2);
  incrementIntensityAfterX(1792, playerPos.x, -5, intensity2, 144, 2);
    // z axis curve

  // PART 3
  incrementIntensityAfterX(1936, playerPos.x, 4, intensity1, 288, 2);
  incrementIntensityAfterX(2080, playerPos.x, -4, intensity1, 304, 2);

  incrementIntensityAfterX(2096, playerPos.x, -4, intensity1, 272, 2);
  incrementIntensityAfterX(2240, playerPos.x, 4, intensity1, 272, 2);

  // PART 4
  incrementIntensityAfterX(2512, playerPos.x, 0.5, intensity2, 300, 2);
  incrementIntensityAfterX(2512, playerPos.x, 1, intensity1, 72, 0);
  incrementIntensityAfterX(2584, playerPos.x, -1, intensity1, 72, 1);

  incrementIntensityAfterX(2656, playerPos.x, 1, intensity1, 80, 0);
  incrementIntensityAfterX(2736, playerPos.x, -1, intensity1, 88, 1);

  incrementIntensityAfterX(2824, playerPos.x, 1, intensity1, 72, 0);
  incrementIntensityAfterX(2896, playerPos.x, -1, intensity1, 80, 1);

  incrementIntensityAfterX(2976, playerPos.x, 1, intensity1, 72, 0);
  incrementIntensityAfterX(3048, playerPos.x, -1, intensity1, 80, 1);
  incrementIntensityAfterX(3048, playerPos.x, -3.5, intensity2, 300, 2);

  // ---DETAILED SIN INTENSITY---

  // ---EFFECT---
  incrementIntensityAfterX(176, playerPos.x, -4, intensity3, 100, 0);
  incrementIntensityAfterX(440, playerPos.x, 8, intensity3, 100, 0);
  incrementIntensityAfterX(480, playerPos.x, -8, intensity3, 100, 0);
  incrementIntensityAfterX(624, playerPos.x, 8, intensity3, 100, 0);
  incrementIntensityAfterX(688, playerPos.x, -8, intensity3, 100, 0);
  incrementIntensityAfterX(976, playerPos.x, 8, intensity3, 100, 0);
  incrementIntensityAfterX(1024, playerPos.x, -4, intensity3, 100, 0);

  
  // PART 1
  doWaveAlongX(position, intensity3, -128, 1344, playerPos.x);
  doRotationEffect(position, intensity1, 0, 0, 1344, playerPos.x);
  // PART 2
  doCurveYEffect(position, intensity1, 0, 0, 1344, 1936, playerPos.x);
  doRotationEffect(position, intensity2, 0, 1344, 1936, playerPos.x);
  // PART 3
  doSpiralEffect(position, intensity1, intensity1 * 2, 10, 1936, 2512, playerPos.x);
  // PART 4
  doRotationEffect(position, intensity2, 0, 2512, 3737, playerPos.x);
  doSquashYEffect(position, intensity1, 2512, 2656, playerPos.x, 0.5);
  doSquashZEffect(position, intensity1, 2656, 2824, playerPos.x, 0);
  doSquashYEffect(position, intensity1, 2824, 2976, playerPos.x, 0.5);
  doSquashZEffect(position, intensity1, 2976, 3128, playerPos.x, 0);

}