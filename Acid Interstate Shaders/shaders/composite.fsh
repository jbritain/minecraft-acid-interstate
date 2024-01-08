#version 120
/* DRAWBUFFERS:34 */

#define gbuffers_shadows
#define composite0
#define composite2
#define lightingColors
#include "shaders.settings"

varying vec2 texcoord;
varying vec3 lightColor;
varying vec3 sunVec;
varying vec3 upVec;
varying vec3 sky1;
varying vec3 sky2;

varying float tr;

varying vec2 lightPos;

varying vec3 sunlight;
varying vec3 nsunlight;

varying vec3 rawAvg;

varying float SdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D composite;

#ifdef HandLight
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

#ifdef Shadows
uniform sampler2DShadow shadow;		//shadows
uniform sampler2DShadow shadowtex1; //colored shadows
uniform sampler2D shadowcolor0;
#endif

uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform ivec2 eyeBrightness;
uniform float nightVision;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;

float comp = 1.0-near/far/far;			//distance above that are considered as sky

const vec2 check_offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
									vec2(-0.1717194f,0.6272162f),
									vec2(-0.4709477f,-0.01774091f),
									vec2(-0.9910634f,0.03831699f),
									vec2(-0.2101292f,0.2034733f),
									vec2(-0.7889516f,-0.5671548f),
									vec2(-0.1037751f,-0.1583221f),
									vec2(-0.5728408f,0.3416965f),
									vec2(-0.1863332f,0.5697952f),
									vec2(0.3561834f,0.007138769f),
									vec2(0.2868255f,-0.5463203f),
									vec2(-0.4640967f,-0.8804076f),
									vec2(0.1969438f,0.6236954f),
									vec2(0.6999109f,0.6357007f),
									vec2(-0.3462536f,0.8966291f),
									vec2(0.172607f,0.2832828f),
									vec2(0.4149241f,0.8816f),
									vec2(0.136898f,-0.9716249f),
									vec2(-0.6272043f,0.6721309f),
									vec2(-0.8974028f,0.4271871f),
									vec2(0.5551881f,0.324069f),
									vec2(0.9487136f,0.2605085f),
									vec2(0.7140148f,-0.312601f),
									vec2(0.0440252f,0.9363738f),
									vec2(0.620311f,-0.6673451f)
									);

#define diagonal3(mat) vec3((mat)[0].x, (mat)[1].y, (mat)[2].z)

#ifdef Shadows
	#if defined Penumbra && defined MC_GL_VENDOR_NVIDIA && defined MC_OS_WINDOWS
		#extension GL_EXT_gpu_shader4 : enable
		#define ffstep(x,y) clamp((y - x) * 1e35,0.0,1.0)
		uniform sampler2D shadowtex0; //This is actually the same as shadow2Dsampler shadow, but nvidia allows different sampler types per texture unit.		
	#endif

vec2 tapLocation(int sampleNumber, int nb, float jitter){
    float alpha = (sampleNumber+jitter)/nb;
    float angle = jitter*6.28 + alpha * 4.0 * 6.28;
    return vec2(cos(angle), sin(angle))*sqrt(alpha);
}
#endif

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

#ifndef Volumetric_Lighting
#ifdef Godrays
float cdist(vec2 coord) {
	vec2 vec = abs(coord*2.0-1.0);
	float d = max(vec.x,vec.y);
	return 1.0 - d*d;
}
#endif
#endif

vec3 getSkyColor(vec3 fposition) {
const vec3 moonlightS = vec3(0.00575, 0.0105, 0.014);
vec3 sVector = normalize(fposition);

float invRain07 = 1.0-rainStrength*0.4;
float cosT = dot(sVector,upVec);
float mCosT = max(cosT,0.0);
float absCosT = 1.0-max(cosT*0.82+0.26,0.2);
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);

const float a = -1.;
const float b = -0.22;
const float c = 8.0;
const float d = -3.5;
const float e = 0.3;

//luminance
float L =  (1.0+a*exp(b/(mCosT)));
float A = 1.0+e*cosY*cosY;

//gradient
vec3 grad1 = mix(sky1,sky2,absCosT*absCosT);
float sunscat = max(cosY,0.0);
vec3 grad3 = mix(grad1,nsunlight*(1.0-isEyeInWater),sunscat*sunscat*(1.0-mCosT)*(0.9-rainStrength*0.5*0.9)*(clamp(-(SdotU)*4.0+3.0,0.0,1.0)*0.65+0.35)+0.1);

float Y2 = 3.14159265359-Y;
float L2 = L * (8.0*exp(d*Y2)+A);

const vec3 moonlight2 = pow(normalize(moonlightS),vec3(3.0))*length(moonlightS);
const vec3 moonlightRain = normalize(vec3(0.25,0.3,0.4))*length(moonlightS);

vec3 gradN = mix(moonlightS,moonlight2,1.-L2/2.0);
gradN = mix(gradN,moonlightRain,rainStrength);
return pow(L*(c*exp(d*Y)+A),invRain07)*sunVisibility *length(rawAvg) * (0.85+rainStrength*0.425)*grad3+ 0.2*pow(L2*1.2+1.2,invRain07)*moonVisibility*gradN;
}

vec3 decode (vec2 enc){
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}


#ifdef Lens_Flares
void LensFlare(inout vec3 color){
	vec2 ntc2 = texcoord*2.0-1.0;
	vec2 lPos = lightPos;
	  
	float sunmask = 1.0;
		  sunmask *= (1.0 - rainStrength);

	if (sunmask > 0.02){
	vec3 lenslc = sqrt(lightColor);
	//Adjust global flare settings
	float flaremultR = 0.04*lenslc.r;
	float flaremultG = 0.05*lenslc.g;
	float flaremultB = 0.075*lenslc.b;
	float flarescale = 1.0;
/*-------------------------------*/

	//Small sun glare/glow
		vec2 flare1scale = vec2(1.7*flarescale, 1.7*flarescale);
		float flare1pow = 12.0;
		vec2 flare1pos = vec2(lPos.x*aspectRatio*flare1scale.x, lPos.y*flare1scale.y);

		float flare1 = distance(flare1pos, vec2(ntc2.s*aspectRatio*flare1scale.x, ntc2.t*flare1scale.y));
              flare1 = 0.5 - flare1;
              flare1 = clamp(flare1, 0.0, 10.0)  ;
              flare1 *= sunmask;
              flare1 = pow(flare1, 1.8);

              flare1 *= flare1pow;
if(sunVisibility > 0.2){
			  color.r += flare1*1.0*flaremultR;
			  color.g += flare1*0.1*flaremultG;
			  color.b += flare1*0.0*flaremultB;
} else {
			  color.r += flare1*0.0*flaremultR;
			  color.g += flare1*0.1*flaremultG;
			  color.b += flare1*0.5*flaremultB;
}

	/*//Huge sun glare/glow
		vec2 flare1Bscale = vec2(0.5*flarescale, 0.5*flarescale);
		float flare1Bpow = 6.0;
		vec2 flare1Bpos = vec2(lPos.x*aspectRatio*flare1Bscale.x, lPos.y*flare1Bscale.y);

		float flare1B = distance(flare1Bpos, vec2(ntc2.s*aspectRatio*flare1Bscale.x, ntc2.t*flare1Bscale.y));
              flare1B = 0.5 - flare1B;
              flare1B = clamp(flare1B, 0.0, 10.0)  ;
              flare1B *= sunmask;
              flare1B = pow(flare1B, 1.8);

			  flare1B *= flare1Bpow;

			  color.r += flare1B*1.0*flaremultR;
			  color.g += flare1B*0.1*flaremultG;
			  color.b += flare1B*0.0*flaremultB;
	/*----------------------------------------------------------*/

	//Far blue flare MAIN
		vec2 flare3scale = vec2(2.0*flarescale, 2.0*flarescale);
		float flare3pow = 0.7;
		float flare3fill = 10.0;
		float flare3offset = -0.5;
		vec2 flare3pos = vec2(  ((1.0 - lPos.x)*(flare3offset + 1.0) - (flare3offset*0.5))  *aspectRatio*flare3scale.x,  ((1.0 - lPos.y)*(flare3offset + 1.0) - (flare3offset*0.5))  *flare3scale.y);

		float flare3 = distance(flare3pos, vec2(ntc2.s*aspectRatio*flare3scale.x, ntc2.t*flare3scale.y));
              flare3 = 0.5 - flare3;
              flare3 = clamp(flare3*flare3fill, 0.0, 1.0)  ;
              flare3 = sin(flare3*1.57075);
              flare3 *= sunmask;
              flare3 = pow(flare3, 1.1);

              flare3 *= flare3pow;

	//subtract from blue flare
		vec2 flare3Bscale = vec2(1.4*flarescale, 1.4*flarescale);
		float flare3Bpow = 1.0;
		float flare3Bfill = 2.0;
		float flare3Boffset = -0.65f;
		vec2 flare3Bpos = vec2(  ((1.0 - lPos.x)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *aspectRatio*flare3Bscale.x,  ((1.0 - lPos.y)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *flare3Bscale.y);

		float flare3B = distance(flare3Bpos, vec2(ntc2.s*aspectRatio*flare3Bscale.x, ntc2.t*flare3Bscale.y));
              flare3B = 0.5 - flare3B;
              flare3B = clamp(flare3B*flare3Bfill, 0.0, 1.0)  ;
              flare3B = sin(flare3B*1.57075);
              flare3B *= sunmask;
              flare3B = pow(flare3B, 0.9);

              flare3B *= flare3Bpow;

              flare3 = clamp(flare3 - flare3B, 0.0, 10.0);

              color.r += flare3*0.5*flaremultR;
              color.g += flare3*0.3*flaremultG;
              color.b += flare3*1.0*flaremultB;
	/*--------------------------------------------------------------------------*/

	//Far blue flare MAIN 2
		vec2 flare3Cscale = vec2(3.2*flarescale, 3.2*flarescale);
		float flare3Cpow = 1.4;
		float flare3Cfill = 10.0;
		float flare3Coffset = -0.0;
		vec2 flare3Cpos = vec2(  ((1.0 - lPos.x)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *aspectRatio*flare3Cscale.x,  ((1.0 - lPos.y)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *flare3Cscale.y);


		float flare3C = distance(flare3Cpos, vec2(ntc2.s*aspectRatio*flare3Cscale.x, ntc2.t*flare3Cscale.y));
              flare3C = 0.5 - flare3C;
              flare3C = clamp(flare3C*flare3Cfill, 0.0, 1.0)  ;
              flare3C = sin(flare3C*1.57075);

              flare3C = pow(flare3C, 1.1);

              flare3C *= flare3Cpow;

	//subtract from blue flare
		vec2 flare3Dscale = vec2(2.1*flarescale, 2.1*flarescale);
		float flare3Dpow = 2.7;
		float flare3Dfill = 1.4;
		float flare3Doffset = -0.05f;
		vec2 flare3Dpos = vec2(  ((1.0 - lPos.x)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *aspectRatio*flare3Dscale.x,  ((1.0 - lPos.y)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *flare3Dscale.y);

		float flare3D = distance(flare3Dpos, vec2(ntc2.s*aspectRatio*flare3Dscale.x, ntc2.t*flare3Dscale.y));
              flare3D = 0.5 - flare3D;
              flare3D = clamp(flare3D*flare3Dfill, 0.0, 1.0)  ;
              flare3D = sin(flare3D*1.57075);
              flare3D = pow(flare3D, 0.9);

              flare3D *= flare3Dpow;

              flare3C = clamp(flare3C - flare3D, 0.0, 10.0);
              flare3C *= sunmask;

              color.r += flare3C*0.5*flaremultR;
              color.g += flare3C*0.3*flaremultG;
              color.b += flare3C*1.0*flaremultB;
	/*--------------------------------------------------------------------*/

	//far small pink flare
		vec2 flare4scale = vec2(4.5*flarescale, 4.5*flarescale);
		float flare4pow = 0.3;
		float flare4fill = 3.0;
		float flare4offset = -0.1;
		vec2 flare4pos = vec2(  ((1.0 - lPos.x)*(flare4offset + 1.0) - (flare4offset*0.5))  *aspectRatio*flare4scale.x,  ((1.0 - lPos.y)*(flare4offset + 1.0) - (flare4offset*0.5))  *flare4scale.y);


		float flare4 = distance(flare4pos, vec2(ntc2.s*aspectRatio*flare4scale.x, ntc2.t*flare4scale.y));
              flare4 = 0.5 - flare4;
              flare4 = clamp(flare4*flare4fill, 0.0, 1.0)  ;
              flare4 = sin(flare4*1.57075);
              flare4 *= sunmask;
              flare4 = pow(flare4, 1.1);

              flare4 *= flare4pow;

              color.r += flare4*1.6*flaremultR;
              color.g += flare4*0.0*flaremultG;
              color.b += flare4*1.8*flaremultB;
	/*---------------------------------------------------------------*/

	//far small pink flare2
		vec2 flare4Bscale = vec2(7.5*flarescale, 7.5*flarescale);
		float flare4Bpow = 0.4;
		float flare4Bfill = 2.0;
		float flare4Boffset = 0.0;
		vec2 flare4Bpos = vec2(  ((1.0 - lPos.x)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *aspectRatio*flare4Bscale.x,  ((1.0 - lPos.y)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *flare4Bscale.y);

		float flare4B = distance(flare4Bpos, vec2(ntc2.s*aspectRatio*flare4Bscale.x, ntc2.t*flare4Bscale.y));
              flare4B = 0.5 - flare4B;
              flare4B = clamp(flare4B*flare4Bfill, 0.0, 1.0)  ;
              flare4B = sin(flare4B*1.57075);
              flare4B *= sunmask;
              flare4B = pow(flare4B, 1.1);

              flare4B *= flare4Bpow;

              color.r += flare4B*1.4*flaremultR;
              color.g += flare4B*0.0*flaremultG;
              color.b += flare4B*1.8*flaremultB;
	/*------------------------------------------------------------*/

	//far small pink flare3
		vec2 flare4Cscale = vec2(37.5*flarescale, 37.5*flarescale);
		float flare4Cpow = 2.0;
		float flare4Cfill = 2.0;
		float flare4Coffset = -0.3;
		vec2 flare4Cpos = vec2(  ((1.0 - lPos.x)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *aspectRatio*flare4Cscale.x,  ((1.0 - lPos.y)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *flare4Cscale.y);

		float flare4C = distance(flare4Cpos, vec2(ntc2.s*aspectRatio*flare4Cscale.x, ntc2.t*flare4Cscale.y));
              flare4C = 0.5 - flare4C;
              flare4C = clamp(flare4C*flare4Cfill, 0.0, 1.0)  ;
              flare4C = sin(flare4C*1.57075);
              flare4C *= sunmask;
              flare4C = pow(flare4C, 1.1);

              flare4C *= flare4Cpow;

              color.r += flare4C*1.6*flaremultR;
              color.g += flare4C*0.3*flaremultG;
              color.b += flare4C*1.1*flaremultB;
	/*----------------------------------------------------------------------------*/
			  
	//far small pink flare4
		vec2 flare4Dscale = vec2(67.5*flarescale, 67.5*flarescale);
		float flare4Dpow = 1.0;
		float flare4Dfill = 2.0;
		float flare4Doffset = -0.35f;
		vec2 flare4Dpos = vec2(  ((1.0 - lPos.x)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *aspectRatio*flare4Dscale.x,  ((1.0 - lPos.y)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *flare4Dscale.y);

		float flare4D = distance(flare4Dpos, vec2(ntc2.s*aspectRatio*flare4Dscale.x, ntc2.t*flare4Dscale.y));
			  flare4D = 0.5 - flare4D;
              flare4D = clamp(flare4D*flare4Dfill, 0.0, 1.0)  ;
              flare4D = sin(flare4D*1.57075);
              flare4D *= sunmask;
              flare4D = pow(flare4D, 1.1);

              flare4D *= flare4Dpow;

			  color.r += flare4D*1.2*flaremultR;
			  color.g += flare4D*0.2*flaremultG;
			  color.b += flare4D*1.2*flaremultB;
	/*------------------------------------------------------------------*/

	//far small pink flare5
		vec2 flare4Escale = vec2(60.5*flarescale, 60.5*flarescale);
		float flare4Epow = 1.0;
		float flare4Efill = 3.0;
		float flare4Eoffset = -0.3393f;
		vec2 flare4Epos = vec2(  ((1.0 - lPos.x)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *aspectRatio*flare4Escale.x,  ((1.0 - lPos.y)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *flare4Escale.y);

		float flare4E = distance(flare4Epos, vec2(ntc2.s*aspectRatio*flare4Escale.x, ntc2.t*flare4Escale.y));
              flare4E = 0.5 - flare4E;
              flare4E = clamp(flare4E*flare4Efill, 0.0, 1.0)  ;
              flare4E = sin(flare4E*1.57075);
              flare4E *= sunmask;
              flare4E = pow(flare4E, 1.1);

			  flare4E *= flare4Epow;

			  color.r += flare4E*1.2*flaremultR;
			  color.g += flare4E*0.2*flaremultG;
			  color.b += flare4E*1.0*flaremultB;
	/*----------------------------------------------------------*/

	//Sun glow
		vec2 flare5scale = vec2(3.2*flarescale , 3.2*flarescale );
		float flare5pow = 13.4;
		float flare5fill = 1.0;
		float flare5offset = -2.0;
		vec2 flare5pos = vec2(  ((1.0 - lPos.x)*(flare5offset + 1.0) - (flare5offset*0.5))  *aspectRatio*flare5scale.x,  ((1.0 - lPos.y)*(flare5offset + 1.0) - (flare5offset*0.5))  *flare5scale.y);

		float flare5 = distance(flare5pos, vec2(ntc2.s*aspectRatio*flare5scale.x, ntc2.t*flare5scale.y));
              flare5 = 0.5 - flare5;
              flare5 = clamp(flare5*flare5fill, 0.0, 1.0)  ;
              flare5 *= sunmask;
              flare5 = pow(flare5, 1.9);

              flare5 *= flare5pow;

			  color.r += flare5*2.0*flaremultR;
			  color.g += flare5*0.4*flaremultG;
			  color.b += flare5*0.1*flaremultB;
	/*-----------------------------------------------------*/
	
	//Anamorphic lens
		vec2 flareEscale = vec2(0.2*flarescale, 5.0*flarescale);
		float flareEpow = 5.0;
		float flareEfill = 0.75;
		vec2 flareEpos = vec2(lPos.x*aspectRatio*flareEscale.x, lPos.y*flareEscale.y);

		float flareE = distance(flareEpos, vec2(ntc2.s*aspectRatio*flareEscale.x, ntc2.t*flareEscale.y));
			  flareE = 0.5 - flareE;
			  flareE = clamp(flareE*flareEfill, 0.0, 1.0)  ;
			  flareE *= sunmask;
			  flareE = pow(flareE, 1.4);
			  flareE *= flareEpow;

			  color.r += flareE*0.0*flaremultR;
			  color.g += flareE*0.05*flaremultG;
			  color.b += flareE*1.0*flaremultB;
	/*----------------------------------------------*/

	//first red sweep
		vec2 flare_extra3scale = vec2(32.0*flarescale, 32.0*flarescale);
		float flare_extra3pow = 2.5;
		float flare_extra3fill = 1.1;
		float flare_extra3offset = -1.3;
		vec2 flare_extra3pos = vec2(  ((1.0 - lPos.x)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *aspectRatio*flare_extra3scale.x,  ((1.0 - lPos.y)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *flare_extra3scale.y);


		float flare_extra3 = distance(flare_extra3pos, vec2(ntc2.s*aspectRatio*flare_extra3scale.x, ntc2.t*flare_extra3scale.y));
              flare_extra3 = 0.5 - flare_extra3;
              flare_extra3 = clamp(flare_extra3*flare_extra3fill, 0.0, 1.0)  ;
              flare_extra3 = sin(flare_extra3*1.57075);
              flare_extra3 *= sunmask;
              flare_extra3 = pow(flare_extra3, 1.1);

              flare_extra3 *= flare_extra3pow;

		//subtract
		vec2 flare_extra3Bscale = vec2(5.1*flarescale, 5.1*flarescale);
		float flare_extra3Bpow = 1.5;
		float flare_extra3Bfill = 1.0;
		float flare_extra3Boffset = -0.77f;
		vec2 flare_extra3Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *aspectRatio*flare_extra3Bscale.x,  ((1.0 - lPos.y)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *flare_extra3Bscale.y);

		float flare_extra3B = distance(flare_extra3Bpos, vec2(ntc2.s*aspectRatio*flare_extra3Bscale.x, ntc2.t*flare_extra3Bscale.y));
              flare_extra3B = 0.5 - flare_extra3B;
              flare_extra3B = clamp(flare_extra3B*flare_extra3Bfill, 0.0, 1.0)  ;
              flare_extra3B = sin(flare_extra3B*1.57075);
              flare_extra3B *= sunmask;
              flare_extra3B = pow(flare_extra3B, 0.9);

              flare_extra3B *= flare_extra3Bpow;

              flare_extra3 = clamp(flare_extra3 - flare_extra3B, 0.0, 10.0);

			  color.r += flare_extra3*1.0*flaremultR;
			  color.g += flare_extra3*0.0*flaremultG;
			  color.b += flare_extra3*0.2*flaremultB;
	/*--------------------------------------------------------------------------*/

	//mid purple sweep
		vec2 flare_extra4scale = vec2(35.0*flarescale, 35.0*flarescale);
		float flare_extra4pow = 1.0;
		float flare_extra4fill = 1.1;
		float flare_extra4offset = -1.2;
		vec2 flare_extra4pos = vec2(  ((1.0 - lPos.x)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *aspectRatio*flare_extra4scale.x,  ((1.0 - lPos.y)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *flare_extra4scale.y);


		float flare_extra4 = distance(flare_extra4pos, vec2(ntc2.s*aspectRatio*flare_extra4scale.x, ntc2.t*flare_extra4scale.y));
              flare_extra4 = 0.5 - flare_extra4;
              flare_extra4 = clamp(flare_extra4*flare_extra4fill, 0.0, 1.0)  ;
              flare_extra4 = sin(flare_extra4*1.57075);
              flare_extra4 *= sunmask;
              flare_extra4 = pow(flare_extra4, 1.1);

              flare_extra4 *= flare_extra4pow;


		//subtract
		vec2 flare_extra4Bscale = vec2(5.1*flarescale, 5.1*flarescale);
		float flare_extra4Bpow = 1.5;
		float flare_extra4Bfill = 1.0;
		float flare_extra4Boffset = -0.77f;
		vec2 flare_extra4Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *aspectRatio*flare_extra4Bscale.x,  ((1.0 - lPos.y)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *flare_extra4Bscale.y);


		float flare_extra4B = distance(flare_extra4Bpos, vec2(ntc2.s*aspectRatio*flare_extra4Bscale.x, ntc2.t*flare_extra4Bscale.y));
			  flare_extra4B = 0.5 - flare_extra4B;
			  flare_extra4B = clamp(flare_extra4B*flare_extra4Bfill, 0.0, 1.0)  ;
			  flare_extra4B = sin(flare_extra4B*1.57075);
			  flare_extra4B *= sunmask;
			  flare_extra4B = pow(flare_extra4B, 0.9);

			  flare_extra4B *= flare_extra4Bpow;

			  flare_extra4 = clamp(flare_extra4 - flare_extra4B, 0.0, 10.0);

			  color.r += flare_extra4*0.7*flaremultR;
			  color.g += flare_extra4*0.1*flaremultG;
			  color.b += flare_extra4*1.0*flaremultB;
	/*----------------------------------------------------------------------------*/

	//last blue/purple sweep
		vec2 flare_extra5scale = vec2(25.0*flarescale, 25.0*flarescale);
		float flare_extra5pow = 4.0;
		float flare_extra5fill = 1.1;
		float flare_extra5offset = -0.9;
		vec2 flare_extra5pos = vec2(  ((1.0 - lPos.x)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *aspectRatio*flare_extra5scale.x,  ((1.0 - lPos.y)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *flare_extra5scale.y);

		float flare_extra5 = distance(flare_extra5pos, vec2(ntc2.s*aspectRatio*flare_extra5scale.x, ntc2.t*flare_extra5scale.y));
              flare_extra5 = 0.5 - flare_extra5;
              flare_extra5 = clamp(flare_extra5*flare_extra5fill, 0.0, 1.0)  ;
              flare_extra5 = sin(flare_extra5*1.57075);
              flare_extra5 *= sunmask;
              flare_extra5 = pow(flare_extra5, 1.1);

              flare_extra5 *= flare_extra5pow;

		//subtract
		vec2 flare_extra5Bscale = vec2(5.1*flarescale, 5.1*flarescale);
		float flare_extra5Bpow = 1.0;
		float flare_extra5Bfill = 1.0;
		float flare_extra5Boffset = -0.77f;
		vec2 flare_extra5Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *aspectRatio*flare_extra5Bscale.x,  ((1.0 - lPos.y)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *flare_extra5Bscale.y);

		float flare_extra5B = distance(flare_extra5Bpos, vec2(ntc2.s*aspectRatio*flare_extra5Bscale.x, ntc2.t*flare_extra5Bscale.y));
			  flare_extra5B = 0.5 - flare_extra5B;
			  flare_extra5B = clamp(flare_extra5B*flare_extra5Bfill, 0.0, 1.0)  ;
			  flare_extra5B = sin(flare_extra5B*1.57075);
			  flare_extra5B *= sunmask;
			  flare_extra5B = pow(flare_extra5B, 0.9);

			  flare_extra5B *= flare_extra5Bpow;

			  flare_extra5 = clamp(flare_extra5 - flare_extra5B, 0.0, 10.0);

			  color.r += flare_extra5*0.2*flaremultR;
			  color.g += flare_extra5*0.1*flaremultG;
			  color.b += flare_extra5*0.6*flaremultB;
	/*----------------------------------------------------------------------*/

	//mid orange sweep
		vec2 flare10scale = vec2(6.0*flarescale, 6.0*flarescale);
		float flare10pow = 1.9;
		float flare10fill = 1.1;
		float flare10offset = -0.7;
		vec2 flare10pos = vec2(  ((1.0 - lPos.x)*(flare10offset + 1.0) - (flare10offset*0.5))  *aspectRatio*flare10scale.x,  ((1.0 - lPos.y)*(flare10offset + 1.0) - (flare10offset*0.5))  *flare10scale.y);


		float flare10 = distance(flare10pos, vec2(ntc2.s*aspectRatio*flare10scale.x, ntc2.t*flare10scale.y));
              flare10 = 0.5 - flare10;
              flare10 = clamp(flare10*flare10fill, 0.0, 1.0)  ;
              flare10 = sin(flare10*1.57075);
              flare10 *= sunmask;
              flare10 = pow(flare10, 1.1);

              flare10 *= flare10pow;

		//subtract
		vec2 flare10Bscale = vec2(5.1*flarescale, 5.1*flarescale);
		float flare10Bpow = 1.5;
		float flare10Bfill = 1.0;
		float flare10Boffset = -0.77f;
		vec2 flare10Bpos = vec2(  ((1.0 - lPos.x)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *aspectRatio*flare10Bscale.x,  ((1.0 - lPos.y)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *flare10Bscale.y);

		float flare10B = distance(flare10Bpos, vec2(ntc2.s*aspectRatio*flare10Bscale.x, ntc2.t*flare10Bscale.y));
              flare10B = 0.5 - flare10B;
              flare10B = clamp(flare10B*flare10Bfill, 0.0, 1.0)  ;
              flare10B = sin(flare10B*1.57075);
              flare10B *= sunmask;
              flare10B = pow(flare10B, 0.9);

              flare10B *= flare10Bpow;

              flare10 = clamp(flare10 - flare10B, 0.0, 10.0);

			  color.r += flare10*0.5*flaremultR;
			  color.g += flare10*0.3*flaremultG;
			  color.b += flare10*0.0*flaremultB;
	/*-----------------------------------------------------------------------------*/

	//mid blue sweep
		vec2 flare10Cscale = vec2(6.0*flarescale, 6.0*flarescale);
		float flare10Cpow = 1.9;
		float flare10Cfill = 1.1;
		float flare10Coffset = -0.6;
		vec2 flare10Cpos = vec2(  ((1.0 - lPos.x)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *aspectRatio*flare10Cscale.x,  ((1.0 - lPos.y)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *flare10Cscale.y);

		float flare10C = distance(flare10Cpos, vec2(ntc2.s*aspectRatio*flare10Cscale.x, ntc2.t*flare10Cscale.y));
              flare10C = 0.5 - flare10C;
              flare10C = clamp(flare10C*flare10Cfill, 0.0, 1.0)  ;
              flare10C = sin(flare10C*1.57075);
              flare10C *= sunmask;
              flare10C = pow(flare10C, 1.1);

              flare10C *= flare10Cpow;

		//subtract
		vec2 flare10Dscale = vec2(5.1*flarescale, 5.1*flarescale);
		float flare10Dpow = 1.5;
		float flare10Dfill = 1.0;
		float flare10Doffset = -0.67f;
		vec2 flare10Dpos = vec2(  ((1.0 - lPos.x)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *aspectRatio*flare10Dscale.x,  ((1.0 - lPos.y)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *flare10Dscale.y);

			float flare10D = distance(flare10Dpos, vec2(ntc2.s*aspectRatio*flare10Dscale.x, ntc2.t*flare10Dscale.y));
			  flare10D = 0.5 - flare10D;
			  flare10D = clamp(flare10D*flare10Dfill, 0.0, 1.0)  ;
			  flare10D = sin(flare10D*1.57075);
			  flare10D *= sunmask;
			  flare10D = pow(flare10D, 0.9);

			  flare10D *= flare10Dpow;

			  flare10C = clamp(flare10C - flare10D, 0.0, 10.0);

			  color.r += flare10C*0.5*flaremultR;
			  color.g += flare10C*0.3*flaremultG;
			  color.b += flare10C*1.0*flaremultB;
	/*--------------------------------------------------------------------------------------*/
        
	//RedGlow1
        vec2 flare11scale = vec2(1.5*flarescale, 1.5*flarescale);
        float flare11pow = 1.1;
        float flare11fill = 2.0;
        float flare11offset = -0.523f;
        vec2 flare11pos = vec2(  ((1.0 - lPos.x)*(flare11offset + 1.0) - (flare11offset*0.5))  *aspectRatio*flare11scale.x,  ((1.0 - lPos.y)*(flare11offset + 1.0) - (flare11offset*0.5))  *flare11scale.y);

        float flare11 = distance(flare11pos, vec2(ntc2.s*aspectRatio*flare11scale.x, ntc2.t*flare11scale.y));
              flare11 = 0.5 - flare11;
              flare11 = clamp(flare11*flare11fill, 0.0, 1.0)  ;
              flare11 = pow(flare11, 2.9);
              flare11 *= sunmask;

              flare11 *= flare11pow;

              color.r += flare11*1.0*flaremultR;
              color.g += flare11*0.2*flaremultG;
              color.b += flare11*0.0*flaremultB;
	/*------------------------------------------------------------------*/
		
	//PurpleGlow2
        vec2 flare12scale = vec2(2.5*flarescale, 2.5*flarescale);
        float flare12pow = 0.5;
        float flare12fill = 2.0;
        float flare12offset = -0.323f;
        vec2 flare12pos = vec2(  ((1.0 - lPos.x)*(flare12offset + 1.0) - (flare12offset*0.5))  *aspectRatio*flare12scale.x,  ((1.0 - lPos.y)*(flare12offset + 1.0) - (flare12offset*0.5))  *flare12scale.y);

        float flare12 = distance(flare12pos, vec2(ntc2.s*aspectRatio*flare12scale.x, ntc2.t*flare12scale.y));
              flare12 = 0.5 - flare12;
              flare12 = clamp(flare12*flare12fill, 0.0, 1.0)  ;
              flare12 = pow(flare12, 2.9);
              flare12 *= sunmask;

              flare12 *= flare12pow;

              color.r += flare12*0.7*flaremultR;
              color.g += flare12*0.0*flaremultG;
              color.b += flare12*1.0*flaremultB;
	/*------------------------------------------------------------------*/

	//BlueGlow3
        vec2 flare13scale = vec2(1.0*flarescale, 1.0*flarescale);
        float flare13pow = 1.5;
        float flare13fill = 2.0;
        float flare13offset = +0.138f;
		vec2 flare13pos = vec2(  ((1.0 - lPos.x)*(flare13offset + 1.0) - (flare13offset*0.5))  *aspectRatio*flare13scale.x,  ((1.0 - lPos.y)*(flare13offset + 1.0) - (flare13offset*0.5))  *flare13scale.y);

        float flare13 = distance(flare13pos, vec2(ntc2.s*aspectRatio*flare13scale.x, ntc2.t*flare13scale.y));
              flare13 = 0.5 - flare13;
              flare13 = clamp(flare13*flare13fill, 0.0, 1.0)  ;
              flare13 = pow(flare13, 2.9);
              flare13 *= sunmask;

              flare13 *= flare13pow;

              color.r += flare13*0.0*flaremultR;
              color.g += flare13*0.2*flaremultG;
              color.b += flare13*1.0*flaremultB;
	/*-------------------------------------------------------------*/
   }
}
#endif

#if defined Volumetric_Lighting || defined raytracedShadows
float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));		// (-depth * (far - near)) = (2.0 * near)/ld - far - near
}
#endif

float raysNoise(vec2 pos) {
	return fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f);
}

#ifdef Volumetric_Lighting
float raysCdist(vec2 coord) {
	return clamp(1.0 - max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0, 0.0, 1.0);
}

vec3 screenSpace(vec2 coord, float depth){
	vec4 pos = gbufferProjectionInverse * (vec4(coord, depth, 1.0) * 2.0 - 1.0);
	return pos.xyz/pos.w;
}

vec2 Vstep = vec2(0.0,1.0)/vec2(viewWidth,viewHeight).xy;

float Vthreshs(float v1){
	float cdepth = ld(texture2D(depthtex0, texcoord.xy).x);
	return exp(-abs(texture2D(composite, texcoord + v1*Vstep).y-cdepth)*8.0);
}

float Volumetric_Light(vec2 tex){
	float weights[9] = float[9](
		0.013519569015984728,
		0.047662179108871855,
		0.11723004402070096,
		0.20116755999375591,
		0.240841295721373,
		0.20116755999375591,
		0.11723004402070096,
		0.047662179108871855,
		0.013519569015984728
	);

	float indices[9] = float[9](-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0);
	
	float threshs[9] = float[9](
		Vthreshs(indices[0]),
		Vthreshs(indices[1]),
		Vthreshs(indices[2]),
		Vthreshs(indices[3]),
		1.0,
		Vthreshs(indices[5]),
		Vthreshs(indices[6]),
		Vthreshs(indices[7]),
		Vthreshs(indices[8])
	);
	
	float weight = 0.0;
	float Vgr = 0.0;;

	for(int i=0; i<9; ++i ){
		weight += weights[i]*threshs[i];
		Vgr += texture2D(composite, tex + indices[i]*Vstep).z * (weights[i]*threshs[i]);		
	}
	Vgr /= weight;
	
	return Vgr;
}

float getVolumetricRays() {	
		float dither = fract(0.75487765 * gl_FragCoord.x + 0.56984026 * gl_FragCoord.y);	
		#ifdef TAA  
			  dither = fract(frameTimeCounter * 128.0 + dither);	//filter using taa
		#endif
		int maxSamples = 6;
	
		const float VL_dISTANCE = 200.0;

		//setup ray in projected shadow map space
		vec4 fragposition = vec4(texcoord.xy,texture2D(depthtex0,texcoord.xy).x,1.0)*2.-1.;
		fragposition = gbufferProjectionInverse*fragposition;
		fragposition /= fragposition.w;
	
		float z = -fragposition.z;
		
		//project pixel position into projected shadowmap space
		fragposition = gbufferModelViewInverse*fragposition;
		fragposition = shadowModelView*fragposition;
		fragposition = shadowProjection*fragposition;
		
		//project view origin into projected shadowmap space
		vec4 start = gbufferModelViewInverse*vec4(0.0,0.0,0.0,1.0);
		start = (shadowModelView*start);
		start = (shadowProjection*start);
		
		//rayvector into projected shadow map space
		//we can use a projected vector because its orthographic projection
		//however we still have to send it to curved shadow map space every step
		vec3 dV = (fragposition.xyz-start.xyz)/maxSamples;
		
		//apply dither
		vec3 progress = start.xyz + dV*dither;

		float vL = 0.0;
		
		for (int i=0;i<maxSamples;i++) {
			//project into biased shadowmap space
			vec2 pos = progress.xy;
			pos = progress.xy*calcDistortion(pos.xy);

			//sample and apply fog to sample
			vL += shadow2D(shadow, vec3(pos.xy*0.5+0.5, progress.z*0.5/6.0+0.5)).z;

			//advance the ray
			progress += dV;
	}
		vL *= z/VL_dISTANCE/maxSamples;
	return vL;
}
#endif

#ifdef Celshading
float edepth(vec2 coord) {
	return texture2D(depthtex1,coord).x;
}

vec3 celshade(vec3 clrr) {
	//edge detect
	float dtresh = 1.0/(far-near) / (5000.0*Celradius);
	vec4 dc = vec4(edepth(texcoord.xy));
	vec3 border = vec3(1.0/viewWidth, 1.0/viewHeight, 0.0)*Celborder;
	vec4 sa = vec4(edepth(texcoord.xy + vec2(-border.x,-border.y)),
		 		   edepth(texcoord.xy + vec2(border.x,-border.y)),
		 		   edepth(texcoord.xy + vec2(-border.x,border.z)),
		 		   edepth(texcoord.xy + vec2(border.z,border.y)));

	//opposite side samples
	vec4 sb = vec4(edepth(texcoord.xy + vec2(border.x,border.y)),
		 		   edepth(texcoord.xy + vec2(-border.x,border.y)),
		 		   edepth(texcoord.xy + vec2(border.x,border.z)),
		 		   edepth(texcoord.xy + vec2(border.z,-border.y)));

	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
		 dd = step(dd.xyzw, vec4(0.0));

	float e = clamp(dot(dd,vec4(0.25f)),0.0,1.0);
	return clrr*e;
}
#endif

#if defined TAA || defined raytracedShadows
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

vec3 toScreenSpace(vec3 pos) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
	vec3 p3 = pos * 2.0 - 1.0;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragposition.xyz / fragposition.w;
}

#ifdef SSDO
//modified version of Yuriy O'Donnell's SSDO (License MIT -> https://github.com/kayru/dssdo)
float calcSSDO(vec3 fragpos, vec3 normal){
	float finalAO = 0.0;

	float radius = 0.05 / (fragpos.z);
	const float attenuation_angle_threshold = 0.1;
	const int num_samples = 16;	
	const float ao_weight = 1.0;
	#ifdef TAA
	float noise = fract(0.75487765 * gl_FragCoord.x + 0.56984026 * gl_FragCoord.y);
		  noise = fract(frameTimeCounter * 2.0 + noise);
	#else
	float noise = 1.0;
	#endif	

	for( int i=0; i<num_samples; ++i ){
	    vec2 texOffset = pow(length(check_offsets[i].xy),0.5)*radius*vec2(1.0,aspectRatio)*normalize(check_offsets[i].xy);
		vec2 newTC = texcoord+texOffset*noise;
	#ifdef TAA
		vec3 t0 = toScreenSpace(vec3(newTC-offsets[framemod8]*texelSize*0.5, texture2D(depthtex1, newTC).x));
	#else
		vec3 t0 = toScreenSpace(vec3(newTC, texture2D(depthtex1, newTC).x));
	#endif	
		vec3 center_to_sample = t0.xyz - fragpos.xyz;

		float dist = length(center_to_sample);

		vec3 center_to_sample_normalized = center_to_sample / dist;
		float attenuation = 1.0-clamp(dist/6.0,0.0,1.0);
		float dp = dot(normal, center_to_sample_normalized);

		attenuation = sqrt(max(dp,0.0))*attenuation*attenuation * step(attenuation_angle_threshold, dp);
		finalAO += attenuation * (ao_weight / num_samples);
	}
	return finalAO;
}
#endif

#ifdef raytracedShadows
//Based of Chocapic13s implementation
//https://www.minecraftforum.net/forums/mapping-and-modding-java-edition/minecraft-mods/1293898-1-14-chocapic13s-shaders
vec3 toClipSpace(vec3 viewSpacePosition) {
    return (diagonal3(gbufferProjection) * viewSpacePosition + gbufferProjection[3].xyz) / -viewSpacePosition.z * 0.5 + 0.5;
}

float calcRaytraceShadows(vec3 angle, vec3 pos, float dither, float translucent){
	//prevents the ray from going behind the camera
	float rayLength = (pos.z + angle.z * far*1.732 > -near) ? (-near - pos.z) / angle.z : far*1.732;
    vec3 direction = toClipSpace(pos+angle*rayLength)-toClipSpace(pos);  //convert to clip space
    	 direction.xyz = direction.xyz/max(abs(direction.x)/texelSize.x,abs(direction.y)/texelSize.y);	//fixed step size

	vec3 stepv = direction * 4.5;
#ifdef TAA	
	vec3 spos = toClipSpace(pos)+vec3(offsets[framemod8]*texelSize*0.5,0.0)+stepv*dither;
#else
	vec3 spos = toClipSpace(pos)+stepv*dither;
#endif
	for (int i = 0; i < 16; i++) {
		spos += stepv;
		float depth1 = texture2D(depthtex1,spos.xy).x; //might change to depthtex0 to support transparency
    	if(depth1 < spos.z) {
			float dist = abs(ld(depth1)-ld(spos.z))/ld(spos.z);
			if (dist < 0.01) return translucent*exp2(pos.z/8.0);
		}
	}
    return 1.0;
}
#endif

uniform float sunElevation;
vec3 YCoCg2RGB(vec3 c){
	c.y-=0.5;
	c.z-=0.5;
	return vec3(c.r+c.g-c.b, c.r + c.b, c.r - c.g - c.b);
}

void main() {

//sample half-resolution buffer with correct texture coordinates
vec4 hr = pow(texture2D(composite,(floor(gl_FragCoord.xy/2.)*2+1.0)/vec2(viewWidth,viewHeight)/2.0),vec4(2.2,2.2,2.2,1.0))*vec4(257.,257,257,1.0);

//Setup depth
float depth0 = texture2D(depthtex0, texcoord).x;	//everything
float depth1 = texture2D(depthtex1, texcoord).x;	//transparency

bool sky = (depth0 >= 1.0);

vec4 albedo = texture2D(colortex0,texcoord);
vec3 normal = decode(texture2D(colortex1, texcoord).xy);
vec2 lightmap = texture2D(colortex1, texcoord.xy).zw;
bool translucent = albedo.b > 0.69 && albedo.b < 0.71;
bool emissive = albedo.b > 0.59 && albedo.b < 0.61;
vec3 color = vec3(albedo.rg,0.0);

vec2 a0 = texture2D(colortex0,texcoord + vec2(1.0/viewWidth,0.0)).rg;
vec2 a1 = texture2D(colortex0,texcoord - vec2(1.0/viewWidth,0.0)).rg;
vec2 a2 = texture2D(colortex0,texcoord + vec2(0.0,1.0/viewHeight)).rg;
vec2 a3 = texture2D(colortex0,texcoord - vec2(0.0,1.0/viewHeight)).rg;
vec4 lumas = vec4(a0.x,a1.x,a2.x,a3.x);
vec4 chromas = vec4(a0.y,a1.y,a2.y,a3.y);

vec4 w = 1.0-step(0.1176, abs(lumas - color.x));
float W = dot(w,vec4(1.0));
w.x = (W==0.0)? 1.0:w.x;  W = (W==0.0)? 1.0:W;

bool pattern = (mod(gl_FragCoord.x,2.0)==mod(gl_FragCoord.y,2.0));
color.b= dot(w,chromas)/W;
color.rgb = (pattern)?color.rbg:color.rgb;
color.rgb = YCoCg2RGB(color.rgb);
color = pow(color,vec3(2.2));

if (!sky){
//Water and Ice
vec3 Wnormal = texture2D(colortex2,texcoord).xyz;
bool iswater = Wnormal.z < 0.2499 && dot(Wnormal,Wnormal) > 0.0;
bool isice = Wnormal.z > 0.2499 && Wnormal.z < 0.4999 && dot(Wnormal,Wnormal) > 0.0;
bool isnsun = (iswater||isice) || ((!iswater||!isice) && isEyeInWater == 1);
/*--------------------------------------------------------------------------------------*/

#ifdef TAA
vec2 newTC = gl_FragCoord.xy*texelSize;
vec3 TAAfragpos = toScreenSpace(vec3(newTC-offsets[framemod8]*texelSize*0.5, texture2D(depthtex1, newTC).x));
#else
vec3 TAAfragpos = toScreenSpace(vec3(texcoord,depth1));	//was depth0 before, might cause issues
#endif

#ifdef Whiteworld
	color += vec3(1.5);
#endif

#ifdef Celshading
	color = celshade(color);
#endif

float ao = 1.0;
#ifdef SSDO
	float occlusion = calcSSDO(TAAfragpos, normal);
	if(!iswater)ao = pow(1.0-occlusion, ao_strength);
#endif
	
	//Emissive blocks lighting and colors
	#ifdef HandLight
	bool underwaterlava = (isEyeInWater == 1.0 || isEyeInWater == 2.0);
	if(!underwaterlava) lightmap.x = max(lightmap.x, max(max(float(heldBlockLightValue), float(heldBlockLightValue2)) - 1.0 - length(TAAfragpos), 0.0) / 15.0);
	#endif
	float torch_lightmap = 16.0-min(15.0,(lightmap.x-0.5/16.0)*16.0*16.0/15.0);
	float fallof1 = clamp(1.0 - pow(torch_lightmap/16.0,4.0),0.0,1.0);
	torch_lightmap = fallof1*fallof1/(torch_lightmap*torch_lightmap+1.0);
	float c_emitted = dot((color.rgb),vec3(1.0,0.6,0.4))/2.0;
	float emitted 		= emissive? clamp(c_emitted*c_emitted,0.0,1.0)*torch_lightmap : 0.0;
	vec3 emissiveLightC = vec3(emissive_R,emissive_G,emissive_B);
	/*------------------------------------------------------------------------------------------*/
	
	//Lighting and colors
	float NdotL = dot(normal,sunVec);
	float NdotU = dot(normal,upVec);
	
	const vec3 moonlight = vec3(0.5, 0.9, 1.8) * Moonlight;

	vec2 visibility = vec2(sunVisibility,moonVisibility);

	float skyL = max(lightmap.y-2./16.0,0.0)*1.14285714286;	
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);

	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.14*skyL*skyL,0.33,0.7,0.1) + vec4(0.6,0.66,0.7,0.25);
		 bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);

	vec3 sun_ambient = bounced.w * (vec3(0.1, 0.5, 1.1)*2.4+rainStrength*2.3*vec3(0.05,-0.33,-0.9))+ 1.6*sunlight*(sqrt(bounced.w)*bounced.x*2.4 + bounced.z)*(1.0-rainStrength*0.99);
	vec3 moon_ambient = (moonlight*0.7 + moonlight*bounced.y)*4.0;

	//vec3 LightC = mix(sunlight,moonlight,moonVisibility)*tr*(1.0-rainStrength*0.99);
	vec3 LightC = mix(sunlight,moonlight,moonVisibility)*(1.0-rainStrength*0.99); //remove time check to smooth out day night transition
	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03*0.65+tr*0.17*0.65);
	float finalminlight = (nightVision > 0.01)? 0.15 : minlight; //add nightvision support but make sure minlight is still adjustable.	
	vec3 ambientC = ao*amb1 + emissiveLightC*(emitted*15.*color + torch_lightmap*ao)*0.66 + ao*finalminlight*min(skyL+6/16.,9/16.)*normalize(amb1+0.0001);
	/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

	//vec3 shadowLightpos = float(sunElevation > 1e-5)*2.0-1.0*normalize(mat3(gbufferModelViewInverse) *shadowLightPosition); //improves lighting but currently causes shadow acne
	//vec3 shadowLightpos = normalize(mat3(gbufferModelViewInverse) *shadowLightPosition);	
	float diffuse = translucent? 0.75 : clamp(dot(normal, normalize(shadowLightPosition)),0.0,1.0);	
	vec3 finalShading = vec3(diffuse);

#ifdef Shadows
	#ifdef TAA 
	float noise = fract(0.75487765 * gl_FragCoord.x + 0.56984026 * gl_FragCoord.y);
		  noise = fract(frameTimeCounter * 16.0 + noise);
	#else
	float noise = fract(dot(gl_FragCoord.xy, vec2(0.5, 0.25))); //Use different dithering if TAA is disabled, because it looks better at low sample rate.
	#endif
if (diffuse > 0.001) {
	vec3 shadowpos = mat3(gbufferModelViewInverse) * TAAfragpos.xyz + gbufferModelViewInverse[3].xyz;
		 shadowpos = mat3(shadowModelView) * shadowpos + shadowModelView[3].xyz;
		 shadowpos = diagonal3(shadowProjection) * shadowpos + shadowProjection[3].xyz;
	float distortion = calcDistortion(shadowpos.xy);
		 shadowpos.xy *= distortion;
	vec2 shading = vec2(1.0); //set to 1.0 for raytraced shadows outside of shadowmap
	//only if on shadowmap
	if (abs(shadowpos.x) < 1.0-1.5/shadowMapResolution && abs(shadowpos.y) < 1.0-1.5/shadowMapResolution && abs(shadowpos.z) < 6.0){
		float pdepth = 1.412;	//fallback if penumbra shadows are disabled
		const float threshMul = max(2048.0/shadowMapResolution*shadowDistance/128.0,0.95);
		float distortThresh = (sqrt(1.0-diffuse*diffuse)/diffuse+0.7)/distortion;
		shadowpos = shadowpos * vec3(0.5,0.5,0.5/6.0) + vec3(0.5,0.5,0.5);

	#if defined Penumbra && defined MC_GL_VENDOR_NVIDIA && defined MC_OS_WINDOWS
		vec3 shadowFilterDepth = vec3(1.412, 30.0, 20.0);	//x=min radius, y=max radius, z=max depth
		float pbias = translucent? 0.00014/15.0 : distortThresh/7500.0*threshMul;
		float diffthreshM = pbias*shadowFilterDepth.y*distortion*Nearshadowplane*k;
		vec2 counter = vec2(0.0);
		for(int i = 0; i < VPS_samples; i++){
			vec2 offsetS = tapLocation(i,VPS_samples,noise);

			float depth = texelFetch2D(shadowtex0, ivec2((shadowpos.xy+offsetS*distortion*(1.0+shadowFilterDepth.y)*Nearshadowplane*k/shadowMapResolution)*shadowMapResolution), 0).x;
			float block  = ffstep(depth,shadowpos.z-i*diffthreshM/VPS_samples-diffthreshM);

			counter.x += block;
			counter.y += depth * block;
		}
		counter.y = (counter.x >= 0.9)? counter.y / counter.x : shadowpos.z;
		pdepth = clamp(max(shadowpos.z - counter.y, 0.0)*1500.0, 0.0, shadowFilterDepth.z)/shadowFilterDepth.z*(shadowFilterDepth.y-shadowFilterDepth.x)+shadowFilterDepth.x;
	#endif

		//Setup shadows
		float rdMul = pdepth*distortion*Nearshadowplane*k/shadowMapResolution;
		float bias = translucent? 0.00014 : distortThresh/6000.0*threshMul;
		shading = vec2(0.0); //set to 0.0 for shadowmap shadows
		for(int i = 0; i < shadow_samples; i++){
			vec2 offsetS = tapLocation(i,shadow_samples,noise);

			float weight = 1.0+(i+noise)*rdMul/shadow_samples*shadowMapResolution;
			shading.x += shadow2D(shadow,vec3(shadowpos + vec3(rdMul*offsetS,-bias*weight))).x/shadow_samples;
		#ifdef ColoredShadows
			shading.y += shadow2D(shadowtex1,vec3(shadowpos + vec3(rdMul*offsetS,-bias*weight))).x/shadow_samples;
		#endif
		}
	}
	
	#ifdef raytracedShadows
		if(shading.x > 0.005)shading.xy *= calcRaytraceShadows(shadowLightPosition,TAAfragpos.xyz,noise,float(translucent));
	#endif

	#ifdef ColoredShadows
		finalShading = texture2D(shadowcolor0, shadowpos.xy).rgb*(shading.y-shading.x) + shading.x;
		finalShading *= diffuse;
	#else
		finalShading = vec3(shading.x)*diffuse;
	#endif

	//Prevent light leakage
	finalShading *= mix(skyL,1.0,clamp((eyeBrightnessSmooth.y/255.0-2.0/16.)*4.0,0.0,1.0));
}
#else
	finalShading *= mix(skyL,1.0,clamp((eyeBrightnessSmooth.y/255.0-4.0/16.)*4.0,0.0,1.0)); //fix lighting in caves with shadows disabled.
	finalShading *= 0.5;
#endif

	vec3 waterC = vec3(waterCR,waterCG,waterCB);
	if(iswater || isEyeInWater == 1.0) LightC = mix(waterC,waterC*0.0125,moonVisibility)*(1.0-rainStrength*0.99); //water shading, wip
	color *= (finalShading*LightC*(isnsun?SkyL2*skyL:1.0)*2.15+ambientC*(isnsun?1.0/(SkyL2*skyL*0.5+0.5):1.0)*1.4)*0.63;
}

//Sky
vec2 ntc = texcoord*2.0;
vec2 ntc2 = texcoord*2.0-1.0;
vec3 c = vec3(0.0);

if (ntc.x < 1.0 && ntc.y < 1.0 && ntc.x > 0.0 && ntc.y > 0.0) {
	float depth1 = texture2D(depthtex1, ntc).x;
	float sky = 0.950-near/far/far;
		if (depth1 > sky) {
			vec4 fragpos = gbufferProjectionInverse * (vec4(ntc, depth1, 1.0) * 2.0 - 1.0);
			fragpos /= fragpos.w;
			//Draw sky
			c = getSkyColor(fragpos.xyz);
		}
}

#ifdef Volumetric_Lighting
	float gr = Volumetric_Light(texcoord.xy);
		  gr = getVolumetricRays();

	//single pass godrays for volumetric lighting
	vec2 deltatexcoord = vec2(lightPos - texcoord) * 0.04;
	vec2 raysCoord = texcoord + deltatexcoord*raysNoise(texcoord); //slow filtered

	float rays = 1.0;
	for (int i = 0; i < 20; i++) {
		float depth0 = texture2D(depthtex0, raysCoord).x;
		raysCoord += deltatexcoord;
		rays += dot(step(comp, depth0), 1.0)*raysCdist(raysCoord);
	}
	rays /= 20.0;

	vec3 raysPos = screenSpace(texcoord.xy, texture2D(depthtex0, texcoord.xy).x);
	float lightpos = clamp(dot(normalize(raysPos), normalize(shadowLightPosition)), 0.0, 1.0)*rays*5.0;
	gr *= 1.0+lightpos*(1.0-isEyeInWater);
#else
	float gr = 0.0;
#endif

//Godrays and lens flares
if (ntc2.x < 1.0 && ntc2.y < 1.0 && ntc2.x > 0.0 && ntc2.y > 0.0){
#ifndef Volumetric_Lighting
#ifdef Godrays
	vec2 deltatexcoord = vec2(lightPos - ntc2) * 0.04;
	vec2 noisetc = ntc2 + deltatexcoord*raysNoise(ntc2) + deltatexcoord; //maybe doesnt need to be filtered
	bool underwater = (isEyeInWater == 1.0);

	for (int i = 0; i < grays_sample; i++) {
		float depth = underwater? texture2D(depthtex1, noisetc).x : texture2D(depthtex0, noisetc).x; //swap depth for now, wip
		noisetc += deltatexcoord;
		gr += dot(step(comp, depth), 1.0)*cdist(noisetc);
	}
	gr /= grays_sample;
#endif
#endif

#ifdef Lens_Flares
LensFlare(c);
#endif
}

#ifdef Lens_Flares
if (texcoord.x < 2.0/viewWidth && texcoord.y < 2.0/viewHeight) {
gr = 0.0;
	for (int i = -6; i < 7;i++) {
		for (int j = -6; j < 7 ;j++) {
		vec2 ij = vec2(i,j);
		float depth = texture2D(depthtex0, ntc+lightPos + sign(ij)*sqrt(abs(ij))*vec2(0.006)).x;
		gr += dot(step(comp, depth), 1.0);
		}
	}
	gr /= 169.0;
}
#endif

//Draw sky (color)
#ifdef defskybox
	if (sky)color = pow(texture2D(composite, texcoord.xy).rgb,vec3(2.2)); //overwrite color with data from skytextured
#else
	if (sky)color = hr.rgb;
#endif

gl_FragData[0] = vec4(c/30.0, 1.0);
gl_FragData[1] = vec4(pow(color/257.0,vec3(0.454)), gr);
}
