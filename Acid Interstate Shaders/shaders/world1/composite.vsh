#version 120

#define lightingColors
#include "/shaders.settings"

varying vec2 texcoord;
varying vec3 sunVec;
varying vec3 upVec;
varying vec3 sunlight;
varying float tr;
varying float sunVisibility;
varying float moonVisibility;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.16,0.005),
								vec3(0.58597,0.31,0.08),
								vec3(0.58597,0.45,0.16),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));

void main() {
	//Position
	gl_Position = ftransform();
	texcoord = (gl_MultiTexCoord0).xy;
	/*--------------------------------*/

	//Sun/moon pos
	sunVec = normalize(sunPosition);
	upVec = vec3(0.0, 1.0, 0.0); //fix for loading shaderpacks in nether and end, optifine bug.

	float SdotU = dot(sunVec,upVec);
	sunVisibility = pow(clamp(SdotU+0.15,0.0,0.15)/0.15,4.0);
	moonVisibility = pow(clamp(-SdotU+0.15,0.0,0.15)/0.15,4.0);
	/*--------------------------------*/

	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1

	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];

	sunlight = mix(temp,temp2,fract(hour));
	sunlight.rgb += vec3(r_multiplier,g_multiplier,b_multiplier); //allows lighting colors to be tweaked.
	sunlight.rgb *= light_brightness; //brightness needs to be adjusted if we tweak lighting colors.

	vec2 trCalc = min(abs(worldTime-vec2(23000.0,12700.0)),750.0);
	tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);	
}
