uniform mat4 gbufferProjection;
uniform mat4 modelViewMatrix;

float portalAreaWidth = 257; // width of terrain which is merged for portals
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



#ifdef FSH
  #include "/acid/acid.glsl"

  // converts from model space to NDC space
  vec3 toNDC(in vec3 position){
    vec3 viewPos = (gbufferModelView * vec4(position, 1.0)).xyz;
    vec4 clipPos = gbufferProjection * vec4(viewPos, 1.0);
    vec3 ndcPos = (clipPos.w != 0.0 && abs(clipPos.w) > 0.0001) ? (clipPos.xyz / clipPos.w) * 2.0 - 1.0 : vec3(0.0);
    return ndcPos;

    
  }

  // returns true if a point is within a quadrilateral made up of four points
  // adapted from https://stackoverflow.com/a/71069487/12646131
  // I don't think the order actually matters but the four parameters imply it does so change the order at your own risk
  bool pointInQuad(vec2 point, vec2 tl, vec2 tr, vec2 bl, vec2 br) {
    float vertx[4] = float[](tl.x, tr.x, br.x, bl.x);
    float verty[4] = float[](tl.y, tr.y, br.y, bl.y);

    int c = 0;
    int j = 3;
    
    for(int i = 0; i < 4; i++){
      if(
        (verty[i] > point.y) != (verty[j] > point.y)
        && (point.x < (vertx[j]-vertx[i]) * (point.y-verty[i]) / (verty[j]-verty[i]) + vertx[i]) 
      ){
        c = 1 - c;
      }

      j = i;
    }

    return c == 1;
  }


  // convert the position and portal corner positions into NDC space and check if the position is within the portal
  bool isVisibleThroughPortal(vec3 position, float portalX){
    
    vec3 worldSpacePosition = position + cameraPosition.xyz;

    // get the portal corners in world space then convert to model space
    vec3 topLeft3D = vec3(portalX, portalNullZoneCentre.y + portalHeight / 2, portalNullZoneCentre.x - (portalWidth / 2)) - cameraPosition.xyz;
    vec3 topRight3D = vec3(portalX, portalNullZoneCentre.y + portalHeight / 2, portalNullZoneCentre.x + (portalWidth / 2)) - cameraPosition.xyz;
    vec3 bottomLeft3D = vec3(portalX, portalNullZoneCentre.y - portalHeight / 2, portalNullZoneCentre.x - (portalWidth / 2)) - cameraPosition.xyz;
    vec3 bottomRight3D = vec3(portalX, portalNullZoneCentre.y - portalHeight / 2, portalNullZoneCentre.x + (portalWidth / 2)) - cameraPosition.xyz;

    //deform portal corners
    doAcid(topLeft3D, cameraPosition);
    doAcid(topRight3D, cameraPosition);
    doAcid(bottomLeft3D, cameraPosition);
    doAcid(bottomRight3D, cameraPosition);
    
    // deform position we are checking
    vec3 deformedPosition = position;
    doAcid(deformedPosition, cameraPosition);

    // convert the portal corners into NDC space
    vec2 topLeft = toNDC(topLeft3D).xy;
    vec2 topRight = toNDC(topRight3D).xy;
    vec2 bottomLeft = toNDC(bottomLeft3D).xy;
    vec2 bottomRight = toNDC(bottomRight3D).xy;

    // get the position in NDC space
    vec2 deformedPosition2D = toNDC(deformedPosition).xy;

    // check if the new position is within the four corners
    return pointInQuad(deformedPosition2D, topLeft, topRight, bottomLeft, bottomRight);
  }
#endif

// this function is used by both the vertex and the fragment shader
// I mainly use blockCentre for the maths because it hurts my head less
float doPortal(in float transitionStartX, in float transitionEndX, inout vec3 position, in vec3 worldSpacePosition, in float portalX, in vec3 blockCentre, in vec3 cameraPosition){

  // dynamic fog - returns 0 if we are within 256 blocks of a portal (within 128 of a transition), interpolating up to 1.0 at 384
  #ifdef composite1
    return smoothstep(256, 300, abs(cameraPosition.x - portalX));
  #endif
  
  if (
    // check if terrain is within transition zone
    blockCentre.x > transitionStartX
    && blockCentre.x < transitionEndX
    && blockCentre.z >= (portalNullZoneCentre.x - (portalNullZoneWidth / 2)) - portalAreaWidth
    && blockCentre.z <= portalNullZoneCentre.x + (portalNullZoneWidth / 2) + portalAreaWidth
  ){
    #ifdef VSH
        int zoneSegment = getZoneSegment(worldSpacePosition);

        if (zoneSegment == 1){
          position.z += (portalNullZoneWidth + portalAreaWidth) / 2 ;
        } else if (zoneSegment == 3){
          position.z -= (portalNullZoneWidth + portalAreaWidth) / 2 ;
        } else {}
    #endif

    

    #ifdef FSH

    bool visibleThroughPortal = isVisibleThroughPortal(position, portalX);
    int zoneSegment = getZoneSegment(worldSpacePosition);
    bool playerBeforePortal = cameraPosition.x < portalX - 0.5;
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
    else if (zoneSegment == 3){
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
  return 1;
}

float doPortals(inout vec3 position, in vec3 worldSpacePosition, in vec3 cameraPosition, in vec3 blockCentre){
  float nearestPortalDistance = 1;
  nearestPortalDistance = min(doPortal(1216, 1472, position, worldSpacePosition, 1344.5, blockCentre, cameraPosition), nearestPortalDistance);
  nearestPortalDistance = min(doPortal(2384, 2640, position, worldSpacePosition, 2512.5, blockCentre, cameraPosition), nearestPortalDistance);
  nearestPortalDistance = min(doPortal(3608, 3864, position, worldSpacePosition, 3737, blockCentre, cameraPosition), nearestPortalDistance);

  return nearestPortalDistance;
}

