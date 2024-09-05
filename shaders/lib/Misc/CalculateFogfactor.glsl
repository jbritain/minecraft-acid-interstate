#if !defined CALCULATEFOGFACTOR_GLSL
#define CALCULATEFOGFACTOR_GLSL

#include "/lib/Acid/portals.glsl"

#define FOG_POWER 5.0 // [1.0 1.5 2.0 3.0 4.0 6.0 8.0]
#define FOG_START 0.2 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8]
#ifdef composite2
float fogPower = mix(FOG_POWER, FOG_POWER / 2, biomePrecipness);
#else
cfloat fogPower = FOG_POWER;
#endif

float CalculateFogFactor(vec3 position) {
#ifndef FOG_ENABLED
	return 0.0;
#endif

#ifdef WORLD_THE_END //end
	return 0.0;
#endif
	
	float fogfactor  = smoothstep(0, min(far, PORTAL_RENDER_DISTANCE * 16), length(position));
	float nearestPortalDistance;
	float nearestPortalX = getNearestPortalX(cameraPosition.x, nearestPortalDistance);

	float portalFogFactor = 1.0 - smoothstep(PORTAL_RENDER_DISTANCE / 2, PORTAL_RENDER_DISTANCE, nearestPortalDistance / 16);
			fogfactor *= 1.0 + portalFogFactor;

		  fogfactor  = clamp01(fogfactor - FOG_START) / (1.0 - FOG_START);
		  fogfactor  = pow(fogfactor, FOG_POWER);
		  fogfactor  = clamp01(fogfactor);
	
	return fogfactor;
}

#endif
