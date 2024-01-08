#version 120
/* DRAWBUFFERS:56 */

#define gbuffers_texturedblock
#include "/shaders.settings"

varying vec4 color;
varying vec2 texcoord;
varying vec3 ambientNdotL;
uniform sampler2D texture;

void main() {

	vec4 albedo = texture2D(texture, texcoord.xy)*color;

	vec3 finalColor = pow(albedo.rgb,vec3(2.2)) * ambientNdotL.rgb;

	gl_FragData[0] = vec4(finalColor, albedo.a);
	gl_FragData[1] = vec4(normalize(albedo.rgb+0.00001), albedo.a);		
}