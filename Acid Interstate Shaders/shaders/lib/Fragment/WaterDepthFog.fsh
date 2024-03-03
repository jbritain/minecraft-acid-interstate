#if !defined WATERDEPTHFOG_FSH
#define WATERDEPTHFOG_FSH

cvec3 waterColor = vec3(0.015, 0.04, 0.098);

vec3 WaterDepthFog(vec3 frontPos, vec3 backPos, io vec3 transmit) {
#ifdef CLEAR_WATER
	return vec3(0.0);
#endif
	
	float fog = -(distance(backPos, frontPos) / 150.0);
	
	vec3 in_scatter = vec3(0.0) * transmit;
	
	transmit *= exp(fog / waterColor);
	
	return in_scatter;
}

#endif
