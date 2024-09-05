#if !defined COMPUTESHADEDFRAGMENT_FSH
#define COMPUTESHADEDFRAGMENT_FSH

#include "/lib/Fragment/PrecomputedSky.glsl"

struct Shading { // Scalar light levels
	vec3 sunlight;
	float skylight;
	float caustics;
	float torchlight;
	float ambient;
};

struct Lightmap { // Vector light levels with color
	vec3 sunlight;
	vec3 skylight;
	vec3 torchlight;
	vec3 ambient;
	vec3 GI;
};


#include "/lib/Fragment/ComputeSunlight.fsh"


float GetHeldLight(vec3 viewSpacePosition, vec3 normal, float handMask) {
	float falloff;

	float light = max(heldBlockLightValue, heldBlockLightValue2);

	vec3 eyeOffset = eyePosition - cameraPosition; // offset of eye from camera, vec3(0.) in first person
	vec3 eyeOffsetView = mat3(gbufferModelView) * eyeOffset;

	vec3 lightPos = viewSpacePosition - eyeOffsetView; // position relative to player eye, ideally I would use hand position but idk where the hand is

	if (length(lightPos) < light){
		float dist = length(lightPos);
		falloff = light;
		falloff = clamp01(falloff);
		falloff = mix(falloff, 0, dist / light);
	}

	#ifdef DIRECTIONAL_LIGHTING
	falloff *= clamp01(dot(normal, -normalize(lightPos))) * 0.8 + 0.2;
	#endif

	return falloff;
}



float Luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 ColorSaturate(vec3 base, float saturation) {
    return mix(base, vec3(Luma(base)), -saturation);
}

cvec3 nightColor = vec3(0.25, 0.35, 0.7);



vec3 LightDesaturation(vec3 color, float torchlight, float skylight, float emissive) {
//	if (emissive > 0.5) return vec3(color);
	
	vec3  desatColor = vec3(color.x + color.y + color.z);
	
	desatColor = mix(desatColor * nightColor, mix(desatColor, color, 0.5) * ColorSaturate(torchColor, 0.35) * 40.0, clamp01(torchlight * 2.0)*0+1);
	
	float moonFade = smoothstep(0.0, 0.3, max0(-worldLightVector.y));
	
	float coeff = clamp01(min(moonFade, 0.65) + pow(1.0 - skylight, 1.4));
	
	return mix(color, desatColor, coeff);
}

vec3 nightDesat(vec3 color, vec3 lightmap, cfloat mult, cfloat curve) {
	float desatAmount = clamp01(pow(length(lightmap) * mult, curve));
	vec3 desatColor = vec3(color.r + color.g + color.b);
	
	desatColor *= sqrt(desatColor);
	
	return mix(desatColor, color, desatAmount);
}

vec3 ComputeShadedFragment(vec3 diffuse, Mask mask, float torchLightmap, float skyLightmap, vec4 GI, vec3 normal, float emission, mat2x3 position, float materialAO, float SSS, vec3 geometryNormal, vec3 preCalculatedSunlight) {
	Shading shading;
	
#ifndef VARIABLE_WATER_HEIGHT
	if (mask.water != isEyeInWater) // Surface is in water
		skyLightmap = 1.0 - clamp01(-(position[1].y + cameraPosition.y - WATER_HEIGHT) / UNDERWATER_LIGHT_DEPTH);
#endif
	
	#ifdef WORLD_OVERWORLD
		shading.skylight = pow2(skyLightmap);
		
		shading.sunlight = preCalculatedSunlight;
		
		shading.skylight *= mix(shading.caustics * 0.65 + 0.35, 1.0, pow8(1.0 - abs(worldLightVector.y)));
		shading.skylight *= GI.a;
		shading.skylight *= 2.0 * SKY_LIGHT_LEVEL;


		#ifdef GI_ENABLED
			shading.skylight *= 0.9 * SKY_LIGHT_LEVEL;
		#endif
	#else
		shading.skylight = 0;
		shading.sunlight = vec3(0);
	#endif

	

	shading.torchlight  = torchLightmap;

	#ifdef gbuffers_textured
		shading.sunlight = vec3(max(shading.sunlight, shading.torchlight));
	#endif

	#ifdef HANDLIGHT
	shading.torchlight = max(shading.torchlight, GetHeldLight(position[0], normal, mask.hand));
	#endif

	shading.torchlight  = clamp01(shading.torchlight * (33.05 / 32.0) - (1.05 / 32.0));
	shading.torchlight = 20.0 * pow(shading.torchlight, 5.06);

	shading.torchlight *= GI.a;

	
	// shading.ambient  = 0.5 + (1.0 - EBS) * 3.0;
	shading.ambient += nightVision * 50.0;
	shading.ambient *= GI.a * 0.5 + 0.5;
	shading.ambient *= 0.04 * AMBIENT_LIGHT_LEVEL;
	shading.ambient = mix(shading.ambient, shading.ambient / 2.0, materialAO);
	#ifdef WORLD_THE_NETHER // nether - no sunlight or skylight so boost ambient
		shading.ambient = clamp(shading.ambient, 0.05, 1.0);
	#endif
	#ifdef WORLD_THE_END // the end
		shading.ambient *= 3;
	#endif
	
	
	Lightmap lightmap;
	
	lightmap.sunlight = shading.sunlight * sunlightColor;
	
	
	lightmap.skylight = shading.skylight * sqrt(skylightColor);
	
	lightmap.GI = GI.rgb * GI.a * sunlightColor;
	
	lightmap.ambient = vec3(shading.ambient) * vec3(1.0, 1.2, 1.4);
	
	

	lightmap.torchlight = shading.torchlight * torchColor;
	
	lightmap.skylight *= clamp01(1.0 - dot(lightmap.GI, vec3(1.0)) / 6.0);
	
	
//	lightmap.sunlight = GetSunAndSkyIrradiance(kPoint(position[1]), normal, sunVector, lightmap.skylight) * shading.sunlight*2.0;
	
	
	vec3 desatColor = vec3(pow(diffuse.r + diffuse.g + diffuse.b, 1.5));
	
#define LIGHT_DESATURATION
#ifndef LIGHT_DESATURATION
	desatColor = diffuse;
#endif
	
	vec3 composite =
	  diffuse * (lightmap.GI + lightmap.ambient + emission * 16)
	+ lightmap.sunlight   * mix(desatColor, diffuse, clamp01(pow(length(lightmap.sunlight  ) *  4.0, 0.1)))
	+ lightmap.skylight   * mix(desatColor, diffuse, clamp01(pow(length(lightmap.skylight  ) * 25.0, 0.2)))
	+ lightmap.torchlight * mix(desatColor, diffuse, clamp01(pow(length(lightmap.torchlight) *  1.0, 0.1)));


	return composite;
}

#endif
