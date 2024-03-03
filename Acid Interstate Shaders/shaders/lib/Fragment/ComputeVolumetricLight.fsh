#if !defined COMPUTEVOLUMETRICLIGHT_FSH
#define COMPUTEVOLUMETRICLIGHT_FSH

vec2 ComputeVolumetricLight(vec3 position, vec3 frontPos, vec2 noise, float waterMask) {
#ifndef VOLUMETRIC_LIGHT
	return vec2(0.0);
#endif
	
	vec3 ray = normalize(position);
	
	vec3 shadowStep = diagonal3(shadowProjection) * (mat3(shadowViewMatrix) * ray);
	
	ray = projMAD(shadowProjection, transMAD(shadowViewMatrix, ray + gbufferModelViewInverse[3].xyz));
	
#ifdef LIMIT_SHADOW_DISTANCE
	cfloat maxSteps = min(200.0, shadowDistance);
#else
	cfloat maxSteps = 200.0;
#endif
	
	float end    = min(length(position), maxSteps);
	float count  = 1.0;
	vec2  result = vec2(0.0);
	
	float frontLength = length(frontPos);
	
	while (count < end) {
		result += shadow2D(shadow, BiasShadowProjection(ray) * 0.5 + 0.5).x * mix(vec2(1.0, 0.0), clamp01(vec2(1.0, -1.0) * (frontLength - count++)), waterMask);
		ray += shadowStep;
	}
	
	result = isEyeInWater == 0 ? result.xy : result.yx;
	
	return result / maxSteps;
}

#endif
