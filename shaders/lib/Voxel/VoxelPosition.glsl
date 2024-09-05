// this must also be the image resolution on all 3 axes in shaders.properties AND there's some stuff in shadowcomp you'd need to change as well
// but honestly, just don't change it
#define VOXEL_MAP_SIZE ivec3(128, 64, 128)

// takes in a player space position and returns a position in the voxel map
ivec3 mapVoxelPos(vec3 playerPos){
  return ivec3(playerPos + fract(cameraPosition) + ivec3(VOXEL_MAP_SIZE / 2));
}

bool isWithinVoxelBounds(ivec3 voxelPos){
  return all(greaterThanEqual(voxelPos, ivec3(0))) && all(lessThan(voxelPos, ivec3(VOXEL_MAP_SIZE)));
}

// for sampling the voxel texture as a sampler3D so we get interpolation
vec3 mapVoxelPosInterp(vec3 playerPos){
  return (playerPos + fract(cameraPosition) + VOXEL_MAP_SIZE / 2) / VOXEL_MAP_SIZE;
}

bool isWithinVoxelBoundsInterp(vec3 voxelPosInterp){
  return all(greaterThanEqual(voxelPosInterp, vec3(0.0))) && all(lessThanEqual(voxelPosInterp, vec3(1.0)));
}

#if defined gbuffers_shadow || defined shadowcomp0
ivec3 mapPreviousVoxelPos(vec3 playerPos){
  return ivec3(playerPos + fract(previousCameraPosition) + ivec3(VOXEL_MAP_SIZE / 2));
}

ivec3 getPreviousVoxelOffset(){
  return ivec3(floor(previousCameraPosition) - floor(cameraPosition));
}
#endif