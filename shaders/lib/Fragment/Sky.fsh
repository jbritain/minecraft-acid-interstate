#include "/lib/Fragment/PrecomputedSky.glsl"
#include "/lib/Fragment/2D_Clouds.fsh"
#include "/lib/Fragment/3D_Clouds.fsh"

vec3 CalculateSkyGradient(vec3 wDir, float sunglow, vec3 sunspot) {
	float gradientCoeff = pow4(1.0 - abs(wDir.y) * 0.5);
	
	vec3 primaryHorizonColor  = SetSaturationLevel(skylightColor, mix(1.25, 0.6, gradientCoeff * timeDay));
	     primaryHorizonColor *= gradientCoeff * 0.5 + 1.0;
	     primaryHorizonColor  = mix(primaryHorizonColor, sunlightColor, gradientCoeff * sunglow * timeDay);
	
	vec3 sunglowColor = mix(skylightColor, sunlightColor * 0.5, gradientCoeff * sunglow) * sunglow;
	
	vec3 color  = primaryHorizonColor * gradientCoeff * 8.0;
	     color *= sunglowColor * 2.0 + 1.0;
	     color += sunglowColor * 5.0;
	     color += sunspot * sunlightColor * sunlightColor * vec3(1.0, 0.8, 0.6);

	return color;
}

vec3 ComputeSunspot(vec3 wDir, inout vec3 transmit) {
	float sunspot = float(dot(wDir, sunVector) > 1.0 - SUN_ANGULAR_PERCENTAGE + 0*0.9999567766);
	vec3 color = vec3(float(sunspot) * sunbright) * transmit;

	//color += pow(smoothstep(0.8, 1.0, dot(wDir, sunVector)), 100);
	
	transmit *= 1.0 - sunspot;
	
	return color;
}

#define STARS
//#define REFLECT_STARS
//#define ROTATE_STARS
#define STAR_SCALE       1.0   // [0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0]
#define STAR_BRIGHTNESS  1.0   // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define STAR_COVERAGE    1.000 // [0.950 0.975 1.000 1.025 1.050]

vec3 CalculateStars(vec3 wDir, vec3 transmit, cbool reflection) {
	#ifndef STARS
	return vec3(0.0);
	#endif
	#ifndef REFLECT_STARS
	if (reflection) return vec3(0.0);
	#endif
	
	if (transmit.r + transmit.g + transmit.b <= 0.0) return vec3(0.0);
	
	vec2 coord;
	
	#ifdef ROTATE_STARS
		vec3 shadowCoord     = mat3(shadowViewMatrix) * wDir;
		     shadowCoord.xz *= sign(sunVector.y);
		
		coord  = vec2(atan(shadowCoord.x, shadowCoord.z), facos(shadowCoord.y));
		coord *= 3.0 * STAR_SCALE * noiseScale;
	#else
		coord = wDir.xz * (2.5 * STAR_SCALE * (2.0 - wDir.y) * noiseScale);
	#endif
	
	float noise  = texture(noisetex, coord * 0.5).r;
	      noise += texture(noisetex, coord).r * 0.5;
	
	float star = clamp01(noise - 1.3 / STAR_COVERAGE) * STAR_BRIGHTNESS * 2000.0 * pow2(clamp01(wDir.y)) * timeNight;
	
	return star * transmit;
}

float PhaseG(float cosTheta, const float g){
    float gg = g * g;
    return (gg * -0.25 + 0.25) * pow(-2.0 * (g * cosTheta) + (gg + 1.0), -1.5) / PI;
}

float CalculateCloudPhase(float vDotL){
    const float mixer = 0.5;

    float g1 = PhaseG(vDotL, 0.8);
    float g2 = PhaseG(vDotL, -0.5);

    return mix(g2, g1, mixer);
}


vec3 ComputeBackSky(vec3 wDir, vec3 wPos, io vec3 transmit, float sunlight, cbool reflection, float sunFactor) {
	vec3 color = vec3(0.0);
	color += SkyAtmosphere(wDir, transmit);
	
	color += CalculateNightSky(wDir, transmit);
	color += ComputeSunspot(wDir, transmit) * 16.0 * sunFactor;

	float sunglow = CalculateSunglow(dot(wDir, sunVector));
	float gradientCoeff = pow4(1.0 - abs(wDir.y) * 0.5);
	vec3 sunglowColor = mix(skylightColor, sunlightColor * 0.5, gradientCoeff * sunglow) * sunglow;

	color += sunglowColor * 5;

	color += ComputeSunspot(-wDir, transmit) * 4.0 * vec3(0.3, 0.7, 8.0) * sunFactor;
	color += CalculateStars(wDir, transmit, reflection);
	
	return color;
}

vec3 ComputeClouds(vec3 wDir, vec3 wPos, io vec3 transmit) {
	float VdotL = dot(wDir, sunVector);
	float phase = CalculateCloudPhase(VdotL);
	
	vec3 color = vec3(0.0);
	color += Compute2DCloudPlane(wDir, wPos, transmit, phase) / 100.0;
	
	return color;
}

vec3 computeEndSky(vec3 wDir){
	return mix(vec3(0.333, 0.212, 0.49) * 0.2, vec3(0.486, 0.349, 0.561), dot(normalize(wDir), vec3(0, 1, 0)));
}

vec3 ComputeSky(vec3 wDir, vec3 wPos, io vec3 transmit, float sunlight, cbool reflection, float sunFactor) {
	#ifdef WORLD_THE_NETHER
		return vec3(0);
	#endif

	#ifdef WORLD_THE_END
		return computeEndSky(wDir);
	#endif

	vec3 color = vec3(0.0);
	color += ComputeClouds(wDir, wPos, transmit);
	color += ComputeBackSky(wDir, wPos, transmit, sunlight, reflection, sunFactor);

	//color = mix(color, vec3(0.0), eyeBrightnessSmooth.y);
	
	return color;
}
