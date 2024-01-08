#version 120

#define VSH

#define gbuffers_shadows
#include "shaders.settings"
#include "/acid/acid.glsl"
#include "/acid/portals.glsl"

varying vec3 worldpos;
uniform vec3 cameraPosition;
attribute vec3 at_midBlock;
out vec3 originalPosition;
out vec3 originalWorldSpacePosition;
out vec3 originalBlockCentre;
out vec3 newPosition;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;

#ifdef Shadows
varying vec4 texcoord;
attribute vec4 mc_Entity;

vec2 calcShadowDistortion(in vec2 shadowpos) {
  float distortion = log(length(shadowpos.xy)*b+a)*k;
  return shadowpos.xy / distortion;
}
#endif

vec3 toPlayerSpace(in vec4 shadowClipPos) {
	vec3 shadowViewPos = (shadowProjectionInverse * shadowClipPos).xyz;
	vec3 feetPlayerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
	return feetPlayerPos;
}

vec4 toShadowClipSpace(in vec3 feetPlayerPos) {
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
	return shadowClipPos;
}

void main() {

	vec4 position = gl_ModelViewProjectionMatrix * gl_Vertex;

	vec3 playerPos = toPlayerSpace(position);
	worldpos = playerPos.xyz + cameraPosition;

	originalPosition = playerPos.xyz;
	originalWorldSpacePosition = worldpos.xyz;
	originalBlockCentre = worldpos.xyz + (at_midBlock / 64);
	
	doPortals(playerPos.xyz, worldpos.xyz, cameraPosition, originalBlockCentre);
	newPosition = playerPos.xyz;
	//doAcid(playerPos.xyz, cameraPosition);

	position = toShadowClipSpace(playerPos);

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