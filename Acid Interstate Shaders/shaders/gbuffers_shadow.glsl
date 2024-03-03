#include "/lib/Syntax.glsl"


varying vec4 color;
varying vec2 texcoord;
varying vec2 vertLightmap;

flat varying vec3 vertNormal;

#define gbuffers_shadow


/***********************************************************************/
#if defined vsh

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;

uniform float sunAngle;

out vec3 oldShadowWorldSpacePosition;
out vec3 shadowMidBlock;

float materialIDs;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"

#include "/UserProgram/centerDepthSmooth.glsl"
#include "/lib/Uniform/Projection_Matrices.vsh"
#include "/lib/Uniform/Shadow_View_Matrix.vsh"

vec2 GetDefaultLightmap() {
	vec2 lightmapCoord = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
	
	return clamp01((lightmapCoord * pow2(1.031)) - 0.032).rg;
}

vec3 GetWorldSpacePositionShadow() {
	return transMAD(shadowModelViewInverse, transMAD(gl_ModelViewMatrix, gl_Vertex.xyz));
}

#include "/block.properties"
#include "/lib/Vertex/Waving.vsh"
#include "/lib/Vertex/Vertex_Displacements.vsh"

#include "/lib/Misc/ShadowBias.glsl"

vec4 ProjectShadowMap(vec4 position) {
	// position = vec4(projMAD(shadowProjection, transMAD(shadowViewMatrix, position.xyz)), position.z * shadowProjection[2].w + shadowProjection[3].w);
	
	float biasCoeff = GetShadowBias(position.xy);
	
	// position.xy /= biasCoeff;
	
	float acne  = 25.0 * pow(clamp01(1.0 - vertNormal.z), 4.0) * float(mc_Entity.x > 0.0);
	      acne += 0.5 + pow2(biasCoeff) * 8.0;
	
	//position.z += acne / shadowMapResolution;
	
	// position.z /= zShrink; // Shrink the domain of the z-buffer. This counteracts the noticable issue where far terrain would not have shadows cast, especially when the sun was near the horizon
	
	// return position;

	vec3 shadowViewPos = (shadowView * vec4(position.xyz, 1.0)).xyz;
	vec4 shadowClipPos = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
	//shadowClipPos.z += acne / shadowMapResolution;
	return shadowClipPos;
}

vec2 ViewSpaceToScreenSpace(vec3 viewSpacePosition) {
	return (diagonal2(projMatrix) * viewSpacePosition.xy + projMatrix[3].xy) / -viewSpacePosition.z;
}

vec3 ViewSpaceToScreenSpace3(vec3 viewSpacePosition) {
	return (diagonal3(projMatrix) * viewSpacePosition.xyz + projMatrix[3].xyz) / -viewSpacePosition.z;
}

bool CullVertex(vec3 wPos) {
#ifdef GI_ENABLED
	return false;
#endif
	
	vec3 vRay = transpose(mat3(shadowViewMatrix))[2] * mat3(gbufferModelViewInverse); // view space light vector
	
	vec3 vPos = wPos * mat3(gbufferModelViewInverse);
	
	vPos.z -= 4.0;
	
	bool onscreen = all(lessThan(abs(ViewSpaceToScreenSpace(vPos)), vec2(1.0))) && vPos.z < 0.0;
	
	// c = distances to intersection with 4 frustum sides, vec4(xy = -1.0, xy = 1.0)
	vec4 c =  vec4(diagonal2(projMatrix) * vPos.xy + projMatrix[3].xy, diagonal2(projMatrix) * vRay.xy);
	     c = -vec4((c.xy - vPos.z) / (c.zw - vRay.z), (c.xy + vPos.z) / (c.zw + vRay.z)); // Solve for (M*(vPos + ray*c) + A) / (vPos.z + ray.z*c) = +-1.0
	
	vec3 b1 = vPos + vRay * c.x;
	vec3 b2 = vPos + vRay * c.y;
	vec3 b3 = vPos + vRay * c.z;
	vec3 b4 = vPos + vRay * c.w;
	
	vec4 otherCoord = vec4( // vec4(y coord of x = -1.0 intersection,   x coord of y = -1.0,   y coord of x = 1.0,   x coord of y = 1.0)
		(projMatrix[1].y * b1.y + projMatrix[3].y) / -b1.z,
		(projMatrix[0].x * b2.x + projMatrix[3].x) / -b2.z,
		(projMatrix[1].y * b3.y + projMatrix[3].y) / -b3.z,
		(projMatrix[0].x * b4.x + projMatrix[3].x) / -b4.z);
	
	vec3 yDot = transpose(mat3(gbufferModelViewInverse))[1];
	
	vec4 w = vec4(dot(b1, yDot), dot(b2, yDot), dot(b3, yDot), dot(b4, yDot)); // World space y intersection points
	
	bvec4 yBounded   = lessThan(abs(w + cameraPosition.y - 128.0), vec4(128.0)); // Intersection happens within y[0.0, 256.0]
	bvec4 inFrustum  = lessThan(abs(otherCoord), vec4(1.0)); // Example: check the y coordinate of the x-hits to make sure the intersection happens within the 2 adjacent frustum edges
	bvec4 correctDir = and(lessThan(vec4(b1.z, b2.z, b3.z, b4.z), vec4(0.0)), lessThan(c, vec4(0.0)));
	
	bool castscreen = any(and(and(inFrustum, correctDir), yBounded));
	
	return !(onscreen || castscreen);
}

void main() {
	if (mc_Entity.x == 66) { gl_Position = vec4(-1.0); return; }
	
	materialIDs = BackPortID(int(mc_Entity.x));
	
#ifndef WATER_SHADOW
	if (isWater(materialIDs)) { gl_Position = vec4(-1.0); return; }
#endif
	
#ifdef HIDE_ENTITIES
//	if (mc_Entity.x < 0.5) { gl_Position = vec4(-1.0); return; }
#endif
	
	CalculateShadowView();
	SetupProjection();
	
	color        = gl_Color;
	texcoord     = gl_MultiTexCoord0.st;
	vertLightmap = GetDefaultLightmap();
	
	vertNormal   = normalize(mat3(shadowViewMatrix) * gl_Normal);
	
	vec3 position = GetWorldSpacePositionShadow();

	oldShadowWorldSpacePosition = position;
	doPortals(position, cameraPosition, at_midBlock);
	

	shadowMidBlock = at_midBlock;


	gl_Position = ProjectShadowMap(position.xyzz);
	
	//if (CullVertex(position)) { gl_Position.z += 100000.0; return; }

	
	
	color.rgb *= clamp01(vertNormal.z);
	
	if (   mc_Entity.x == 0 // If the vertex is an entity
	// 	&& abs(position.x) < 1.2
	// 	&& position.y > -0.1 &&  position.y < 2.2 // Check if the vertex is A bounding box around the player, so that at least non-near entities still cast shadows
	// 	&& abs(position.z) < 1.2) {
	// #ifndef PLAYER_SHADOW
	){
		color.a = 0.0;
	// #elif !defined PLAYER_GI_BOUNCE
	// 	color.rgb = vec3(0.0);
	// #endif
	}
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

uniform sampler2D tex;

uniform vec3 cameraPosition;

#ifndef PORTALS_INCLUDED
	#include "/acid/portals.glsl"
	#define PORTALS_INCLUDED
#endif

in vec3 oldShadowWorldSpacePosition;
in vec3 shadowMidBlock;


void main() {
	vec4 diffuse = color * texture2D(tex, texcoord);

	doPortals(oldShadowWorldSpacePosition, cameraPosition, shadowMidBlock);
	
	gl_FragData[0] = diffuse;
	gl_FragData[1] = vec4(vertNormal.xy * 0.5 + 0.5, 0.0, 1.0);
}

#endif
/***********************************************************************/