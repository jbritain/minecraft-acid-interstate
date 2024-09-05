vec3 CalculateVertexDisplacements(vec3 worldSpacePosition) {
	vec3 worldPosition = worldSpacePosition + cameraPos;
	
#if !defined gbuffers_shadow && !defined gbuffers_basic
	worldPosition += previousCameraPosition - cameraPosition;
#endif
	
	vec3 displacement = vec3(0.0);
	
#if defined gbuffers_terrain || defined gbuffers_water || defined gbuffers_shadow
	if      (materialIDs == IPBR_LEAVES)
		{ displacement += GetWavingLeaves(worldPosition); }

	else if (materialIDs == IPBR_GRASS || materialIDs == IPBR_FLOWERS)
		{ displacement += GetWavingGrass(worldPosition, false); }

	else if (IPBR_IS_TALL_GRASS(materialIDs))
		{ displacement += GetWavingGrass(worldPosition, true); }
#endif
	
#if !defined gbuffers_hand
	displacement += TerrainDeformation(worldSpacePosition) - worldSpacePosition;
#endif
	
	return displacement;
}
