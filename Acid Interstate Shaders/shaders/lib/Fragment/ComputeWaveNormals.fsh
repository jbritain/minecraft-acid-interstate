#if !defined COMPUTEWAVENORMALS_FSH

float GetWaveCoord(float coord) {
	cfloat madd = 0.5 * noiseResInverse;
	float whole = floor(coord);
	coord = whole + cubesmooth(coord - whole);
	
	return coord * noiseResInverse + madd;
}

vec2 GetWaveCoord(vec2 coord) {
	cvec2 madd = vec2(0.5 * noiseResInverse);
	vec2 whole = floor(coord);
	coord = whole + cubesmooth(coord - whole);
	
	return coord * noiseResInverse + madd;
}

float SharpenWave(float wave) {
	wave = 1.0 - abs(wave * 2.0 - 1.0);
	
	return wave < 0.78 ? wave : (wave * -2.5 + 5.0) * wave - 1.6;
}

cvec4 heights = vec4(29.0, 15.0, 17.0, 4.0);
cvec4 height = heights * WAVE_MULT / sum4(heights);

cvec2[4] scale = vec2[4](
	vec2(0.0065, 0.0052  ) * noiseRes * noiseScale,
	vec2(0.013 , 0.00975 ) * noiseRes * noiseScale,
	vec2(0.0195, 0.014625) * noiseRes * noiseScale,
	vec2(0.0585, 0.04095 ) * noiseRes * noiseScale);

cvec4 stretch = vec4(
	scale[0].x * -1.7 ,
	scale[1].x * -1.7 ,
	scale[2].x *  1.1 ,
	scale[3].x * -1.05);

mat4x2 waveTime = mat4x2(0.0);

void SetupWaveFBM() {
	cvec2 disp1 = vec2(0.04155, -0.0165   ) * noiseRes * noiseScale;
	cvec2 disp2 = vec2(0.017  , -0.0469   ) * noiseRes * noiseScale;
	cvec2 disp3 = vec2(0.0555 ,  0.03405  ) * noiseRes * noiseScale;
	cvec2 disp4 = vec2(0.00825, -0.0491625) * noiseRes * noiseScale;
	
	float w = TIME * WAVE_SPEED * 0.6;
	
	waveTime[0] = w * disp1;
	waveTime[1] = w * disp2;
	waveTime[2] = w * disp3;
	waveTime[3] = w * disp4;
}

float GetWaves(vec2 coord, io mat4x2 c) {
	float waves = 0.0;
	vec2 ebin;
	
	c[0].xy = coord * scale[0] + waveTime[0];
	c[0].y = coord.x * stretch[0] + c[0].y;
	ebin = GetWaveCoord(c[0].xy);
	c[0].x = ebin.x;
	
	waves += SharpenWave(texture2D(noisetex, ebin).x) * height.x;
	
	c[1].xy = coord * scale[1] + waveTime[1];
	c[1].y = coord.x * stretch[1] + c[1].y;
	ebin = GetWaveCoord(c[1].xy);
	c[1].x = ebin.x;
	
	waves += texture2D(noisetex, ebin).x * height.y;
	
	c[2].xy = coord * scale[2] + waveTime[2];
	c[2].y = coord.x * stretch[2] + c[2].y;
	ebin = GetWaveCoord(c[2].xy);
	c[2].x = ebin.x;
	
	waves += texture2D(noisetex, ebin).x * height.z;
	
	c[3].xy = coord * scale[3] + waveTime[3];
	c[3].y = coord.x * stretch[3] + c[3].y;
	ebin = GetWaveCoord(c[3].xy);
	c[3].x = ebin.x;
	
	waves += texture2D(noisetex, ebin).x * height.w;
	
	return waves;
}

float GetWaves(vec2 coord) {
	mat4x2 c;
	
	return GetWaves(coord, c);
}

float GetWaves(mat4x2 c, float offset) {
	float waves = 0.0;
	
	c[0].y = GetWaveCoord(offset * scale[0].y + c[0].y);
	
	waves += SharpenWave(texture2D(noisetex, c[0].xy).x) * height.x;
	
	c[1].y = GetWaveCoord(offset * scale[1].y + c[1].y);
	
	waves += texture2D(noisetex, c[1].xy).x * height.y;
	
	c[2].y = GetWaveCoord(offset * scale[2].y + c[2].y);
	
	waves += texture2D(noisetex, c[2].xy).x * height.z;
	
	c[3].y = GetWaveCoord(offset * scale[3].y + c[3].y);
	
	waves += texture2D(noisetex, c[3].xy).x * height.w;
	
	return waves;
}

vec2 GetWaveDifferentials(vec2 coord, cfloat scale) { // Get finite wave differentials for the world-space X and Z coordinates
	mat4x2 c;
	
	float a  = GetWaves(coord, c);
	float aX = GetWaves(coord + vec2(scale,   0.0));
	float aY = GetWaves(c, scale);
	
	return a - vec2(aX, aY);
}

#if defined gbuffers_water
vec2 GetParallaxWave(vec2 worldPos, float angleCoeff) {
#ifndef WATER_PARALLAX
	return worldPos;
#endif
	
	cfloat parallaxDist = TERRAIN_PARALLAX_DISTANCE * 5.0;
	cfloat distFade     = parallaxDist / 3.0;
	cfloat MinQuality   = 0.5;
	cfloat maxQuality   = 1.5;
	
	float intensity = clamp01((parallaxDist - length(position[1]) * FOV / 90.0) / distFade) * 0.85 * TERRAIN_PARALLAX_INTENSITY;
	
//	if (intensity < 0.01) return worldPos;
	
	float quality = clamp(radians(180.0 - FOV) / max1(pow(length(position[1]), 0.25)), MinQuality, maxQuality) * TERRAIN_PARALLAX_QUALITY;
	
	vec3  tangentRay = normalize(position[1]) * tbnMatrix;
	vec3  stepSize = 0.1 * vec3(1.0, 1.0, 1.0);
	float stepCoeff = -tangentRay.z * 5.0 / stepSize.z;
	
	angleCoeff = clamp01(angleCoeff * 2.0) * stepCoeff;
	
	vec3 step   = tangentRay   * stepSize;
	     step.z = tangentRay.z * -tangentRay.z * 5.0;
	
	float rayHeight = angleCoeff;
	float sampleHeight = GetWaves(worldPos) * angleCoeff;
	
	float count = 0.0;
	
	while(sampleHeight < rayHeight && count++ < 150.0) {
		worldPos  += step.xy * clamp01(rayHeight - sampleHeight);
		rayHeight += step.z;
		
		sampleHeight = GetWaves(worldPos) * angleCoeff;
	}
	
	return worldPos;
}

vec3 ViewSpaceToScreenSpace(vec3 viewSpacePosition) {
	return projMAD(projMatrix, viewSpacePosition) / -viewSpacePosition.z * 0.5 + 0.5;
}

vec3 ComputeWaveNormals(vec3 worldSpacePosition, vec3 flatWorldNormal) {
	if (WAVE_MULT == 0.0) return vec3(0.0, 0.0, 1.0);
	
	SetupWaveFBM();
	
	float angleCoeff  = dotNorm(-position[1].xyz, flatWorldNormal);
	      angleCoeff /= clamp(length(position[1]) * 0.05, 1.0, 10.0);
	      angleCoeff  = clamp01(angleCoeff * 2.5);
	      angleCoeff  = sqrt(angleCoeff);
	
	vec3 worldPos    = position[1] + cameraPos - worldDisplacement;
	     worldPos.xz = worldPos.xz + worldPos.y;
	
	worldPos.xz = GetParallaxWave(worldPos.xz, angleCoeff);
	
	vec2 diff = GetWaveDifferentials(worldPos.xz, 0.1) * angleCoeff;
	
	return vec3(diff, sqrt(1.0 - length2(diff)));
}
#endif

#endif
