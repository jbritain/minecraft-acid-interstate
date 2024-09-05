#if !defined COMPUTEVOLUMETRICLIGHT_FSH
#define COMPUTEVOLUMETRICLIGHT_FSH

vec2 ComputeVolumetricLight(vec3 position, vec3 frontPos, vec2 noise, float waterMask) {
#ifndef VL_ENABLED
	return vec2(0.0);
#endif

#ifndef WORLD_OVERWORLD
	return vec2(0.0);
#endif
	
	cfloat samples = VL_QUALITY;
	float waterSamples = 0;
	vec3 ray = normalize(position);
	
	vec3 shadowStep = diagonal3(shadowProjection) * (mat3(shadowViewMatrix) * ray);
	
	ray = projMAD(shadowProjection, transMAD(shadowViewMatrix, ray + gbufferModelViewInverse[3].xyz));

	vec2 result = vec2(0.0);
	
#ifdef LIMIT_SHADOW_DISTANCE
	float maxDistance = min(length(position), shadowDistance);
#else
	float maxDistance = length(position);
#endif

	maxDistance = min(maxDistance, 128);
	
	float frontLength = length(frontPos);
	
	for(int i = 0; i < samples; i++) {
		float shadow;
		float waterShadow;

		// for a sample count n, distribute each sample in the ith nth of the ray
		// i.e for a sample count of 8, the first sample will be somewhere in the first 8th
		// the second in the second 8th
		// and so on and so forth
		float noise = InterleavedGradientNoise(floor(gl_FragCoord.xy), i);
		vec3 segmentStart = ray + shadowStep * maxDistance * (i/samples);
		vec3 segmentEnd = ray + shadowStep * maxDistance * (i+1)/samples;

		vec3 samplePos = BiasShadowProjection(mix(segmentStart, segmentEnd, noise)) * 0.5 + 0.5;
		// vec3 samplePos = BiasShadowProjection(ray + shadowStep * noise * maxDistance) * 0.5 + 0.5;
		
		#if defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
		float transparentShadow = shadow2D(shadowtex0HW, samplePos).r;
		#else
		float transparentShadow = step(samplePos.z, texture(shadowtex0, samplePos.xy).r);
		#endif

		if(transparentShadow == 1.0){ // no shadow at all
			shadow = 1.0;
		} else {
			#if defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
			float opaqueShadow = shadow2D(shadowtex1HW, samplePos).r;
			#else
			float opaqueShadow = step(samplePos.z, texture(shadowtex1, samplePos.xy).r);
			#endif

			if(opaqueShadow == 0.0){ // only opaque shadow so don't sample opaque shadow map
				shadow = 0.0;
			} else {
				vec4 shadowColorData = texture(shadowcolor0, samplePos.xy);
				shadow = mix(((1.0 - shadowColorData.a) * opaqueShadow), 1.0, transparentShadow);
				waterShadow = shadow;
				waterSamples++;
			}
		}
		
		result += vec2(shadow, waterShadow);
	}
	
	// result = isEyeInWater == 0 ? result.xy : result.yx;
	
	result.x /= samples;
	if(waterSamples != 0){
		result.y /= waterSamples;
	}

	return result;
}

#endif
