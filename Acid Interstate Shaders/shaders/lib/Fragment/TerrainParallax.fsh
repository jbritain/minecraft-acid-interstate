#if !defined TERRAINPARALLAX_FSH
#define TERRAINPARALLAX_FSH

vec2 ComputeParallaxCoordinate(vec2 coord, vec3 position) {
#if !defined TERRAIN_PARALLAX || !defined gbuffers_terrain
	return coord;
#endif
	
	LOD = textureQueryLod(tex, coord).x;
	
	cfloat parallaxDist = TERRAIN_PARALLAX_DISTANCE;
	cfloat distFade     = parallaxDist / 3.0;
	cfloat MinQuality   = 0.5;
	cfloat maxQuality   = 1.5;
	
	float intensity = clamp01((parallaxDist - length(position) * FOV / 90.0) / distFade) * 0.85 * TERRAIN_PARALLAX_INTENSITY;
	
	if (intensity < 0.01) { return coord; }
	
	float quality = clamp(radians(180.0 - FOV) / max1(pow(length(position), 0.25)), MinQuality, maxQuality) * TERRAIN_PARALLAX_QUALITY;
	
	vec3 tangentRay = normalize(position) * tbnMatrix;

	vec2 textureRes = vec2(TEXTURE_PACK_RESOLUTION);
	
	if (atlasSize.x != atlasSize.y) {
		tangentRay.x *= 0.5;
		textureRes.y *= 2.0;
	}
	
	vec4 tileScale   = vec4(atlasSize.x / textureRes, textureRes / atlasSize.x);
	vec2 tileCoord   = fract(coord * tileScale.xy);
	vec2 atlasCorner = floor(coord * tileScale.xy) * tileScale.zw;
	
	float stepCoeff = -tangentRay.z * 100.0 * clamp01(intensity);
	
	vec3 step    = tangentRay * vec3(0.01, 0.01, 1.0 / intensity) / quality * 0.03 * sqrt(length(position));
	     step.z *= stepCoeff;
	
	vec3  sampleRay    = vec3(0.0, 0.0, stepCoeff);
	float sampleHeight = GetTexture(normals, coord).a * stepCoeff;
	
	if (sampleRay.z <= sampleHeight) return coord;
	
	for (uint i = 0; sampleRay.z > sampleHeight && i < 150; i++) {
		sampleRay.xy += step.xy * clamp01(sampleRay.z - sampleHeight);
		sampleRay.z += step.z;
		
		sampleHeight = GetTexture(normals, fract(sampleRay.xy * tileScale.xy + tileCoord) * tileScale.zw + atlasCorner).a * stepCoeff;
	}
	
	return fract(sampleRay.xy * tileScale.xy + tileCoord) * tileScale.zw + atlasCorner;
}

#endif
