#version 120

#define composite2
#define gbuffers_texturedblock
#define lightingColors
#include "/shaders.settings"

varying vec4 color;
varying vec2 texcoord;
varying vec3 ambientNdotL;

uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform int worldTime;
uniform float rainStrength;
uniform float nightVision;

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.15,0.02),
								vec3(0.58597,0.35,0.09),
								vec3(0.58597,0.5,0.26),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));
#ifdef TAA
uniform float viewWidth;
uniform float viewHeight;
vec2 texelSize = vec2(1.0/viewWidth,1.0/viewHeight);
uniform int framemod8;
const vec2[8] offsets = vec2[8](vec2(1./8.,-3./8.),
								vec2(-1.,3.)/8.,
								vec2(5.0,1.)/8.,
								vec2(-3,-5.)/8.,
								vec2(-5.,5.)/8.,
								vec2(-7.,-1.)/8.,
								vec2(3,7.)/8.,
								vec2(7.,-7.)/8.);
#endif							

void main() {

	//setup basics
	color = gl_Color;
	gl_Position = ftransform();
#ifdef TAA
	gl_Position.xy += offsets[framemod8] * gl_Position.w*texelSize;
#endif	
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	/*--------------------------------*/
	
	//Emissive blocks lighting
	float torch_lightmap = 16.0-min(15.,(lmcoord.s-0.5/16.)*16.*16./15);
	float fallof1 = clamp(1.0 - pow(torch_lightmap/16.0,4.0),0.0,1.0);
	torch_lightmap = fallof1*fallof1/(torch_lightmap*torch_lightmap+1.0);
	//vec3 emissiveLightC = vec3(emissive_R,emissive_G,emissive_B)*torch_lightmap;
	vec3 emissiveLightC = vec3(0.5, 0.0, 1.0); //purple eyes
	float finalminlight = (nightVision > 0.01)? 0.025 : (minlight+0.006)*10.0; //multiply by 10 to improve eye rendering

	ambientNdotL.rgb = emissiveLightC + finalminlight;

}