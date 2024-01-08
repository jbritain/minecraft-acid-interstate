#version 120

#define final
#include "shaders.settings"

varying vec2 texcoord;

#ifdef Rain_Drops
varying vec2 rainPos1;
varying vec2 rainPos2;
varying vec2 rainPos3;
varying vec2 rainPos4;
varying vec4 weights;
uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
uniform float frameTimeCounter;

vec2 noisepattern(vec2 pos) {
	return vec2(abs(fract(sin(dot(pos, vec2(83147.6995379f, 125370.887575f))))));
}
#endif

#ifdef Bloom
varying float eyeAdaptBloom;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.16,0.025),
								vec3(0.58597,0.4,0.2),
								vec3(0.58597,0.52344,0.24680),
								vec3(0.58597,0.55422,0.34),
								vec3(0.58597,0.57954,0.38),
								vec3(0.58597,0.58,0.40),
								vec3(0.58597,0.58,0.40));
														
float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}
#endif

void main() {

	gl_Position = ftransform();
	texcoord = (gl_MultiTexCoord0).xy;

#ifdef Bloom
	texcoord = (gl_MultiTexCoord0).xy;
	
	//Sun/Moon position
	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);
	
	float SdotU = dot(sunVec,upVec);
	float sunVisibility = pow(clamp(SdotU+0.15,0.0,0.15)/0.15,4.0);
	float moonVisibility = pow(clamp(-SdotU+0.15,0.0,0.15)/0.15,4.0);
	/*--------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	vec3 sunlight  = mix(temp,temp2,fract(hour));
	/*--------------------------------*/
	
	//Lighting
	float eyebright = max(eyeBrightnessSmooth.y/255.0-0.5/16.0,0.0)*1.03225806452;
	float SkyL2 = mix(1.0,eyebright*eyebright,eyebright);	

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	
	vec4 bounced = vec4(0.5*SkyL2,0.66*SkyL2,0.7,0.3);

	vec3 sun_ambient = bounced.w * (vec3(0.25,0.62,1.32)-rainStrength*vec3(0.11,0.32,1.07)) + sunlight*(bounced.x + bounced.z);

	const vec3 moonlight = vec3(0.0035, 0.0063, 0.0098);
	
	vec3 avgAmbient =(sun_ambient*sunVisibility + moonlight*moonVisibility)*eyebright*eyebright*(0.05+tr*0.15)*4.7+0.0006;

	eyeAdaptBloom = log(clamp(luma(avgAmbient),0.007,80.0))/log(2.6)*0.35;
	eyeAdaptBloom = 1.0/pow(2.6,eyeAdaptBloom)*1.75;
#endif

#ifdef Rain_Drops
	const float lifetime = 4.0;		//water drop lifetime in seconds
	float ftime = frameTimeCounter*2.0/lifetime;  
	vec2 drop = vec2(0.0,fract(frameTimeCounter/20.0));
	rainPos1 = fract((noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25))))*0.8+0.1 - drop);
	rainPos2 = fract((noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5))))*0.8+0.1- drop);
	rainPos3 = fract((noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75))))*0.8+0.1- drop);
	rainPos4 = fract((noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5))))*0.8+0.1- drop);
	weights.x = 1.0-fract((ftime+0.5)*0.5);
	weights.y = 1.0-fract((ftime+1.0)*0.5);
	weights.z = 1.0-fract((ftime+1.5)*0.5);
	weights.w = 1.0-fract(ftime*0.5);
	weights *= rainStrength*clamp((eyeBrightnessSmooth.y-220)/15.0,0.0,1.0);
#endif
}
