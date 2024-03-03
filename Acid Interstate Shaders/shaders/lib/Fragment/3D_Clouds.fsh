float CalculateDitherPattern1() {
	const int[16] ditherPattern = int[16] (
		 0,  8,  2, 10,
		12,  4, 14,  6,
		 3, 11,  1,  9,
		15,  7, 13,  5);
	
	vec2 count = vec2(mod(gl_FragCoord.st, vec2(4.0)));
	
	int dither = ditherPattern[int(count.x) + int(count.y) * 4] + 1;
	
	return float(dither) / 17.0;
}

float CalculateSunglow2(vec3 vPos) {
	vec3 npos = normalize(vPos);
	vec3 halfVector2 = normalize(-lightVector + npos);
	float factor = 1.0 - dot(halfVector2, npos);
	
	return factor * factor * factor * factor;
}

float Get2DNoise(vec3 pos) { // 2D slices
	return texture2D(noisetex, pos.xz * noiseResInverse).x;
}

float Get2DStretchNoise(vec3 pos) {
	float zStretch = 15.0 * noiseResInverse;
	
	vec2 coord = pos.xz * noiseResInverse + (floor(pos.y) * zStretch);
	
	return texture2D(noisetex, coord).x;
}

float Get2_5DNoise(vec3 pos) { // 2.5D
	float p = floor(pos.y);
	float f = pos.y - p;
	
	float zStretch = 17.0 * noiseResInverse;
	
	vec2 coord = pos.xz * noiseResInverse + (p * zStretch);
	
	vec2 noise = texture2D(noisetex, coord).xy;
	
	return mix(noise.x, noise.y, f);
}

float Get3DNoise(vec3 pos) { // True 3D
	float p = floor(pos.z);
	float f = pos.z - p;
	
	float zStretch = 17.0 * noiseResInverse;
	
	vec2 coord = pos.xy * noiseResInverse + (p * zStretch);
	
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord + zStretch).x;
	
	return mix(xy1, xy2, f);
}

vec3 Get3DNoise3D(vec3 pos) {
	float p = floor(pos.z);
	float f = pos.z - p;
	
	float zStretch = 17.0 * noiseResInverse;
	
	vec2 coord = pos.xy * noiseResInverse + (p * zStretch);
	
	vec3 xy1 = texture2D(noisetex, coord).xyz;
	vec3 xy2 = texture2D(noisetex, coord + zStretch).xyz;
	
	return mix(xy1, xy2, f);
}

#define CloudNoise Get3DNoise // [Get2DNoise Get2DStretchNoise Get2_5DNoise Get3DNoise]

float GetCoverage(float coverage, cfloat denseFactor, float clouds) {
	return clamp01((clouds + coverage - 1.0) * denseFactor);
}

mat4x3 cloudMul;
mat4x3 cloudAdd;

vec3 directColor, ambientColor, bouncedColor;

vec4 CloudColor(vec3 worldPosition, cfloat cloudLowerHeight, cfloat cloudDepth, cfloat denseFactor, float coverage, float sunglow) {
	cfloat cloudCenter = cloudLowerHeight + cloudDepth * 0.5;
	
	float cloudAltitudeWeight = clamp01(distance(worldPosition.y, cloudCenter) / (cloudDepth / 2.0));
	      cloudAltitudeWeight = pow(1.0 - cloudAltitudeWeight, 0.33);
	
	vec4 cloud;
	
	mat4x3 p;
	
	cfloat[5] weights = float[5](1.3, -0.7, -0.255, -0.105, 0.04);
	
	vec3 w = worldPosition / 100.0;
	
	p[0] = w * cloudMul[0] + cloudAdd[0];
	p[1] = w * cloudMul[1] + cloudAdd[1];
	
	cloud.a  = CloudNoise(p[0]) * weights[0];
	cloud.a += CloudNoise(p[1]) * weights[1];
	
	if (GetCoverage(coverage, denseFactor, (cloud.a - weights[1]) * cloudAltitudeWeight) < 1.0)
		return vec4(0.0);
	
	p[2] = w * cloudMul[2] + cloudAdd[2];
	p[3] = w * cloudMul[3] + cloudAdd[3];
	
	cloud.a += CloudNoise(p[2]) * weights[2];
	cloud.a += CloudNoise(p[3]) * weights[3];
	cloud.a += CloudNoise(p[3] * cloudMul[3] / 6.0 + cloudAdd[3]) * weights[4];
	
	cloud.a += -(weights[1] + weights[2] + weights[3]);
	cloud.a /= 2.15;
	
	cloud.a = GetCoverage(coverage, denseFactor, cloud.a * cloudAltitudeWeight);
	
	float heightGradient  = clamp01((worldPosition.y - cloudLowerHeight) / cloudDepth);
	float anisoBackFactor = mix(clamp01(pow(cloud.a, 1.6) * 2.5), 1.0, sunglow);
	float sunlight;
	
	/*
	vec3 lightOffset = 0.25 * worldLightVector;
	
	cloudAltitudeWeight = clamp01(distance(worldPosition.y + lightOffset.y * cloudDepth, cloudCenter) / (cloudDepth / 2.0));
	cloudAltitudeWeight = pow(1.0 - cloudAltitudeWeight, 0.3);
	
	sunlight  = CloudNoise(p[0] + lightOffset) * weights[0];
	sunlight += CloudNoise(p[1] + lightOffset) * weights[1];
	if (1.0 - GetCoverage(coverage, denseFactor, (sunlight - weights[1]) * cloudAltitudeWeight) < 1.0)
	{
	sunlight += CloudNoise(p[2] + lightOffset) * weights[2];
	sunlight += CloudNoise(p[3] + lightOffset) * weights[3];
	sunlight += -(weights[1] + weights[2] + weights[3]); }
	sunlight /= 2.15;
	sunlight  = 1.0 - pow(GetCoverage(coverage, denseFactor, sunlight * cloudAltitudeWeight), 1.5);
	sunlight  = (pow4(heightGradient) + sunlight * 0.9 + 0.1) * (1.0 - timeHorizon);
	*/
	
	sunlight  = pow5((worldPosition.y - cloudLowerHeight) / (cloudDepth - 25.0)) + sunglow * 0.005;
	sunlight *= 1.0 + sunglow * 5.0 + pow(sunglow, 0.25);
	
	
	cloud.rgb = mix(ambientColor, directColor, sunlight) + bouncedColor;
	
	return cloud;
}

void swap(io vec3 a, io vec3 b) {
	vec3 swap = a;
	a = b;
	b = swap;
}

void CloudFBM1(cfloat speed) {
	float t = TIME * 0.07 * speed;
	
	cloudMul[0] = vec3(0.5, 0.5, 0.1);
	cloudAdd[0] = vec3(t * 1.0, 0.0, 0.0);
	
	cloudMul[1] = vec3(1.0, 2.0, 1.0);
	cloudAdd[1] = vec3(t * 0.577, 0.0, 0.0);
	
	cloudMul[2] = vec3(6.0, 6.0, 6.0);
	cloudAdd[2] = vec3(t * 5.272, 0.0, t * 0.905);
	
	cloudMul[3] = vec3(18.0);
	cloudAdd[3] = vec3(t * 19.721, 0.0, t * 6.62);
}

void CloudLighting2(float sunglow) {
	directColor  = sunlightColor;
	directColor *= 35.0 * (1.0 + pow2(sunglow) * 2.0) * mix(1.0, 0.2, rainStrength);
	
	ambientColor  = mix(sqrt(skylightColor), sunlightColor, 0.5);
	ambientColor *= 0.5 + timeHorizon * 0.5;
	
	directColor += ambientColor * 20.0 * timeHorizon;
	
	bouncedColor = vec3(0.0);
}

void RaymarchClouds(io vec4 cloud, vec3 position, float sunglow, float samples, cfloat noise, cfloat density, float coverage, cfloat cloudLowerHeight, cfloat cloudDepth) {
	if (cloud.a >= 1.0) return;
	
	cfloat cloudUpperHeight = cloudLowerHeight + cloudDepth;
	
	vec3 a, b, rayPosition, rayIncrement;
	
	a = position * ((cloudUpperHeight - cameraPosition.y) / position.y);
	b = position * ((cloudLowerHeight - cameraPosition.y) / position.y);
	
	if (cameraPosition.y < cloudLowerHeight) {
		if (position.y <= 0.0) return;
		
		swap(a, b);
	} else if (cloudLowerHeight <= cameraPosition.y && cameraPosition.y <= cloudUpperHeight) {
		if (position.y < 0.0) swap(a, b);
		
		samples *= abs(a.y) / cloudDepth;
		b = vec3(0.0);
		
		swap(a, b);
	} else {
		if (position.y >= 0.0) return;
	}
	
	rayIncrement = (b - a) / (samples + 1.0);
	rayPosition = a + cameraPosition + rayIncrement * (1.0 + CalculateDitherPattern1() * noise);
	
	coverage *= clamp01(1.0 - length2((rayPosition.xz - cameraPosition.xz) / 10000.0));
	if (coverage <= 0.1) return;
	
	cfloat denseFactor = 1.0 / (1.0 - density);
	
	for (float i = 0.0; i < samples && cloud.a < 1.0; i++, rayPosition += rayIncrement) {
		vec4 cloud = CloudColor(rayPosition, cloudLowerHeight, cloudDepth, denseFactor, coverage, sunglow);
		
		cloud.rgb += cloud.rgb * (1.0 - cloud.a) * cloud.a;
		cloud.a += cloud.a;
	}
	
	cloud.a = clamp01(cloud.a);
}

//#define CLOUD3D
#define CLOUD3D_START_HEIGHT 400    // [260 300 350 400 450 500 550 600 650 700 750 800 850 900 950 1000]
#define CLOUD3D_DEPTH        150    // [50 100 150 200 250 300 350 400 450 500]
#define CLOUD3D_SAMPLES       10    // [3 4 5 6 7 8 9 10 15 20 25 30 40 50 100]
#define CLOUD3D_NOISE          1.0  // [0.0 1.0]
#define CLOUD3D_COVERAGE       0.5  // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]
#define CLOUD3D_DENSITY        0.95 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 0.97 0.99]
#define CLOUD3D_SPEED          1.0  // [0.25 0.5 1.0 2.5 5.0 10.0]

vec4 CalculateClouds3(vec3 wPos, float depth) {
#ifndef CLOUD3D
	return vec4(0.0);
#endif
	
	if (depth < 1.0) return vec4(0.0);
	const ivec2[4] offsets = ivec2[4](ivec2(2), ivec2(-2, 2), ivec2(2, -2), ivec2(-2));
//	if (all(lessThan(textureGatherOffsets(depthtex1, texcoord, offsets, 0), vec4(1.0)))) return vec4(0.0);
	
	float sunglow  = pow8(clamp01(dotNorm(wPos, worldLightVector) - 0.01)) * pow4(max(timeDay, timeNight));
	float coverage = 0.0;
	
	vec4 cloudSum = vec4(0.0);
	
	coverage = CLOUD3D_COVERAGE + rainStrength * 0.335;
	CloudFBM1(CLOUD3D_SPEED);
	CloudLighting2(sunglow);
	RaymarchClouds(cloudSum, wPos, sunglow, CLOUD3D_SAMPLES, CLOUD3D_NOISE, CLOUD3D_DENSITY, coverage, CLOUD3D_START_HEIGHT, CLOUD3D_DEPTH);
	
	cloudSum.rgb *= 0.1;
	
	return cloudSum;
}
