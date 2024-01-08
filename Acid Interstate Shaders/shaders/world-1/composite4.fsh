#version 120
/* DRAWBUFFERS:6 */
//overwrite buffer 6, final image is buffer 7

#define Bloom
#define bloom_strength 0.75
#define composite4
#include "/shaders.settings"

#ifdef Bloom
varying vec2 texcoord;
varying float eyeAdapt;

uniform sampler2D colortex6;

uniform int isEyeInWater;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;
#endif

void main() {

#ifdef Bloom
	const int nSteps = 17;
	const int center = 8;		//=nSteps-1 / 2

	//huge gaussian blur for glare
	vec3 blur = vec3(0.0);
	float tw = 0.0;
	for (int i = 0; i < nSteps; i++) {
		float dist = abs(i-float(center))/center;
		float weight = (exp(-(dist*dist)/ 0.28));
		vec3 bsample = texture2D(colortex6,(texcoord.xy + vec2(1.0/viewWidth,1.0/viewHeight)*vec2(0.0,i-center))).rgb*3.0;

		blur += bsample*weight;
		tw += weight;
	}
	blur /= tw;

	vec3 glow = blur * bloom_strength;
	vec3 overglow = glow*pow(length(glow)*2.0,2.8)*2.0;

	vec3 finalColor = (overglow+glow*1.15)*(1+isEyeInWater*10.0+(pow(rainStrength,3.0)*7.0/pow(eyeAdapt,1.0)))*1.2;

	gl_FragData[0] = vec4(finalColor, 1.0);
#else
	gl_FragData[0] = vec4(0.0);
#endif
}
