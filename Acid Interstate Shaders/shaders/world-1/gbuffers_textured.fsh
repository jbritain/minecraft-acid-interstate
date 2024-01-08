#version 120
/* DRAWBUFFERS:56 */
//Render hand, entities and particles in here, boost and fix enchanted armor effect in gbuffers_armor_glint

#define gbuffers_texturedblock
#include "/shaders.settings"

varying vec4 color;
varying vec2 texcoord;
varying vec3 ambientNdotL;

uniform sampler2D texture;
uniform vec4 entityColor;
uniform int worldTime;
uniform int entityId; 

void main() {
	
	vec4 albedo = texture2D(texture, texcoord.xy)*color;
	#ifdef MobsFlashRed
		albedo.rgb = mix(albedo.rgb,entityColor.rgb,entityColor.a);
	#endif

	vec3 finalColor = pow(albedo.rgb,vec3(2.2)) * ambientNdotL.rgb;

	//Lightning rendering
	if(entityId == 11000.0){
		float night = clamp((worldTime-13000.0)/300.0,0.0,1.0)-clamp((worldTime-22800.0)/200.0,0.0,1.0);
		finalColor = vec3(0.025, 0.03, 0.05) * (1.0-0.75*night);
		albedo.a = 1.0;
	}

	gl_FragData[0] = vec4(finalColor, albedo.a);
	gl_FragData[1] = vec4(normalize(albedo.rgb+0.00001), albedo.a);		
}