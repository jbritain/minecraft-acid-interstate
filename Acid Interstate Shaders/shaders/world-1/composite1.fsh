#version 120
#extension GL_ARB_shader_texture_lod : enable
const bool gaux1MipmapEnabled = true;
/* DRAWBUFFERS:3 */

#define composite2
#define composite1
#define lightingColors
#include "/shaders.settings"

varying vec2 texcoord;

uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D gdepth;

uniform sampler2D noisetex;
uniform sampler2D gaux3;
uniform sampler2D gaux2;

uniform vec3 cameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform float screenBrightness;
uniform int isEyeInWater;
uniform float near;
uniform float far;

uniform float frameTimeCounter;
uniform float blindness;
uniform vec3 fogColor;
#if MC_VERSION >= 11900
uniform float darknessFactor;
uniform float darknessLightFactor; 
#endif
/*------------------------------------------*/
float comp = 1.0-near/far/far;

#if defined waterRefl || defined iceRefl
const int maxf = 3;				//number of refinements
const float ref = 0.11;			//refinement multiplier
const float inc = 3.0;			//increasement factor at each step

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}
vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}
float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

vec4 raytrace(vec3 fragpos, vec3 skycolor, vec3 rvector) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
	rvector *= 1.2;
    fragpos += rvector;
	vec3 tvector = rvector;
    int sr = 0;

    for(int i=0;i<25;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 fragpos0 = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        fragpos0 = nvec3(gbufferProjectionInverse * nvec4(fragpos0 * 2.0 - 1.0));
        float err = distance(fragpos,fragpos0);
		if(err < pow(length(rvector),1.175)){ //if(err < pow(length(rvector)*1.85,1.15)){ <- old, adjusted error check to reduce banding issues/glitches
                sr++;
                if(sr >= maxf){
					bool land = texture2D(depthtex1, pos.st).r < comp;
                    color = pow(texture2DLod(gaux1, pos.st, 1),vec4(2.2))*257.0;
					if (isEyeInWater == 0) color.rgb = land ? mix(color.rgb,skycolor,0.5) : skycolor; //reflections color, blend it with fake sky color.
					color.a = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
					break;
                }
				tvector -= rvector;
                rvector *= ref;

}
        rvector *= inc;
        tvector += rvector;
		fragpos = start + tvector;
    }
    return color;
}
#endif

#ifdef Refraction
mat2 rmatrix(float rad){
	return mat2(vec2(cos(rad), -sin(rad)), vec2(sin(rad), cos(rad)));
}

float calcWaves(vec2 coord){
	vec2 movement = abs(vec2(0.0, -frameTimeCounter * 0.5));

	coord *= 0.4;
	vec2 coord0 = coord * rmatrix(1.0) - movement * 4.5;
		 coord0.y *= 3.0;
	vec2 coord1 = coord * rmatrix(0.5) - movement * 1.5;
		 coord1.y *= 3.0;		 
	vec2 coord2 = coord * frameTimeCounter * 0.02;
	
	coord0 *= waveSize;
	coord1 *= (waveSize-0.5); //create an offset for smaller waves

	float wave = texture2D(noisetex,coord0 * 0.005).x * 10.0;			//big waves
		  wave -= texture2D(noisetex,coord1 * 0.010416).x * 7.0;			//small waves
		  wave += 1.0-sqrt(texture2D(noisetex,coord2 * 0.0416).x * 6.5) * 1.33;	//noise texture
		  wave *= 0.0157;

	return wave;
}

vec2 calcBump(vec2 coord){
	const vec2 deltaPos = vec2(0.25, 0.0);

	float h0 = calcWaves(coord);
	float h1 = calcWaves(coord + deltaPos.xy);
	float h2 = calcWaves(coord - deltaPos.xy);
	float h3 = calcWaves(coord + deltaPos.yx);
	float h4 = calcWaves(coord - deltaPos.yx);

	float xDelta = ((h1-h0)+(h0-h2));
	float yDelta = ((h3-h0)+(h0-h4));

	return vec2(xDelta,yDelta)*0.05;
}
#endif

vec3 decode (vec2 enc){
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}

void main() {

vec3 c = pow(texture2D(gaux1,texcoord).xyz,vec3(2.2))*257.;

//Depth and fragpos
float depth0 = texture2D(depthtex0, texcoord).x;
vec4 fragpos0 = gbufferProjectionInverse * (vec4(texcoord, depth0, 1.0) * 2.0 - 1.0);
fragpos0 /= fragpos0.w;
vec3 normalfragpos0 = normalize(fragpos0.xyz);

float depth1 = texture2D(depthtex1, texcoord).x;
vec4 fragpos1 = gbufferProjectionInverse * (vec4(texcoord, depth1, 1.0) * 2.0 - 1.0);
	 fragpos1 /= fragpos1.w;
vec3 normalfragpos1 = normalize(fragpos1.xyz);
/*--------------------------------------------------------------------------------------------*/
vec4 trp = texture2D(gaux3,texcoord.xy);
bool transparency = dot(trp.xyz,trp.xyz) > 0.000001;

#if MC_VERSION >= 11600
if (depth1 > comp){
	c.rgb = fogColor*0.02;	//use default MC fogcolor for sky aswell
}
	vec3 fogC = fogColor*0.5;
#else
if (depth1 > comp){
	c.r = 0.002+(screenBrightness*0.001); //draw nether sky, keep it similar to fog color, scale with brightness
}
	vec3 fogC = vec3(0.05, 0.0, 0.0);
#endif

#ifdef Refraction
if (texture2D(colortex2, texcoord).z < 0.2499 && dot(texture2D(colortex2,texcoord).xyz,texture2D(colortex2,texcoord).xyz) > 0.0 || isEyeInWater == 1.0) { //reflective water
	vec2 wpos = (gbufferModelViewInverse*fragpos0).xz+cameraPosition.xz;
	vec2 refraction = texcoord.xy + calcBump(wpos);	

	c = pow(texture2D(gaux1, refraction).xyz, vec3(2.2))*257.0;
}
#endif

//Render before transparency
float mats = texture2D(colortex0,texcoord).b;
bool isMetallic = mats > 0.39 && mats < 0.41;
bool isPolished = mats > 0.49 && mats < 0.51;
#ifndef polishedRefl
	isPolished = false;
#endif	
#ifndef metallicRefl
	isMetallic = false;
#endif

#if defined metallicRefl || defined polishedRefl
	if (isMetallic || isPolished) {
		vec3 relfNormal = decode(texture2D(colortex1,texcoord).xy);
		vec3 reflectedVector = reflect(normalfragpos0, relfNormal);
		
		float normalDotEye = dot(relfNormal, normalfragpos0);
		float fresnel = pow(clamp(1.0 + normalDotEye,0.0,1.0), 4.0);
			  fresnel = mix(0.09,1.0,fresnel); //F0
	
		vec3 sky_c = fogC*metallicSky;
		vec4 reflection = raytrace(fragpos0.xyz, sky_c, reflectedVector);

		reflection.rgb = mix(sky_c, reflection.rgb, reflection.a)*0.5;
		c = mix(c,reflection.rgb,fresnel*metalStrength);
	}
#endif

if (transparency) {
	vec3 normal = texture2D(colortex2,texcoord).xyz;
	float sky = normal.z;

	bool reflectiveWater = sky < 0.2499 && dot(normal,normal) > 0.0;
	bool reflectiveIce = sky > 0.2499 && sky < 0.4999 && dot(normal,normal) > 0.0;

	bool iswater = sky < 0.2499;
	bool isice = sky > 0.2499 && sky < 0.4999;

	if (iswater) sky *= 4.0;
	if (isice) sky = (sky - 0.25)*4.0;

	if (!iswater && !isice) sky = (sky - 0.5)*4.0;

	sky = clamp(sky*1.2-2./16.0*1.2,0.,1.0);
	sky *= sky;

	normal = decode(normal.xy);

	normal = normalize(normal);
	
	//draw fog for transparency
	c = mix(c, fogC*0.04, 1.0-exp(-length(fragpos1.xyz)*0.0005));
	if(depth1 < comp)c = mix(fogC*0.04, c, exp(-exp2(length(fragpos1.xyz) / far * 16.0 - 14.0)));

	//Draw transparency
	vec3 finalAc = texture2D(gaux2, texcoord.xy).rgb;
	float alphaT = clamp(length(trp.rgb)*1.02,0.0,1.0);

	c = mix(c,c*(trp.rgb*0.9999+0.0001)*1.732,alphaT)*(1.0-alphaT) + finalAc;	

	//Reflections
	float iswater2 = float(iswater);	
	if (reflectiveWater || reflectiveIce) {
		vec3 reflectedVector = reflect(normalfragpos1, normal);
		vec3 hV= normalize(reflectedVector - normalfragpos1);

		float normalDotEye = dot(hV, normalfragpos1);

		float F0 = 0.09;

		float fresnel = pow(clamp(1.0 + normalDotEye,0.0,1.0), 4.0) ;
		fresnel = fresnel+F0*(1.0-fresnel);
	
		vec3 sky_c = fogC*0.2; //Use fogC as our custom sky reflections
	#if defined waterRefl || defined iceRefl
		vec4 reflection = raytrace(fragpos0.xyz, sky_c, reflectedVector);
	#else
		vec4 reflection = vec4(0.0);
		fresnel *= 0.5;
	#endif
		reflection.rgb = mix(sky_c, reflection.rgb, reflection.a)*0.5;

	#ifdef iceRefl
		fresnel *= 0.5*float(isice) + 0.5*iswater2;
	#else
		fresnel *= 1.0*iswater2;
	#endif
		c = mix(c,reflection.rgb,fresnel*1.5);
	}
  }

	#ifdef Fog
	if(depth0 < comp)c = mix(c, fogC*(1.0-isEyeInWater), 1.0-exp(-length(fragpos0.xyz)*0.0005));
	//Chunk border fog
	if(depth0 < comp)c = mix(fogC*0.04, c, exp(-exp2(length(fragpos0.xyz) / far * 16.0 - 14.0)));
	#endif

	#ifdef Underwater_Fog
	vec3 ufogC = vec3(0.0, 0.005, 0.0125);
	if (isEyeInWater == 1.0) c = mix(c, ufogC, 1.0-exp(-length(fragpos0.xyz)/uFogDensity));
	#endif
	
	if (isEyeInWater == 2.0) c = mix(c, vec3(1.0, 0.0125, 0.0), 1.0-exp(-length(fragpos0.xyz))); //lava fog
	if(blindness > 0.9) c = mix(c, vec3(0.0), 1.0-exp(-length(fragpos1.xyz)*1.125));	//blindness fog
#if MC_VERSION >= 11900
 	if(darknessFactor > 0.9) c = mix(c, vec3(0.0), 1.0-exp(-length(fragpos1.xyz)*0.2)) * (1.0-darknessLightFactor*2.0); //Darkness fog, adjust for nether.
#endif	

	c *= 0.142;
	gl_FragData[0] = vec4(c,1.0);
}
