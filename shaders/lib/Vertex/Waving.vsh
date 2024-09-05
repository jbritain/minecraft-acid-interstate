vec3 GetWavingGrass(vec3 position, cbool doubleTall) {
#ifndef WAVING_GRASS
	return vec3(0.0);
#endif
	
	bool topVert  = texcoord.t < mc_midTexCoord.t;
	bool topBlock = mc_Entity.x == 2009;
	
	float magnitude  = vertLightmap.g;
	
	if (doubleTall) magnitude *= mix(mix(0.0, 0.6, topVert), mix(0.6, 1.2, topVert), topBlock);
	else            magnitude *= float(topVert);
	
	vec3 wave = vec3(0.0);
	
	cfloat speed = 1.0;
	
	float intensity = sin((TIME * 20.0 * PI / (28.0)) + position.x + position.z) * 0.1 + 0.1;
	
	float d0 = sin(TIME * 20.0 * PI / (122.0 * speed)) * 3.0 - 1.5 + position.z;
	float d1 = sin(TIME * 20.0 * PI / (152.0 * speed)) * 3.0 - 1.5 + position.x;
	float d2 = sin(TIME * 20.0 * PI / (122.0 * speed)) * 3.0 - 1.5 + position.x;
	float d3 = sin(TIME * 20.0 * PI / (152.0 * speed)) * 3.0 - 1.5 + position.z;
	
	wave.x += sin((TIME * 20.0 * PI / (28.0 * speed)) + (position.x + d0) * 0.1 + (position.z + d1) * 0.1) * intensity;
	wave.z += sin((TIME * 20.0 * PI / (28.0 * speed)) + (position.z + d2) * 0.1 + (position.x + d3) * 0.1) * intensity;
	
	return wave * magnitude;
}

vec3 GetWavingLeaves(vec3 position) {
#ifndef WAVING_LEAVES
	return vec3(0.0);
#endif
	
	vec3 wave = vec3(0.0);
	
	float speed = 1.0;

	//speed += mix(0.0, 0.5, thunderStrength);
	
	float intensity = (sin(((position.y + position.x) * 0.5 + TIME * PI / ((88.0)))) * 0.05 + 0.15) * 0.35;
	
	float d0 = sin(TIME * 20.0 * PI / (122.0 * speed)) * 3.0 - 1.5;
	float d1 = sin(TIME * 20.0 * PI / (152.0 * speed)) * 3.0 - 1.5;
	float d2 = sin(TIME * 20.0 * PI / (192.0 * speed)) * 3.0 - 1.5;
	float d3 = sin(TIME * 20.0 * PI / (142.0 * speed)) * 3.0 - 1.5;
	
	wave.x += sin((TIME * 20.0 * PI / (16.0 * speed)) + (position.x + d0) * 0.5 + (position.z + d1) * 0.5 + position.y) * intensity;
	wave.z += sin((TIME * 20.0 * PI / (18.0 * speed)) + (position.z + d2) * 0.5 + (position.x + d3) * 0.5 + position.y) * intensity;
	wave.y += sin((TIME * 20.0 * PI / (10.0 * speed)) + (position.z + d2)       + (position.x + d3)                   ) * intensity * 0.5;
	
	return wave * vertLightmap.g;
}

vec3 GetWavingWater(vec3 position) {
#ifndef WAVING_WATER
	return vec3(0.0);
#endif
	
	vec3 wave = vec3(0.0);
	
	float dist = distance(position.xz, cameraPos.xz);
	
	float waveHeight = max0(0.06 / max(dist / 10.0, 1.0) - 0.006);
	
	wave.y  = waveHeight * sin(PI * (TIME / 2.1 + position.x / 7.0  + position.z / 13.0));
	wave.y += waveHeight * sin(PI * (TIME / 1.5 + position.x / 11.0 + position.z / 5.0 ));
	wave.y -= waveHeight;
	
#if !defined gbuffers_shadow
//	wave.y *= float(position.y - floor(position.y) > 0.15 || position.y - floor(position.y) < 0.005);
#endif
	
	return wave;
}

#include "/UserProgram/Terrain_Deformation.vsh"
