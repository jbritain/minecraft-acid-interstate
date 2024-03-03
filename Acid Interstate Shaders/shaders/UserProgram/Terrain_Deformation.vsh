
#ifndef ACID_INCLUDED
	#include "/acid/acid.glsl"
	#define ACID_INCLUDED
#endif
#ifndef PORTALS_INCLUDED
	#include "/acid/portals.glsl"
	#define PORTALS_INCLUDED
#endif

attribute vec3 at_midBlock;
out vec3 midblock;

vec3 UserDeformation(vec3 position) {

	#ifndef gbuffers_shadow
		midblock = at_midBlock;
		//doPortals(position.xyz, cameraPosition.xyz, at_midBlock);
		doAcid(position.xyz, cameraPosition.xyz);
	#endif
	return position;
}

vec3 Globe(vec3 position, cfloat radius) {
	position.y -= length2(position.xz) / radius;
	
	return position;
}

vec3 Acid(vec3 position) {
	position.xy = rotate(position.xy, sin(length2(position.xz) * 0.00005) * 0.8);
	
	return position;
}

vec3 TerrainDeformation(vec3 position) {
	
#ifdef DEFORM
	
	#if !defined gbuffers_shadow
		position += gbufferModelViewInverse[3].xyz;
	#endif
	
	#if DEFORMATION == 1
		
		position = Globe(position, 500.0);
		
	#elif DEFORMATION == 2
		
		position = Acid(position);
		
	#else
		
		position = UserDeformation(position);
		
	#endif
	
	#if !defined gbuffers_shadow
		position -= gbufferModelViewInverse[3].xyz;
	#endif
	
#endif
	
	return position;
}
