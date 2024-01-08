#version 120

#define gbuffers_shadows
#include "shaders.settings"

#ifdef Shadows
varying vec4 texcoord;
attribute vec4 mc_Entity;

vec2 calcShadowDistortion(in vec2 shadowpos) {
  float distortion = log(length(shadowpos.xy)*b+a)*k;
  return shadowpos.xy / distortion;
}
#endif

void main() {

vec4 position = gl_ModelViewProjectionMatrix * gl_Vertex;

#ifdef Shadows
	position.xy = calcShadowDistortion(position.xy);
	position.z /= 6.0;

	texcoord.xy = (gl_MultiTexCoord0).xy;
	texcoord.z = 0.0;
	texcoord.w = 0.0;
	if(mc_Entity.x == 10008.0) texcoord.z = 1.0;
	#ifndef grass_shadows
	if(mc_Entity.x == 10031.0 || mc_Entity.x == 10059.0 || mc_Entity.x == 10175.0 || mc_Entity.x == 10176.0) texcoord.w = 1.0;
	#endif
#endif	
	gl_Position = position;
}
