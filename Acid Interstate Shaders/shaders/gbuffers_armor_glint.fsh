#version 120
/* DRAWBUFFERS:5 */

uniform sampler2D texture;

varying vec4 color;
varying vec2 texcoord;

uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;

float night = clamp((worldTime-13000.0)/300.0,0.0,1.0)-clamp((worldTime-22800.0)/200.0,0.0,1.0);
float cavelight = pow(eyeBrightnessSmooth.y / 255.0, 6.0f) * 1.0 + (0.7 + 0.5*night);

void main() {

vec4 albedo = texture2D(texture, texcoord.st)*color;

//Fix minecrafts way of handling enchanted effects and turn it into a somewhat consistent effect across day/night/cave/raining
vec3 lighting = vec3(1.0+ (0.4*rainStrength - 0.4*rainStrength*night));
	 lighting /= 0.8 - 0.5*night;
	 lighting /= cavelight;

	albedo.rgb = pow(albedo.rgb*0.33, lighting);

	gl_FragData[0] = albedo;
}