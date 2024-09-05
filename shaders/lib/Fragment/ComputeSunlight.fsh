#if !defined COMPUTESUNLIGHT_FSH
#define COMPUTESUNLIGHT_FSH

#include "/lib/Misc/ShadowBias.glsl"
#include "/lib/Acid/portals.glsl"

float noise;

float GetLambertianShading(vec3 normal) {
	return clamp01(dot(normal, worldLightVector));
}

vec2 VogelDiscSample(int stepIndex, int stepCount, float rotation) {
    const float goldenAngle = 2.4;

    float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
    float theta = stepIndex * goldenAngle + rotation;

    return r * vec2(cos(theta), sin(theta));
}

// ask tech, idk
float ComputeSSS(float blockerDistance, float SSS, vec3 normal){
	#ifndef SUBSURFACE_SCATTERING
	return 0.0;
	#endif

	if(SSS < 0.0001){
		return 0.0;
	}

	float nDotL = dot(normal, lightVector);

	if(nDotL > -0.00001){
		return 0.0;
	}

	float s = 1.0 / (SSS * 0.06);
	float z = blockerDistance * 255;

	if(isnan(z)){
		z = 0.0;
	}

	float scatter = 0.25 * (exp(-s * z) + 3*exp(-s * z / 3));

	return clamp01(scatter);
}

vec3 SampleShadow(vec3 shadowClipPos, bool useImageShadowMap){
	float biasCoeff;


	vec3 shadowScreenPos = BiasShadowProjection(shadowClipPos, biasCoeff) * 0.5 + 0.5;

	float shadow;
	if(useImageShadowMap){
		shadow = step(shadowScreenPos.z, texture(portalshadowtex, shadowScreenPos.xy).r);
	} else {
		shadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
	}

	return vec3(shadow);
}

vec3 ComputeShadows(vec3 shadowClipPos, float penumbraWidthBlocks, bool useImageShadowMap){
	#ifndef SHADOWS
	return vec3(1.0);
	#endif

	if(penumbraWidthBlocks == 0.0){
		return(SampleShadow(shadowClipPos, useImageShadowMap));
	}

	float penumbraWidth = penumbraWidthBlocks / shadowDistance;
	float range = penumbraWidth / 2;

	vec3 shadowSum = vec3(0.0);
	int samples = SHADOW_SAMPLES;


	for(int i = 0; i < samples; i++){
		vec2 offset = VogelDiscSample(i, samples, noise);
		shadowSum += SampleShadow(shadowClipPos + vec3(offset * range, 0.0), useImageShadowMap);
	}
	shadowSum /= float(samples);

	return shadowSum;
}

float GetBlockerDistance(vec3 shadowClipPos){
	float biasCoeff;

	float range = float(BLOCKER_SEARCH_RADIUS) / (2 * shadowDistance);

	vec3 receiverShadowScreenPos = BiasShadowProjection(shadowClipPos, biasCoeff) * 0.5 + 0.5;
	float receiverDepth = receiverShadowScreenPos.z;

	float blockerDistance = 0;

	float blockerCount = 0;

	for(int i = 0; i < BLOCKER_SEARCH_SAMPLES; i++){
		vec2 offset = VogelDiscSample(i, BLOCKER_SEARCH_SAMPLES, noise);
		vec3 newShadowScreenPos = BiasShadowProjection(shadowClipPos + vec3(offset * range, 0.0), biasCoeff) * 0.5 + 0.5;
		float newBlockerDepth = texture(shadowtex0, newShadowScreenPos.xy).r;
		if (newBlockerDepth < receiverDepth){
			blockerDistance += (receiverDepth - newBlockerDepth);
			blockerCount += 1;
		}
	}

	if(blockerCount == 0){
		return 0.0;
	}
	blockerDistance /= blockerCount;

	return clamp01(blockerDistance);
}

vec3 ComputeSunlight(vec3 worldSpacePosition, vec3 normal, vec3 geometryNormal, float sunlightCoeff, float SSS, float skyLightmap, bool rightOfPortal) {
	#ifndef WORLD_OVERWORLD
	return vec3(0.0);
	#endif

	float distCoeff = GetDistanceCoeff(worldSpacePosition);

	
	vec3 shadowClipPos = projMAD(shadowProjection, transMAD(shadowViewMatrix, worldSpacePosition + gbufferModelViewInverse[3].xyz));
	vec3 sunlight = vec3(1.0);

	float nearestPortalX = getNearestPortalX(cameraPosition.x);

	bool useImageShadowMap = (
		((cameraPosition.x < nearestPortalX && rightOfPortal) ||
		(cameraPosition.x > nearestPortalX && !rightOfPortal)) &&
		abs((worldSpacePosition.x + cameraPosition.x) - nearestPortalX + 0.5) < PORTAL_RENDER_DISTANCE * 16 / 2
	);

	noise = InterleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter);

	float nDotL = clamp01(dot(normal, lightVector));

	float penumbraWidth = SHADOW_SOFTNESS * rcp(10); // soft shadows

	vec3 shadow = ComputeShadows(shadowClipPos, penumbraWidth, useImageShadowMap);
	float blockerDistance = GetBlockerDistance(shadowClipPos);

	float scatter = ComputeSSS(blockerDistance, SSS, geometryNormal);
	sunlight = max(shadow * nDotL, scatter);
	sunlight = mix(sunlight, vec3(nDotL), distCoeff);



	sunlight *= 1.0 * SUN_LIGHT_LEVEL;
	sunlight *= mix(1.0, 0.0, biomePrecipness);



	return sunlight;
}

#endif
