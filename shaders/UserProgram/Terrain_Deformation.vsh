#if !defined DEFORMATION_GLSL
#define DEFORMATION_GLSL

#include "/lib/Acid/acid.glsl"

vec3 UserDeformation(vec3 position) {
	doAcid(position, cameraPosition);
	return position;
}

vec3 Globe(vec3 position, cfloat radius) {
	position.y -= length2(position.xz) / radius;
	
	return position;
}

vec3 Acid(vec3 position) {
	position.zy = rotate(position.zy, sin(length2(position.xz) * 0.00005) * 0.8);
	
	return position;
}

vec3 AnimalCrossing(vec3 position){
	position.y -= min(length2(position.xz) / 20, 20);
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
		
	#elif DEFORMATION == 3

		position = AnimalCrossing(position);

	#else
		
		position = UserDeformation(position);
		
	#endif
	
	#if !defined gbuffers_shadow
		position -= gbufferModelViewInverse[3].xyz;
	#endif
	
#endif
	
	return position;
}

#endif
