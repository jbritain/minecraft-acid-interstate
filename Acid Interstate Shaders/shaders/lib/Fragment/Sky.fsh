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
	float sunspot = float(dot(wDir, sunVector) > 0.9994 + 0*0.9999567766);
	vec3 color = vec3(float(sunspot) * sunbright) * transmit;
	
	transmit *= 1.0 - sunspot;
	
	return color;
}

#define STARS            ON    // [ON OFF]
#define REFLECT_STARS    OFF   // [ON OFF]
#define ROTATE_STARS     OFF   // [ON OFF]
#define STAR_SCALE       1.0   // [0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0]
#define STAR_BRIGHTNESS  1.0   // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define STAR_COVERAGE    1.000 // [0.950 0.975 1.000 1.025 1.050]

vec3 CalculateStars(vec3 wDir, vec3 transmit, cbool reflection) {
	if (!STARS) return vec3(0.0);
	if (!REFLECT_STARS && reflection) return vec3(0.0);
	
	if (transmit.r + transmit.g + transmit.b <= 0.0) return vec3(0.0);
	
	vec2 coord;
	
	if (ROTATE_STARS) {
		vec3 shadowCoord     = mat3(shadowViewMatrix) * wDir;
		     shadowCoord.xz *= sign(sunVector.y);
		
		coord  = vec2(atan(shadowCoord.x, shadowCoord.z), acos(shadowCoord.y));
		coord *= 3.0 * STAR_SCALE * noiseScale;
	} else
		coord = wDir.xz * (2.5 * STAR_SCALE * (2.0 - wDir.y) * noiseScale);
	
	float noise  = texture2D(noisetex, coord * 0.5).r;
	      noise += texture2D(noisetex, coord).r * 0.5;
	
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


vec3 ComputeBackSky(vec3 wDir, vec3 wPos, io vec3 transmit, float sunlight, cbool reflection) {
	vec3 color = vec3(0.0);
	color += SkyAtmosphere(wDir, transmit);
	
	color += CalculateNightSky(wDir, transmit);
	color += ComputeSunspot(wDir, transmit) * 16.0;
	color += ComputeSunspot(-wDir, transmit) * 16.0 * vec3(0.3, 0.7, 8.0);
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

vec3 ComputeSky(vec3 wDir, vec3 wPos, io vec3 transmit, float sunlight, cbool reflection) {
	vec3 color = vec3(0.0);
	color += ComputeClouds(wDir, wPos, transmit);
	color += ComputeBackSky(wDir, wPos, transmit, sunlight, reflection);
	
	return color;
}
