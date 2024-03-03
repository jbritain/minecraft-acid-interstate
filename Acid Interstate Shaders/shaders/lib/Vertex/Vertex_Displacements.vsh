

vec3 CalculateVertexDisplacements(vec3 worldSpacePosition) {
	vec3 worldPosition = worldSpacePosition + cameraPos;
	
#if !defined gbuffers_shadow && !defined gbuffers_basic
	worldPosition += previousCameraPosition - cameraPosition;
#endif
	
	vec3 displacement = vec3(0.0);
	
#if defined gbuffers_terrain || defined gbuffers_water || defined gbuffers_shadow
	if      (isTranslucent(materialIDs))
		{ displacement += GetWavingLeaves(worldPosition); }
	
	else if (isWater(materialIDs))
		{ displacement += GetWavingWater(worldPosition); }
#endif
	
	displacement += TerrainDeformation(worldSpacePosition) - worldSpacePosition;
	
	return displacement;
}
