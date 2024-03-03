#include "/lib/Syntax.glsl"


varying vec3 color;
varying vec2 texcoord;
varying vec2 vertLightmap;

varying mat3 tbnMatrix;
varying mat3 oldTbnMatrix;

varying mat2x3 position;

varying vec3 worldDisplacement;

flat varying float materialIDs;

#include "/lib/Uniform/Shading_Variables.glsl"


/***********************************************************************/
#if defined vsh

attribute vec4 mc_Entity;
attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;

uniform sampler2D lightmap;

uniform mat4 gbufferModelViewInverse;

uniform vec3  cameraPosition;
uniform vec3  previousCameraPosition;
uniform float far;

out vec3 portaledOldWorldSpacePosition;
out vec3 oldWorldSpacePosition;
out vec3 oldCameraPosition;

out float entityID;

out vec3 originalNormal;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Uniform/Projection_Matrices.vsh"

#if defined gbuffers_water
uniform sampler3D gaux1;

#include "/UserProgram/centerDepthSmooth.glsl"
#include "/lib/Uniform/Shadow_View_Matrix.vsh"
#include "/lib/Fragment/PrecomputedSky.glsl"
#include "/lib/Vertex/Shading_Setup.vsh"
#endif


vec2 GetDefaultLightmap() {
	vec2 lightmapCoord = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
	
	return clamp01(lightmapCoord / vec2(0.8745, 0.9373)).rg;
}

#include "/block.properties"

vec3 GetWorldSpacePosition() {
	vec3 position = transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);
	
#if  defined gbuffers_water
	position -= gl_NormalMatrix * gl_Normal * (norm(gl_Normal) * 0.00005 * float(abs(mc_Entity.x - 8.5) > 0.6));
#elif defined gbuffers_spidereyes
	position += gl_NormalMatrix * gl_Normal * (norm(gl_Normal) * 0.0002);
#endif
	
	return mat3(gbufferModelViewInverse) * position;
}

vec4 ProjectViewSpace(vec3 viewSpacePosition) {
#if !defined gbuffers_hand
	return vec4(projMAD(projMatrix, viewSpacePosition), viewSpacePosition.z * projMatrix[2].w);
#else
	return vec4(projMAD(gl_ProjectionMatrix, viewSpacePosition), viewSpacePosition.z * gl_ProjectionMatrix[2].w);
#endif
}

#include "/lib/Vertex/Waving.vsh"
#include "/lib/Vertex/Vertex_Displacements.vsh"

mat3 CalculateTBN(vec3 worldPosition) {
	vec3 tangent  = normalize(at_tangent.xyz);
	vec3 binormal = normalize(-cross(gl_Normal, at_tangent.xyz));
	
	tangent  += CalculateVertexDisplacements(worldPosition +  tangent) - worldDisplacement;
	binormal += CalculateVertexDisplacements(worldPosition + binormal) - worldDisplacement;
	
	tangent  = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix *  tangent);
	binormal =           mat3(gbufferModelViewInverse) * gl_NormalMatrix * binormal ;
	
	vec3 normal = normalize(cross(-tangent, binormal));
	
	binormal = cross(tangent, normal); // Orthogonalize binormal
	
	return mat3(tangent, binormal, normal);
}


void main() {
	originalNormal = normalize(gl_NormalMatrix * gl_Normal);

	entityID		= mc_Entity.x;
	materialIDs  = BackPortID(int(mc_Entity.x));
	
#ifdef HIDE_ENTITIES
//	if (isEntity(materialIDs)) { gl_Position = vec4(-1.0); return; }
#endif
	
	SetupProjection();
	
	color        = abs(mc_Entity.x - 10.5) > 0.6 ? gl_Color.rgb : vec3(1.0);
	texcoord     = gl_MultiTexCoord0.st;
	vertLightmap = GetDefaultLightmap();
	
	show(int(mc_Entity.x) == 9)
	vec3 worldSpacePosition = GetWorldSpacePosition();
	
	oldWorldSpacePosition = worldSpacePosition;
	doPortals(worldSpacePosition, cameraPosition, at_midBlock);
	portaledOldWorldSpacePosition = worldSpacePosition;
	
	oldCameraPosition = cameraPosition;
	oldTbnMatrix = CalculateTBN(oldWorldSpacePosition);
	
	worldDisplacement = CalculateVertexDisplacements(worldSpacePosition);
	
	
	position[1] = worldSpacePosition + worldDisplacement;
	position[0] = position[1] * mat3(gbufferModelViewInverse);

	
	gl_Position = ProjectViewSpace(position[0]);
	tbnMatrix = CalculateTBN(worldSpacePosition);
	
	
#if defined gbuffers_water
	SetupShading();
#endif
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

uniform sampler2D tex;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2DShadow shadow;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;

uniform vec3 cameraPosition;

uniform float nightVision;

uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

uniform vec3 at_midBlock;

uniform ivec2 atlasSize;

uniform float wetness;
uniform float far;

in float entityID;

#include "/lib/Settings.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Uniform/Projection_Matrices.fsh"
#define gbuffers_main
#include "/lib/Misc/CalculateFogfactor.glsl"
#include "/lib/Fragment/Masks.fsh"

#ifndef PORTALS_INCLUDED
	#include "/acid/portals.glsl"
	#define PORTALS_INCLUDED
#endif
in vec3 oldWorldSpacePosition;

#if defined gbuffers_water
uniform sampler3D gaux1;

#include "/lib/Uniform/Shadow_View_Matrix.fsh"
#include "/lib/Fragment/ComputeShadedFragment.fsh"
#include "/lib/Fragment/ComputeWaveNormals.fsh"
#endif


float LOD;

#ifdef TERRAIN_PARALLAX
	#define GetTexture(x, y) texture2DLod(x, y, LOD)
#else
	#define GetTexture(x, y) texture2D(x, y)
#endif

vec4 GetDiffuse(vec2 coord) {
	vec4 col = vec4(color.rgb, 1.0) * GetTexture(tex, coord);
	return col;
}

vec3 GetNormal(vec2 coord) {
	vec3 normal = vec3(0.0, 0.0, 1.0);
	
#ifndef NORMAL_MAPS
	normal = GetTexture(normals, coord).xyz * 2.0 - 1.0;
#endif
	
	return tbnMatrix * normal;
}

vec3 GetTangentNormal() {
#ifndef NORMAL_MAPS
	return vec3(0.5, 0.5, 1.0);
#endif
	
	return texture2D(normals, texcoord).rgb;
}

float GetSpecularity(vec2 coord) {
	float specularity = 0.0;
	
#ifdef SPECULARITY_MAPS
	return specularity = GetTexture(specular, coord).r;
#endif
	
	return clamp01(specularity + wetness);
}


#include "/lib/Fragment/TerrainParallax.fsh"
#include "/lib/Misc/Euclid.glsl"

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
	vec4 homPos = projectionMatrix * vec4(position, 1.0);
	return homPos.xyz / homPos.w;
}

#if defined gbuffers_water
	/* DRAWBUFFERS:0389 */
#else
	/* DRAWBUFFERS:1489 */
#endif

#include "/lib/Exit.glsl"

in vec3 midblock;
in vec3 portaledOldWorldSpacePosition;
in vec3 originalNormal;

void main() {
	vec3 preAcidScreenSpacePos = portaledOldWorldSpacePosition;
	
	doPortals(oldWorldSpacePosition, cameraPosition, midblock);
	vec3 oldNormal = vec3(0.0, 0.0, 1.0);//oldTbnMatrix * vec3(0.0, 0.0, 1.0);

	if (CalculateFogfactor(position[0]) >= 1.0)
		{ discard; }
	
	vec2  coord       = ComputeParallaxCoordinate(texcoord, position[1]);
	vec4  diffuse     = GetDiffuse(coord); if (diffuse.a < 0.1) { discard; }
	vec3  normal      = GetNormal(coord);
	float specularity = GetSpecularity(coord);
	
#if !defined gbuffers_water
	float encodedMaterialIDs = EncodeMaterialIDs(materialIDs, vec4(0.0, 0.0, 0.0, 0.0));
	
	gl_FragData[0] = vec4(diffuse.rgb, 1.0);
	gl_FragData[1] = vec4(Encode4x8F(vec4(encodedMaterialIDs, specularity, vertLightmap.rg)), EncodeNormal(normal, 11.0), 0.0, 1.0);
#else
	specularity = clamp(specularity, 0.0, 1.0 - 1.0 / 255.0);
	
	Mask mask = EmptyMask;
	
	if (materialIDs == 4.0) {
		if (!gl_FrontFacing) discard;
		
		diffuse     = vec4(0.215, 0.356, 0.533, 0.75);
		normal      = tbnMatrix * ComputeWaveNormals(position[1], tbnMatrix[2]);
		specularity = 1.0;
		mask.water  = 1.0;
	}

	mat2x3 oldPosition;
	oldPosition[1] = preAcidScreenSpacePos;
	oldPosition[0] = mat3(gbufferModelView) * oldPosition[1];
	
	vec3 composite = ComputeShadedFragment(powf(diffuse.rgb, 2.2), mask, vertLightmap.r, vertLightmap.g, vec4(0.0, 0.0, 0.0, 1.0), normal * mat3(gbufferModelViewInverse), specularity, oldPosition);
	
	vec2 encode;
	encode.x = Encode4x8F(vec4(specularity, vertLightmap.g, mask.water, 0.1));
	encode.y = EncodeNormal(normal, 11.0);
	
	if (materialIDs == 4.0) {
		composite *= 0.0;
		diffuse.a = 0.0;
	}
	
	gl_FragData[0] = vec4(encode, 0.0, 1.0);
	gl_FragData[1] = vec4(composite, diffuse.a);
	
#endif
	gl_FragData[2] = vec4(preAcidScreenSpacePos.xyz, 1.0);

	#ifdef gbuffers_water
	gl_FragData[3] = vec4(normal, 1.0);
	#else
	gl_FragData[3] = vec4(originalNormal, 1.0);
	#endif
	
	exit();
}

#endif
/***********************************************************************/
