float GetNoise(vec2 coord) {
	cvec2 madd = vec2(0.5 * noiseResInverse);
	vec2 whole = floor(coord);
	coord = whole + cubesmooth(coord - whole);
	
	return texture(noisetex, coord * noiseResInverse + madd).x;
}

vec2 GetNoise2D(vec2 coord) {
	cvec2 madd = vec2(0.5 * noiseResInverse);
	vec2 whole = floor(coord);
	coord = whole + cubesmooth(coord - whole);
	
	return texture(noisetex, coord * noiseResInverse + madd).xy;
}

float GetCoverage(float clouds, float coverage) {
	return cubesmooth(clamp01((coverage + clouds - 1.0) * 1.1 - 0.1));
}

float CloudFBM(vec2 coord, out mat4x2 c, vec3 weights, float weight) {
	float time = CLOUD2D_SPEED * TIME * 0.01;
	
	c[0]    = coord * 0.007;
	c[0]   += GetNoise2D(c[0]) * 0.3 - 0.15;
	c[0].x  = c[0].x * 0.25 + time;
	
	float cloud = -GetNoise(c[0]);
	
	c[1]    = c[0] * 2.0 - cloud * vec2(0.5, 1.35);
	c[1].x += time;
	
	cloud += GetNoise(c[1]) * weights.x;
	
	c[2]  = c[1] * vec2(9.0, 1.65) + time * vec2(3.0, 0.55) - cloud * vec2(1.5, 0.75);
	
	cloud += GetNoise(c[2]) * weights.y;
	
	c[3]   = c[2] * 3.0 + time;
	
	cloud += GetNoise(c[3]) * weights.z;
	
	cloud  = weight - cloud;
	
	cloud += GetNoise(c[3] * 3.0 + time) * 0.022;
	cloud += GetNoise(c[3] * 9.0 + time * 3.0) * 0.014;
	
	return cloud * 0.7;
}

vec3 Compute2DCloudPlane(vec3 wDir, vec3 wPos, vec3 transmit, float phase) {
#ifndef CLOUD2D
	return vec3(0.0);
#endif
	
	cfloat cloudHeight = CLOUD2D_HEIGHT;
	
	wPos += cameraPos;
	
	if (wDir.y <= 0.0 != wPos.y >= cloudHeight) return vec3(0.0);
	
	
	float coverage = CLOUD2D_COVERAGE * 1.16;
	coverage = mix(coverage, 1.0, biomePrecipness);
	cvec3  weights  = vec3(0.5, 0.135, 0.075);
	cfloat weight   = weights.x + weights.y + weights.z;
	
	vec2 coord = wDir.zx * ((cloudHeight - wPos.y) / wDir.y) + wPos.zx;
	vec3 RAY = wDir * ((cloudHeight - wPos.y) / wDir.y);
	
	mat4x2 coords;
	
	float cloudAlpha = CloudFBM(coord, coords, weights, weight);
	cloudAlpha = GetCoverage(cloudAlpha, coverage);
	//cloudAlpha = mix(cloudAlpha, 0.1, biomePrecipness);
	// cloudAlpha = GetCoverage(cloudAlpha, coverage) * sqrt(abs(wDir.y)) ;
	
	vec2 lightOffset = worldLightVector.xz * 0.2;
	
	float sunlight;
	sunlight  = -GetNoise(coords[0] + lightOffset)            ;
	sunlight +=  GetNoise(coords[1] + lightOffset) * weights.x;
	sunlight +=  GetNoise(coords[2] + lightOffset) * weights.y;
	sunlight +=  GetNoise(coords[3] + lightOffset) * weights.z;
	sunlight  = GetCoverage(weight - sunlight, coverage);
	sunlight  = pow(1.3 - sunlight, 5.5);
	sunlight *= phase ;
	sunlight *= 1000.0;
	sunlight = mix(sunlight, sunlight / 4, biomePrecipness);
	
	float direct  = mix(1.0, 5.0, timeNight);
	float ambient = 5.0;
	
	vec3 directColor  = sunlightColor * direct;
	vec3 ambientColor = mix(skylightColor, sunlightColor, 0.15) * ambient;
	
	vec3 cloud = (ambientColor + directColor * sunlight) * 10.0 * cloudAlpha;
	
#ifdef PRECOMPUTED_ATMOSPHERE
//	PrecomputedSkyToPoint(kCamera, kPoint(RAY*5.0), 0.0, sunVector, transmit);
	transmit *= sqrt(abs(wDir.y));
#else
	transmit *= sqrt(abs(wDir.y));
#endif
	
	return cloud * transmit;
}
