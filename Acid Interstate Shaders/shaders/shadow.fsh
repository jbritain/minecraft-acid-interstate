#version 120

#define gbuffers_shadows
#include "shaders.settings"

#define FSH
#define shadow_FSH


varying vec3 worldpos;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
#include "/acid/portals.glsl"
in vec3 originalPosition;
in vec3 originalWorldSpacePosition;
in vec3 originalBlockCentre;
in vec3 newPosition;

#ifdef Shadows
varying vec4 texcoord;
uniform sampler2D texture;
uniform int blockEntityId;
uniform int entityId;
#endif

void main() {
	vec3 newPos = newPosition;
	doPortals(newPos, originalWorldSpacePosition, cameraPosition, originalBlockCentre);

#ifdef Shadows
	vec4 color = texture2D(texture, texcoord.xy);
	if(texcoord.z > 0.9)color.rgb = vec3(1.0, 1.0, 1.0);	//water shadows color
	if(texcoord.w > 0.9)color = vec4(0.0); 					//disable shadows on entities defined in vertex shadows
	if(entityId == 11000.0)color *= 0.0;					//remove lightning strike shadow.
	#if MC_VERSION < 11601									//blockEntityId broken in 1.16.1, causes shadow issue, used to remove beam shadows, 10089 is the id of all emissive blocks but only beam is a block entity
	if(blockEntityId == 10089.0) color *= 0.0;
	#endif
#else
	gl_FragData[0] = vec4(0.0);
#endif	
}