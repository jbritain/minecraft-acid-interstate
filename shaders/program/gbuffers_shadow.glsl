#include "/lib/Syntax.glsl"

#include "/lib/Settings.glsl"

#include "/lib/iPBR/IDs.glsl"
#include "/lib/iPBR/Groups.glsl"


varying vec4 color;
varying vec2 texcoord;
varying vec2 vertLightmap;

flat varying vec3 vertNormal;
varying float materialIDs;

varying vec3 position;
varying vec3 prePortalPosition;
varying vec3 shadowPosition;
varying vec3 midblock;


/***********************************************************************/
#if defined vsh

attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;
attribute vec4 at_tangent;
attribute vec3 at_midBlock;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform int entityId;
uniform int renderStage;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float sunAngle;

uniform float thunderStrength;



#include "/lib/Utility.glsl"

#include "/lib/Voxel/VoxelPosition.glsl"
#include "/lib/iPBR/lightColors.glsl"


#include "/lib/Uniform/Shadow_View_Matrix.vsh"

bool EVEN_FRAME = frameCounter % 2 == 0;

vec2 GetDefaultLightmap() {
	vec2 lightmapCoord = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
	
	return clamp01((lightmapCoord * pow2(1.031)) - 0.032).rg;
}

vec3 GetWorldSpacePositionShadow() {
	return transMAD(shadowModelViewInverse, transMAD(gl_ModelViewMatrix, gl_Vertex.xyz));
}



#include "/lib/Vertex/Waving.vsh"
#include "/lib/Vertex/Vertex_Displacements.vsh"

#include "/lib/Misc/ShadowBias.glsl"
#include "/lib/Acid/portals.glsl"

vec4 ProjectShadowMap(vec4 position) {
	position = vec4(projMAD(shadowProjection, transMAD(shadowViewMatrix, position.xyz)), position.z * shadowProjection[2].w + shadowProjection[3].w);
	
	float biasCoeff = GetShadowBias(position.xy);
	
	position.xy /= biasCoeff;
	
	// float acne  = 25.0 * pow4(clamp01(1.0 - vertNormal.z));
	//       acne += 0.5 + pow2(biasCoeff) * 8.0;
	
	// position.z += acne / shadowMapResolution;
	position.z += biasCoeff * 32.0 / shadowMapResolution;
	
	position.z /= zShrink; // Shrink the domain of the z-buffer. This counteracts the noticable issue where far terrain would not have shadows cast, especially when the sun was near the horizon
	
	return position;
}

vec2 ViewSpaceToScreenSpace(vec3 viewSpacePosition) {
	return (diagonal2(gbufferProjection) * viewSpacePosition.xy + gbufferProjection[3].xy) / -viewSpacePosition.z;
}

vec3 ViewSpaceToScreenSpace3(vec3 viewSpacePosition) {
	return (diagonal3(gbufferProjection) * viewSpacePosition.xyz + gbufferProjection[3].xyz) / -viewSpacePosition.z;
}

bool CullVertex(vec3 wPos) {
#ifdef GI_ENABLED
	return false;
#endif
	
	vec3 vRay = mat3(gbufferModelView) * transpose(mat3(shadowViewMatrix))[2]; // view space light vector
	
	vec3 vPos = mat3(gbufferModelView) * wPos;
	
	vPos.z -= 4.0;
	
	bool onscreen = all(lessThan(abs(ViewSpaceToScreenSpace(vPos)), vec2(1.0))) && vPos.z < 0.0;
	
	// c = distances to intersection with 4 frustum sides, vec4(xy = -1.0, xy = 1.0)
	vec4 c =  vec4(diagonal2(gbufferProjection) * vPos.xy + gbufferProjection[3].xy, diagonal2(gbufferProjection) * vRay.xy);
	     c = -vec4((c.xy - vPos.z) / (c.zw - vRay.z), (c.xy + vPos.z) / (c.zw + vRay.z)); // Solve for (M*(vPos + ray*c) + A) / (vPos.z + ray.z*c) = +-1.0
	
	vec3 b1 = vPos + vRay * c.x;
	vec3 b2 = vPos + vRay * c.y;
	vec3 b3 = vPos + vRay * c.z;
	vec3 b4 = vPos + vRay * c.w;
	
	vec4 otherCoord = vec4( // vec4(y coord of x = -1.0 intersection,   x coord of y = -1.0,   y coord of x = 1.0,   x coord of y = 1.0)
		(gbufferProjection[1].y * b1.y + gbufferProjection[3].y) / -b1.z,
		(gbufferProjection[0].x * b2.x + gbufferProjection[3].x) / -b2.z,
		(gbufferProjection[1].y * b3.y + gbufferProjection[3].y) / -b3.z,
		(gbufferProjection[0].x * b4.x + gbufferProjection[3].x) / -b4.z);
	
	vec3 yDot = transpose(mat3(gbufferModelViewInverse))[1];
	
	vec4 w = vec4(dot(b1, yDot), dot(b2, yDot), dot(b3, yDot), dot(b4, yDot)); // World space y intersection points
	
	bvec4 yBounded   = lessThan(abs(w + cameraPosition.y - 128.0), vec4(128.0)); // Intersection happens within y[0.0, 256.0]
	bvec4 inFrustum  = lessThan(abs(otherCoord), vec4(1.0)); // Example: check the y coordinate of the x-hits to make sure the intersection happens within the 2 adjacent frustum edges
	bvec4 correctDir = and(lessThan(vec4(b1.z, b2.z, b3.z, b4.z), vec4(0.0)), lessThan(c, vec4(0.0)));
	
	bool castscreen = any(and(and(inFrustum, correctDir), yBounded));
	
	return !(onscreen || castscreen);
}

void main() {
	#ifndef SHADOWS
		gl_Position = ftransform();
		return;
	#endif

	midblock = at_midBlock.xyz;
	
	materialIDs  = mc_Entity.x;
	
#ifdef HIDE_ENTITIES
//	if (mc_Entity.x < 0.5) { gl_Position = vec4(-1.0); return; }
#endif
	
	CalculateShadowView();
	
	
	color        = gl_Color;
	texcoord     = gl_MultiTexCoord0.st;
	vertLightmap = GetDefaultLightmap();
	
	vertNormal   = normalize(mat3(shadowViewMatrix) * gl_Normal);
	
	
	position  = GetWorldSpacePositionShadow();
	prePortalPosition = position;
	position += cameraPosition;
	doPortals(position, at_midBlock.xyz);
	position -= cameraPosition;
	    //  position += CalculateVertexDisplacements(position);


	gl_Position = ProjectShadowMap(position.xyzz);
	
	// if (CullVertex(position)) { gl_Position.z += 100000.0; return; }
	
	
	color.rgb *= clamp01(vertNormal.z);
	
	if(renderStage == MC_RENDER_STAGE_ENTITIES){
		gl_Position = vec4(-1.0);
	}

	shadowPosition = gl_Position.xyz;
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

uniform sampler2D gtexture;
uniform vec3 fogColor;
uniform ivec2 eyeBrightnessSmooth;
uniform sampler2D noisetex;
uniform float far;
uniform float near;
uniform vec3 cameraPosition;

#include "/lib/Utility.glsl"
#include "/lib/Fragment/ComputeWaveNormals.fsh"
#include "/lib/Acid/portals.glsl"

layout(r32ui) uniform uimage2D portalShadowMap;

#define pow2(x) x*x

void writeToImageShadowMap(){
    float depth = gl_FragCoord.z;
    uint depthInt = floatBitsToUint(depth);
    uint oldDepth = imageAtomicMin(portalShadowMap, ivec2(floor(shadowPosition.xy * PORTAL_SHADOW_RESOLUTION / 2) + PORTAL_SHADOW_RESOLUTION / 2), depthInt);

    if (oldDepth == 0){ // this is not how atomics work but in this case it is fine but not really but it works
      imageStore(portalShadowMap, ivec2(floor(shadowPosition.xy * PORTAL_SHADOW_RESOLUTION / 2) + PORTAL_SHADOW_RESOLUTION / 2), uvec4(depthInt, uvec3(0)));
    }
}

void main() {
	#ifndef SHADOWS
	discard;
	#endif

	vec4 diffuse = color * texture(gtexture, texcoord);

	// what we need is for the stuff on the *other side of the portal* to write to the portal shadow map
	// if we are before the portal, this is the stuff on our right
	// otherwise this is the stuff on our left
	// of course, this only applies if the position is within a portal transition zone

	float nearestPortalX = getNearestPortalX(cameraPosition.x);

	vec3 blockCentre = prePortalPosition + cameraPosition + midblock / 64;

	if(
		((cameraPosition.x < nearestPortalX && blockCentre.z > 2) ||
		(cameraPosition.x > nearestPortalX && blockCentre.z < -1)) &&
		abs(blockCentre.x - nearestPortalX + 0.5) < PORTAL_RENDER_DISTANCE * 16 / 2
	){
		writeToImageShadowMap();
		discard;
	}
	

	// if (materialIDs == IPBR_WATER) {
	// 	diffuse = vec4(mix(WATER_COLOR.rgb, color.rgb, BIOME_WATER_TINT), WATER_COLOR.a);
	// 	#ifdef WATER_CAUSTICS
	// 		SetupWaveFBM();
	// 		float height = GetWaves(position.xz + cameraPosition.xz);
	// 		height *= height * height * height;
	// 		diffuse.a = (1.0 - height);
	// 		diffuse.a = pow2(diffuse.a);
	// 	#endif
	// }
	
	gl_FragData[0] = diffuse;
	gl_FragData[1] = vec4(vertNormal.xy * 0.5 + 0.5, 0.0, 1.0);
}

#endif
/***********************************************************************/
