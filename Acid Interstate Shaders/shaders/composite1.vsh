#version 120

#define lightingColors
#include "shaders.settings"

varying vec2 texcoord;
varying vec2 lightPos;

varying vec3 sunVec;
varying vec3 upVec;
varying vec3 lightColor;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 nsunlight;
varying vec3 sunlight;
varying vec3 rawAvg;
varying vec3 avgAmbient2;
varying vec3 cloudColor;
varying vec3 cloudColor2;

varying float fading;
varying float tr;
varying float eyeAdapt;
varying float SdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;
uniform float rainStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform mat4 gbufferProjection;

const float redtint = 1.5;
const vec3 ToD[7] = vec3[7](  vec3(redtint,0.15,0.02),
								vec3(redtint,0.35,0.09),
								vec3(redtint,0.5,0.26),
								vec3(redtint,0.5,0.35),
								vec3(redtint,0.5,0.36),
								vec3(redtint,0.5,0.37),
								vec3(redtint,0.5,0.38));


								
						
float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}


void main() {

	//Light pos for Godrays
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	lightPos = pos1*0.5+0.5;
	/*-------------------------------*/

	//Positioning
	gl_Position = ftransform();
	texcoord = (gl_MultiTexCoord0).xy;
	/*--------------------------------*/

	//Sun/Moon position
	sunVec = normalize(sunPosition);
	upVec = normalize(upPosition);
	
	SdotU = dot(sunVec,upVec);
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
	sunlight.rgb += vec3(r_multiplier,g_multiplier,b_multiplier);
	sunlight.rgb *= light_brightness;
	
	vec3 sunlight04 = pow(sunlight,vec3(0.454));
	/*-----------------------------------------------------------------*/
	
	//Lighting
	float eyebright = max(eyeBrightnessSmooth.y/255.0-0.5/16.0,0.0)*1.03225806452;
	float SkyL2 = mix(1.0,eyebright*eyebright,eyebright);

	vec2 trCalc = min(abs(worldTime-vec2(23050.0,12700.0)),750.0);
	tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	float tr = clamp(min(min(distance(float(worldTime),23050.0),750.0),min(distance(float(worldTime),12700.0),800.0))/800.0-0.5,0.0,1.0)*2.0;

	vec4 bounced = vec4(0.5,0.66,1.3,0.27);
	vec3 sun_ambient = bounced.w * (vec3(0.25,0.62,1.32)-rainStrength*vec3(0.1,0.47,1.17))*(1.0+rainStrength*7.0) + sunlight*(bounced.x + bounced.z)*(1.0-rainStrength*0.95);

	const vec3 moonlight = vec3(0.0016, 0.00288, 0.00448);
	vec3 moon_ambient = (moonlight + moonlight*eyebright*eyebright*eyebright);
	
	float tr2 = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);

	vec4 bounced2 = vec4(0.5*SkyL2,0.66*SkyL2,0.7,0.3);
	vec3 sun_ambient2 = bounced2.w * (vec3(0.25,0.62,1.32)-rainStrength*vec3(0.11,0.32,1.07)) + sunlight*(bounced2.x + bounced2.z);
	vec3 moon_ambient2 = (moonlight*3.5);

	rawAvg = (sun_ambient*sunVisibility + 8.0*moonlight*moonVisibility)*(0.05+tr*0.15)*4.7+0.0002;	
	vec3 avgAmbient =(sun_ambient2*sunVisibility + moon_ambient2*moonVisibility)*eyebright*eyebright*(0.05+tr2*0.15)*4.7+0.0006;
	avgAmbient2 = (sun_ambient*sunVisibility + 6.0*moon_ambient*moonVisibility)*eyebright *(0.27+tr*0.65)+0.0002;

	eyeAdapt = log(clamp(luma(avgAmbient),0.007,80.0))/log(2.6)*0.35;
	eyeAdapt = 1.0/pow(eyeLight,eyeAdapt)*1.75;
	avgAmbient /= sqrt(3.0);
	avgAmbient2 /= sqrt(3.0);
	/*--------------------------------*/

	//Light pos for godrays
	float truepos = sign(sunPosition.z)*1.0;		//1 -> sun / -1 -> moon	
	lightColor = mix(sunlight*sunVisibility+0.00001,12.*moonlight*moonVisibility+0.00001,(truepos+1.0)/2.);
	if (length(lightColor)>0.001)lightColor = mix(lightColor,normalize(vec3(0.3,0.3,0.3))*pow(normalize(lightColor),vec3(0.4))*length(lightColor)*0.03,rainStrength)*(0.25+0.25*tr);
	/*------------------------------------------------*/
	
	//Sky lighting
	float mcosS = max(SdotU,0.0);				

	float skyMult = max(SdotU*0.1+0.1,0.0)/0.2*(1.0-rainStrength*0.6)*0.7;
	nsunlight = normalize(pow(mix(sunlight04 ,5.*sunlight04 *sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.35),rainStrength),vec3(2.2)))*0.6*skyMult;
	
	vec3 sky_color = vec3(0.15, 0.4, 1.);
	sky_color = normalize(mix(sky_color,2.*sunlight04 *sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.3)*length(sunlight04 ),rainStrength)); //normalize colors in order to don't change luminance
	
	sky1 = sky_color*0.6*skyMult;
	sky2 = mix(sky_color,mix(nsunlight,sky_color,rainStrength*0.9),1.0-max(mcosS-0.2,0.0)*0.5)*0.6*skyMult;
	
	cloudColor = sunlight04 *sunVisibility*(1.0-rainStrength*0.17)*length(rawAvg) + rawAvg*0.7*(1.0-rainStrength*0.1) + 2.0*moonlight*moonVisibility*(1.0-rainStrength*0.17);
	cloudColor2 = 0.1*sunlight*sunVisibility*(1.0-rainStrength*0.15)*length(rawAvg) + 1.5*length(rawAvg)*mix(vec3(0.15, 0.4, 1.),vec3(0.65, 0.65, 0.65),rainStrength)*(1.0-rainStrength*0.1) + 2.0*moonlight*moonVisibility*(1.0-rainStrength*0.15);
	
	vec2 centerLight = abs(lightPos*2.0-1.0);
    float distof = max(centerLight.x,centerLight.y);
	fading = clamp(1.0-distof*distof*distof*0.,0.0,1.0);
	/*-----------------------------------------------------*/
}