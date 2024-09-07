#include "/lib/acid/helpers.glsl"

float timeTransition(float startTime, float endTime, float startX, float endX, float X, bool ease){
  float dist = mix(0.0, 1.0, (X - startX) / (endX - startX));

  if(ease){
    dist = easeCubicInOut(dist);
  }

  return (dist * (endTime - startTime)) + startTime;
}

// HERE YOU SHOULD PUT YOUR TIME OVERRIDE CODE
float getTime(float x){
  return timeTransition(-500, 12000, 0, 3737, cameraPosition.x, false);
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