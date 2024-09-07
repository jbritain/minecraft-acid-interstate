#if !defined EUCLID_GLSL
#define EUCLID_GLSL

#include "/lib/Utility.glsl"
#include "/UserProgram/Terrain_Deformation.vsh"

float DistanceToPlane(vec3 point, vec3 p0, vec3 p1, vec3 p2) {
	vec3   normal = normalize(cross(p1 - p0, p2 - p0));
	return dot(normal, point) - dot(normal, p0);
}

float DistanceToPlane(vec3 point, vec3 p1, vec3 p2) {
	vec3   normal = normalize(cross(p1, p2));
	return dot(normal, point);
}

bool IsInsideFrustum(vec3 pos, vec3 center, float horizontalSpan, float verticalSpan) {
	vec3 topLeft  = center + vec3(0.0,  verticalSpan, -horizontalSpan ) - cameraPosition.xyz;
	vec3 topRight = center + vec3(0.0,  verticalSpan,  horizontalSpan ) - cameraPosition.xyz;
	vec3 botLeft  = center + vec3(0.0, -verticalSpan, -horizontalSpan ) - cameraPosition.xyz;
	vec3 botRight = center + vec3(0.0, -verticalSpan,  horizontalSpan ) - cameraPosition.xyz;

	topLeft = TerrainDeformation(topLeft);
	topRight = TerrainDeformation(topRight);
	botLeft = TerrainDeformation(botLeft);
	botRight = TerrainDeformation(botRight);

	vec3 deformedPosition = TerrainDeformation(pos.xyz);
	
	float topDistance = DistanceToPlane(deformedPosition, vec3(0.0), topRight, topLeft);
	float bottomDistance = DistanceToPlane(deformedPosition, vec3(0.0), botRight, botLeft);
	float leftDistance = DistanceToPlane(deformedPosition, vec3(0.0), topLeft, botLeft);
	float rightDistance	= DistanceToPlane(deformedPosition, vec3(0.0), topRight, botRight);
	
	if (cameraPosition.x < center.x) {
		return !(
			sign(leftDistance) > -0.5
			|| sign(rightDistance) < 0.5
			|| sign(topDistance) > 0.5
			|| sign(bottomDistance) < 0.5
		);
  } else {
		return (
			sign(leftDistance) > -0.5
			&& sign(rightDistance) < 0.5
			&& sign(topDistance) > 0.5
			&& sign(bottomDistance) < 0.5
		);
  }
}

#define PORTAL_RENDER_DISTANCE 16
#define PORTAL_Y 64.5
#define PORTAL_WIDTH 3
#define PORTAL_HEIGHT 3

// 1 if in left portal area, 2 if in portal null zone, 3 if in right portal area (assumes a value outside the transition zone will not be passed in)
int getZoneSegment(in vec3 position){
	if(position.z >= -2 && position.z <= 3){
		return 2;
	}

  if(position.z < 0){
		return 1;
	} else {
		return 3;
	}
}

// position should be in world space (i.e player space + cameraPosition)
#ifdef vsh
void doPortal(float portalX, inout vec3 position, vec3 midblock){
#else
void doPortal(float portalX, vec3 position, vec3 midblock){
#endif

	vec3 blockCentre = position + (midblock / 64);

	bool inRangeOfPortal = abs(blockCentre.x - portalX + 0.5) < PORTAL_RENDER_DISTANCE * 16 / 2;
	if(!inRangeOfPortal) return;

	int zoneSegment = getZoneSegment(blockCentre);

	#ifdef fsh
	if(zoneSegment == 2){
		discard;
	}
	#endif

	if(zoneSegment == 1){
		position.z += PORTAL_RENDER_DISTANCE * 16 / 2 + 3;
	} else if (zoneSegment == 3) {
		position.z -= PORTAL_RENDER_DISTANCE * 16 / 2 + 3;
	}

	#ifdef fsh
	vec3 localPosition = position - cameraPosition;

	bool playerBeforePortal = cameraPosition.x < portalX;
	bool visibleThroughPortal = IsInsideFrustum(localPosition, vec3(portalX, PORTAL_Y, 0.5), 1.5, 1.5);
	bool positionBeforePortal = position.x < portalX;

	if(zoneSegment == 1){ // should appear before portal
		if (playerBeforePortal && !positionBeforePortal && visibleThroughPortal){ // don't show within portal
			discard;
		} else if (!playerBeforePortal && !visibleThroughPortal){ // if through portal, only show within portal
			discard;
		} else if (!playerBeforePortal && !positionBeforePortal) { // if through portal, discard terrain on this side
			discard;
		}
	}
	else if (zoneSegment == 3){ // should appear after portal
		if (!playerBeforePortal && positionBeforePortal && visibleThroughPortal){
			discard;
		} else if (playerBeforePortal && !visibleThroughPortal){ // if through portal, only show within portal
			discard;
		} else if (playerBeforePortal && positionBeforePortal){ // if through portal, discard terrain on this side
			discard;
		}
	} else {
		discard;
	}
	

	#endif
}

#endif