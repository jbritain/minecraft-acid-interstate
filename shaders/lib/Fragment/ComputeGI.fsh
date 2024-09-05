#if !defined ComputeGI_FSH
#define ComputeGI_FSH

#include "/lib/Misc/ShadowBias.glsl"
#include "/lib/Fragment/ComputeSunlight.fsh"

#ifndef GI_ENABLED
	#define ComputeGI(a, b, c, d, e, f) vec3(0.0)
#else
vec3 ComputeGI(vec3 worldSpacePosition, vec3 normal, float skyLightmap, cfloat radius, vec2 noise, Mask mask) {
	float distCoeff = GetDistanceCoeff(worldSpacePosition);
	
	float lightMult = skyLightmap * (1.0 - distCoeff);
	
#ifdef GI_BOOST
	float sunlight = GetLambertianShading(normal, worldLightVector, mask) * skyLightmap;
	      //sunlight = ComputeSunlight(worldSpacePosition, sunlight);
	
	lightMult = (pow2(skyLightmap) * 0.9 + 0.1) * (1.0 - distCoeff) - sunlight * 4.0;
#endif
	
	if (lightMult < 0.05) return vec3(0.0);
	
	float LodCoeff = clamp01(1.0 - length(worldSpacePosition) / shadowDistance);
	
	float depthLOD	= 2.0 * LodCoeff;
	float sampleLOD	= 5.0 * LodCoeff;
	
	vec3 shadowViewPosition = transMAD(shadowViewMatrix, worldSpacePosition + gbufferModelViewInverse[3].xyz);
	
	vec2 basePos = shadowViewPosition.xy * diagonal2(shadowProjection) + shadowProjection[3].xy;
	
	normal = mat3(shadowViewMatrix) * -normal;
	
	vec3 projMult = mat3(shadowProjectionInverse) * -vec3(1.0, 1.0, zShrink * 2.0);
	vec3 projDisp = shadowViewPosition.xyz - shadowProjectionInverse[3].xyz - vec3(0.0, 0.0, 0.5 * projMult.z);
	
	cvec3 sampleMax = vec3(0.0, 0.0, radius * radius);
	
	cfloat brightness = 1.0 * radius * radius * GI_BRIGHTNESS * SUN_LIGHT_LEVEL;
	cfloat scale      = radius / 256.0;
	
	noise *= scale;
	
	vec3 GI = vec3(0.0);
	
	#include "/lib/Samples/GI.glsl"
	
	float translucent = clamp01(GI_TRANSLUCENCE + mask.translucent);
	
	for (int i = 0; i < GI_SAMPLE_COUNT; i++) {
		vec2 offset = samples[i] * scale + noise;
		
		if (dot(offset.xy, normal.xy) - mask.translucent >= 0.0) continue; // Faux-hemisphere
		
		vec3 samplePos = vec3(basePos.xy + offset, 0.0);
		
		vec2 mapPos = BiasShadowMap(samplePos.xy) * 0.5 + 0.5;
		
		samplePos.z = texture2DLod(shadowtex1, mapPos, depthLOD).x;
		
		vec3 sampleDiff = samplePos * projMult + projDisp.xyz;
		
		float sampleLengthSqrd = length2(sampleDiff);
		
		vec3 shadowNormal;
		     shadowNormal.xy = texture2DLod(shadowcolor1, mapPos, sampleLOD).xy * 2.0 - 1.0;
		     shadowNormal.z  = sqrt(1.0 - length2(shadowNormal.xy));
		
		vec3 lightCoeffs   = vec3(finversesqrt(sampleLengthSqrd) * sampleDiff * mat2x3(normal, shadowNormal), sampleLengthSqrd);
		     lightCoeffs   = max(lightCoeffs, sampleMax);
		     lightCoeffs.x = mix(lightCoeffs.x, 1.0, translucent);
		     lightCoeffs.y = sqrt(lightCoeffs.y);
		
		vec3 flux = texture2DLod(shadowcolor0, mapPos, sampleLOD).rgb;
		
		GI += flux * (lightCoeffs.x * lightCoeffs.y * rcp(lightCoeffs.z));
	}
	
	GI /= GI_SAMPLE_COUNT;
	
	return GI * lightMult * brightness;
}
#endif

#endif
