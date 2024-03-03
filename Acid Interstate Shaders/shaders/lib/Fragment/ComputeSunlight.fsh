uniform mat4 shadowModelView;

#if !defined COMPUTESUNLIGHT_FSH
#define COMPUTESUNLIGHT_FSH

#include "/lib/Misc/ShadowBias.glsl"

float GetLambertianShading(vec3 normal) {
	return clamp01(dot(normal, lightVector));
}

float GetLambertianShading(vec3 normal, vec3 lightVector, Mask mask) {
	float shading = clamp01(dot(normal, lightVector));
	      shading = mix(shading, 1.0, mask.translucent);
	
	return shading;
}

#if SHADOW_TYPE == 2 && defined composite1
	float ComputeShadows(vec3 shadowPosition, float biasCoeff) {
		float spread = (1.0 - biasCoeff) / shadowMapResolution;
		
		cfloat range       = 1.0;
		cfloat interval    = 1.0;
		cfloat sampleCount = pow(range / interval * 2.0 + 1.0, 2.0);
		
		float sunlight = 0.0;
		
		for (float y = -range; y <= range; y += interval)
			for (float x = -range; x <= range; x += interval)
				sunlight += shadow2D(shadow, vec3(shadowPosition.xy + vec2(x, y) * spread, shadowPosition.z)).x;
		
		return sunlight / sampleCount;
	}
#else
	#define ComputeShadows(shadowPosition, biasCoeff) shadow2D(shadow, shadowPosition).x
#endif

vec4 toShadowClipSpace(in vec3 feetPlayerPos) {
	vec3 shadowViewPos = (shadowView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
	return shadowClipPos;
}

float ComputeSunlight(vec3 worldSpacePosition, float sunlightCoeff) {
	if (sunlightCoeff <= 0.0) return sunlightCoeff;
	
	float distCoeff = GetDistanceCoeff(worldSpacePosition);
	
	//if (distCoeff >= 1.0) return sunlightCoeff;
	
	float biasCoeff;
	
	//vec3 shadowPosition = BiasShadowProjection(projMAD(shadowProjection, transMAD(shadowViewMatrix, worldSpacePosition + gbufferModelViewInverse[3].xyz)), biasCoeff) * 0.5 + 0.5;
	
	//vec3 shadowPosition = BiasShadowProjection(projMAD(shadowProjection, transMAD(shadowViewMatrix, worldSpacePosition + gbufferModelViewInverse[3].xyz)), biasCoeff) * 0.5 + 0.5;
	//vec4 shadowClipPosition = toShadowClipSpace(worldSpacePosition.xyz);
	//vec3 shadowPosition = shadowClipPosition.xyz / shadowClipPosition.w;
	//shadowPosition = shadowPosition * 0.5 + 0.5;

	

	vec4 shadowPosition = (shadowView * vec4(worldSpacePosition, 1.0));
	
	shadowPosition = shadowProjection * shadowPosition;
	shadowPosition.xyz = shadowPosition.xyz * 0.5 + 0.5;
	shadowPosition.z -= 0.001; // lazy ass shadow bias

	//vec3 shadowPosition = BiasShadowProjection(shadowProjection * (shadowModelView * vec4(worldSpacePosition, 1.0)), biasCoeff);

	if (any(greaterThan(abs(shadowPosition.xyz - 0.5), vec3(0.5)))) return sunlightCoeff;
	
	float sunlight = ComputeShadows(shadowPosition.xyz, biasCoeff);
	      sunlight = mix(sunlight, 1.0, distCoeff);
	
	return sunlightCoeff * pow(sunlight, mix(2.0, 1.0, clamp01(length(worldSpacePosition) * 0.1)));
}

#endif
