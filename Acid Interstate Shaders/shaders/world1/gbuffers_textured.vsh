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
uniform float screenBrightness;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

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

#ifdef HandLight
uniform int isEyeInWater;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

void main() {

	//setup basics
	color = gl_Color;
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
#ifdef TAA
	gl_Position.xy += offsets[framemod8] * gl_Position.w*texelSize;
#endif	
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	/*--------------------------------*/
	
	//Emissive blocks lighting in order to fix lighting on particles
	#ifdef HandLight
	bool underwaterlava = (isEyeInWater == 1.0 || isEyeInWater == 2.0);
	if(!underwaterlava) lmcoord.x = max(lmcoord.x, max(max(float(heldBlockLightValue), float(heldBlockLightValue2)) - 1.0 - length(gl_ModelViewMatrix * gl_Vertex), 0.0) / 15.0);
	#endif
	float torch_lightmap = 16.0-min(15.,(lmcoord.s-0.5/16.)*16.*16./15);
	float fallof1 = clamp(1.0 - pow(torch_lightmap/16.0,4.0),0.0,1.0);
	torch_lightmap = fallof1*fallof1/(torch_lightmap*torch_lightmap+1.0);
	vec3 emissiveLightC = vec3(emissive_R,emissive_G,emissive_B)*torch_lightmap;
	float finalminlight = (nightVision > 0.01)? 0.025 : ((minlight+0.006)+(screenBrightness*0.0125))*0.5;
	/*---------------------------------------------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	vec3 sunlight = mix(temp,temp2,fract(hour));
	const vec3 rainC = vec3(0.01,0.01,0.01);
	sunlight = mix(sunlight,rainC*sunlight,rainStrength);
	/*-------------------------------------------------------------------*/	
	
	const vec3 moonlight = vec3(0.0024, 0.00432, 0.0078);

	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = vec3(0.0, 1.0, 0.0); //fix for loading shaderpacks in nether and end, optifine bug.

	vec2 visibility = vec2(dot(sunVec,upVec),dot(-sunVec,upVec));

	float NdotL = dot(normal,sunVec);
	float NdotU = dot(normal,upVec);

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	visibility = pow(clamp(visibility+0.15,0.0,0.15)/0.15,vec2(4.0));

	float skyL = max(lmcoord.t-2./16.0,0.0)*1.14285714286;
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);
	
	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.14*skyL*skyL,0.34,0.7,0.1) + vec4(0.6,0.66,0.7,0.25);
	bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);

	vec3 sun_ambient = bounced.w * (vec3(0.1, 0.5, 1.1)+rainStrength*vec3(0.05,-0.27,-0.8))*2.3+ 1.7*sunlight*(sqrt(bounced.w)*bounced.x*2.4 + bounced.z)*(1.0-rainStrength*0.98);
	vec3 moon_ambient = (moonlight*0.7 + moonlight*bounced.y)*(1.0-rainStrength*0.95)*2.0;
	
	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03+tr*0.17)*0.65;
	ambientNdotL.rgb =  amb1 + emissiveLightC + finalminlight;

	sunlight = mix(sunlight,moonlight*(1.0-rainStrength*0.9),visibility.y)*tr;

}