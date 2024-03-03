#ifndef HELPERS_INCLUDED
#include "/acid/helpers.glsl"
#define HELPERS_INCLUDED
#endif
float timeTransition(float startTime, float endTime, float startX, float endX, float X, bool ease){
  float dist = mix(0.0, 1.0, (X - startX) / (endX - startX));

  if(ease){
    dist = easeCubicInOut(dist);
  }

  return (dist * (endTime - startTime)) + startTime;
}

float getTime(float x){
  if (x < 1120) {
    return timeTransition(-1000, 0, 0, 1120, x, false);
  } else if (x < 1632) {
    return timeTransition(0, 6000, 1120, 1632, x, true);
  } else if (x < 3360) {
    return 6000;
  } else if (x < 4480) {
    return timeTransition(6000, 12000, 3360, 4480, x, false);
  } else if (x < 5600) {
    return timeTransition(12000, 24000, 4480, 5600, x, false);
  } else if (x < 7840) {
    return timeTransition(0, 12000, 5600, 7840, x, false);
  } else if (x < 10067) {
    return timeTransition(12000, 30000, 7840, 10067, x, false);
  } else if (x < 12288) {
    return timeTransition(6000, 12000, 10067, 12288, x, false);
  } else if (x < 13056) {
    return timeTransition(12000, 18000, 12288, 13056, x, false);
  }

  return 18000;
}

// as featured in #snippets in shaderLABS
float getTimeAngle(float time){
  time += 6000;
  //minecraft's native calculateCelestialAngle() function, ported to GLSL.
  float ang = fract(time / 24000.0 - 0.25);
  ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959; //0-2pi, rolls over from 2pi to 0 at noon.
  ang = (ang / 3.14159265358979) * 180; // convert to degrees

  return ang;
}