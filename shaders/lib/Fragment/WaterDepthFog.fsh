#if !defined waterdepthFOG_FSH
#define waterdepthFOG_FSH

vec3 stockWaterColor = pow2(normalize(WATER_COLOR.rgb)) * (EBS * 0.8 + 0.2);
vec3 biomeWaterColor = pow2(normalize(fogColor)) * (EBS * 0.8 + 0.2) * vec3(1.5, 1.3, 1.0);
vec3 waterColor = mix(stockWaterColor, biomeWaterColor, BIOME_WATER_TINT);

vec3 waterdepthFog(vec3 frontPos, vec3 backPos, vec3 color) {
#ifdef CLEAR_WATER
	return color;
#endif
	
	float waterdepth = distance(backPos.xyz, frontPos.xyz); // Depth of the water volume
	
	if (isEyeInWater == 1.0) waterdepth = clamp(length(frontPos), 0, far) * 0.5;
	
	// Beer's Law
	float fogAccum = exp(-3.0 * (waterdepth / far));
	vec3 tint = sunlightColor * (EBS * 0.7 + 0.3);

	#if defined VL_ENABLED
	tint *= (sqrt(VL.y) * 0.7 + 0.3) * sunlightColor;
	#endif

	tint = sqrt(tint * length(tint));

	if(isEyeInWater != 1.0){
		tint = vec3(0.0);
	}

	color *= pow(vec3(0.6, 0.7, 0.8), vec3(waterdepth));
	color = mix(color, waterColor * tint, 1.0 - clamp01(fogAccum));
	return color;
}

#endif
