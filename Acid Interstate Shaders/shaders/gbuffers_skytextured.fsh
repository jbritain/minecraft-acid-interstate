#version 120
/* DRAWBUFFERS:3 */

#define gbuffers_skytextured
#include "shaders.settings"

varying vec4 color;
varying vec2 texcoord;
uniform sampler2D texture;

void main() {
#ifdef defskybox
	gl_FragData[0] = texture2D(texture,texcoord.xy)*color;
#else
	gl_FragData[0] = vec4(0.0);
#endif	
}