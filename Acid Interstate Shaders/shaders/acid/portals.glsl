#define RENDER_DISTANCE 32.0
uniform mat4 modelViewMatrix;

float portalAreaWidth = 16 * RENDER_DISTANCE; // width of terrain which is merged for portals
float portalNullZoneWidth = 5; // width of area not included in merge. Terrain here will be invisible
vec2 portalNullZoneCentre = vec2(0.5, 64.5); // coordinates of the centre of the portal null zone, along the x axis (so x is z really)
float portalHeight = 3;
float portalWidth = 3;

// 0 if in left portal area, 1 if in portal null zone, 2 if in right portal area (assumes a value outside the transition zone will not be passed in)
int getZoneSegment(in vec3 position){
  if (position.z <= portalNullZoneCentre.x - (portalNullZoneWidth / 2) + 0.5 ){
      return 1;
    } else if (position.z >= portalNullZoneCentre.x + (portalNullZoneWidth / 2) - 0.5) {
      return 3;
    } else {
      return 2;
    }
}



#ifdef fsh
  // originally I had my own code to handle portals but it didn't work when I ported it here
  // so I rewrote it using the logic from the previous acid interstate videos
  // there's also apparently a Euclid.glsl but using that would be cheating a bit too much

  #ifndef ACID_INCLUDED
    #include "/acid/acid.glsl"
    #define ACID_INCLUDED
  #endif

  // stolen from bruce
  float planeDistance(in vec3 point, in vec3 p0, in vec3 p1, in vec3 p2) {
    vec3 normal = normalize(cross(p1 - p0, p2 - p0));

    return normal.x * point.x + normal.y * point.y + normal.z * point.z - dot(normal, p0);
  }


    // convert the position and portal corner positions into NDC space and check if the position is within the portal
  bool isVisibleThroughPortal(vec3 position, float portalX){

    // get the portal corners in world space then convert to model space
    vec3 topLeft = vec3(portalX, portalNullZoneCentre.y + portalHeight / 2, portalNullZoneCentre.x - (portalWidth / 2)) - cameraPosition.xyz;
    vec3 topRight = vec3(portalX, portalNullZoneCentre.y + portalHeight / 2, portalNullZoneCentre.x + (portalWidth / 2)) - cameraPosition.xyz;
    vec3 bottomLeft = vec3(portalX, portalNullZoneCentre.y - portalHeight / 2, portalNullZoneCentre.x - (portalWidth / 2)) - cameraPosition.xyz;
    vec3 bottomRight = vec3(portalX, portalNullZoneCentre.y - portalHeight / 2, portalNullZoneCentre.x + (portalWidth / 2)) - cameraPosition.xyz;

    //deform portal corners
    doAcid(topLeft, cameraPosition);
    doAcid(topRight, cameraPosition);
    doAcid(bottomLeft, cameraPosition);
    doAcid(bottomRight, cameraPosition);
    
    // deform position we are checking
    vec3 deformedPosition = position;
    doAcid(deformedPosition, cameraPosition);

    float topDistance = planeDistance(deformedPosition.xyz, vec3(0.0), topRight, topLeft);
    float bottomDistance = planeDistance(deformedPosition.xyz, vec3(0.0), bottomRight, bottomLeft);
	  float leftDistance = planeDistance(deformedPosition.xyz, vec3(0.0), topLeft, bottomLeft);
	  float rightDistance	= planeDistance(deformedPosition.xyz, vec3(0.0), topRight, bottomRight);

    // kinda stolen from bruce
    if (cameraPosition.x < portalX) {
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
#endif

// this function is used by both the vertex and the fragment shader
// I mainly use blockCentre for the maths because it hurts my head less
void doPortal(inout vec3 position, in vec3 worldSpacePosition, in float portalX, in vec3 blockCentre, in vec3 cameraPosition){

  float transitionStartX = portalX - RENDER_DISTANCE * 8 - 0.5;
  float transitionEndX  = portalX + RENDER_DISTANCE * 8 - 0.5;
  

  if (
    // check if terrain is within transition zone
    blockCentre.x > transitionStartX
    && blockCentre.x < transitionEndX
    && blockCentre.z >= (portalNullZoneCentre.x - (portalNullZoneWidth / 2)) - portalAreaWidth
    && blockCentre.z <= portalNullZoneCentre.x + (portalNullZoneWidth / 2) + portalAreaWidth
  ){

    int zoneSegment = getZoneSegment(worldSpacePosition);
    
    if (zoneSegment == 1){
      position.z += round(portalNullZoneWidth / 2) + portalAreaWidth / 2 ;
    } else if (zoneSegment == 3){
      position.z -= (portalNullZoneWidth + portalAreaWidth) / 2 + 0.5; // bruh
    } else {
    }

    #ifdef fsh


    bool visibleThroughPortal = isVisibleThroughPortal(position, portalX);
    bool playerBeforePortal = cameraPosition.x < portalX;// - 0.5;
    bool positionBeforePortal = worldSpacePosition.x < portalX;
      
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
}

void doExitPortal(inout vec3 position, in float portalX){
  #ifdef fsh
    if(isVisibleThroughPortal(position, portalX)){
      discard;
    }
  #endif
}

#if (defined vsh) || (defined composite1)
float doPortals(inout vec3 position, in vec3 cameraPosition, in vec3 midblock){
#else
float doPortals(in vec3 position, in vec3 cameraPosition, in vec3 midblock){
#endif
  
  float nearestPortalDistance = 0.5;

  vec3 worldSpacePosition = position + cameraPosition;
  vec3 blockCentre = worldSpacePosition + (midblock / 64);
  
  doPortal(position, worldSpacePosition, 3360.5, blockCentre, cameraPosition);
  doPortal(position, worldSpacePosition, 4480.5, blockCentre, cameraPosition);
  doPortal(position, worldSpacePosition, 5600.5, blockCentre, cameraPosition);
  doPortal(position, worldSpacePosition, 7840.5, blockCentre, cameraPosition);
  doPortal(position, worldSpacePosition, 10067.5, blockCentre, cameraPosition);
  //doExitPortal(position, 14720);

  return nearestPortalDistance;
}

float getPortalDistance(float playerX, float portalX){
    return clamp(abs(playerX - portalX) / (RENDER_DISTANCE * 16), 0, 1) / 2 + 0.5;
}

float getPortalDistances(float X){
  float shortestDistance = 1;
  return shortestDistance;
}
