#if !defined CALCULATEFOGFACTOR_GLSL
#define CALCULATEFOGFACTOR_GLSL

#ifndef PORTALS_INCLUDED
	#include "/acid/portals.glsl"
#define PORTALS_INCLUDED
#endif

//#define FOG_ENABLED
#define FOG_POWER 1.5 // [1.0 1.5 2.0 3.0 4.0 6.0 8.0]
#define FOG_START 0.2 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8]

float CalculateFogfactor(vec3 position) {
#ifndef FOG_ENABLED
	return 0.0;
#endif
	
	#define PORTALFOG
	vec3 useless = vec3(0);
	float fogfactor  = length(position) / (far * 0.5);//getPortalDistances(cameraPosition.x));
		  fogfactor  = clamp01(fogfactor - FOG_START) / (1.0 - FOG_START);
		  fogfactor  = pow(fogfactor, FOG_POWER);
		  fogfactor  = clamp01(fogfactor);
	#undef PORTALFOG
	return fogfactor;
}

#endif
