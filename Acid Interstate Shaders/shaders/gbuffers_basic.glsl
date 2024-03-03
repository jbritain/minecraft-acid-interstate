#include "/lib/Syntax.glsl"


varying mat2x3 position;

varying vec3 color;


/***********************************************************************/
#if defined vsh

attribute vec4 mc_Entity;

uniform mat4 gbufferModelViewInverse;

uniform vec3  cameraPosition;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Uniform/Projection_Matrices.vsh"

vec3 GetWorldSpacePosition() {
	vec3 position = transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);
	
	return mat3(gbufferModelViewInverse) * position;
}

vec4 ProjectViewSpace(vec3 viewSpacePosition) {
	return vec4(projMAD(projMatrix, viewSpacePosition), viewSpacePosition.z * projMatrix[2].w);
}

#include "/UserProgram/Terrain_Deformation.vsh"
#include "/lib/Vertex/Vertex_Displacements.vsh"

void main() {
	SetupProjection();
	
	color = gl_Color.rgb;
	
	vec3 position  = GetWorldSpacePosition();
	     position += CalculateVertexDisplacements(position);
	     position  = position * mat3(gbufferModelViewInverse);
	
	gl_Position = ProjectViewSpace(position);
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

/* DRAWBUFFERS:1 */

void main() {
	gl_FragData[0] = vec4(color.rgb, 1.0);
}

#endif
/***********************************************************************/
