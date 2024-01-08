#version 120

#define composite2
#define gbuffers_water
#define lightingColors
#include "/shaders.settings"

varying vec4 color;
varying vec4 ambientNdotL;
varying vec2 texcoord;
varying vec2 lmcoord;

varying vec3 viewVector;
varying vec3 worldpos;
varying mat3 tbnMatrix;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;                      //xyz = tangent vector, w = handedness, added in 1.7.10

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float rainStrength;
uniform float nightVision;
uniform float screenBrightness;

#ifdef Waving_Water
uniform float frameTimeCounter;
const float PI = 3.1415927;
#endif

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.16,0.005),
								vec3(0.58597,0.31,0.05),
								vec3(0.58597,0.45,0.16),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));

float SunIntensity(float zenithAngleCos, float sunIntensity, float cutoffAngle, float steepness){
	return sunIntensity * max(0.0, 1.0 - exp(-((cutoffAngle - acos(zenithAngleCos))/steepness)));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

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

	//pos
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal).xyz;
	vec3 position = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz + gbufferModelViewInverse[3].xyz;
	worldpos = position.xyz + cameraPosition;

	color = gl_Color;
	
	texcoord = (gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	//Transparency stuff
	ambientNdotL.a = 0.0;
	float iswater = 1.0; //disable lightmap on water, make light go through instead
	if(mc_Entity.x == 10008.0) {
		ambientNdotL.a = 1.0;
		iswater = 0.0;
	#ifdef Waving_Water
		float fy = fract(worldpos.y + 0.001);
		float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.8 + worldpos.x /  2.5 + worldpos.z / 5.0))
				   + 0.05 * sin(2 * PI * (frameTimeCounter*0.6 + worldpos.x / 6.0 + worldpos.z /  12.0));
		position.y += clamp(wave, -fy, 1.0-fy)*waves_amplitude;
	#endif
	}
	if(mc_Entity.x == 10079.0) ambientNdotL.a = 0.5;
	//---
	
	gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(position, 1.0);
#ifdef TAA
	gl_Position.xy += offsets[framemod8] * gl_Position.w*texelSize;
#endif
	//ToD
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
#ifdef MC_GL_VENDOR_ATI
	vec3 sunlight = vec3(1.0); //Time of day calculation breaks water on amd drivers 18.8.1, last working driver was 18.6.1, causes heavy flickering. TESTED ON RX460
#else
	vec3 sunlight = mix(ToD[int(cmpH)], ToD[int(cmpH1)], fract(hour));
#endif
	sunlight.rgb += vec3(r_multiplier,g_multiplier,b_multiplier); //allows lighting colors to be tweaked.
	sunlight.rgb *= light_brightness; //brightness needs to be adjusted if we tweak lighting colors.
	//---

	//lightmap
	float torch_lightmap = 16.0-min(15.0,(lmcoord.s-0.5/16.0)*16.0*16.0/15.0);
	float fallof1 = clamp(1.0 - pow(torch_lightmap/16.0,4.0),0.0,1.0);
	torch_lightmap = fallof1*fallof1/(torch_lightmap*torch_lightmap+1.0);
	torch_lightmap *= iswater;
	vec3 emissiveLightC = vec3(emissive_R,emissive_G,emissive_B)*torch_lightmap*0.2;
	//---

	//light bounce
	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = vec3(0.0, 1.0, 0.0); //fix for loading shaderpacks in nether and end, optifine bug.

	vec2 visibility = vec2(dot(sunVec,upVec),dot(-sunVec,upVec));
	
	float cutoffAngle = 1.608;
	float steepness = 1.5;
	float cosSunUpAngle = dot(sunVec, upVec) * 0.95 + 0.05; //Has a lower offset making it scatter when sun is below the horizon.
	float sunE = SunIntensity(cosSunUpAngle, 1000.0, cutoffAngle, steepness);  // Get sun intensity based on how high in the sky it is

	float NdotL = dot(normal,sunVec);
	float NdotU = dot(normal,upVec);

	vec2 trCalc = min(abs(worldTime-vec2(23000.0,12700.0)),750.0); //adjust to make day-night switch smoother
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	visibility = pow(clamp(visibility+0.15,0.0,0.3)/0.3,vec2(4.4));
	sunlight = sunlight/luma(sunlight)*sunE*0.0075*0.075*3.*visibility.x;
	
	float skyL = max(lmcoord.t-2./16.0,0.0)*1.14285714286;	
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);

	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.14*skyL*skyL,0.33,0.7,0.1) + vec4(0.6,0.66,0.7,0.25);
		 bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);
	
	vec3 ambientC = mix(vec3(0.3, 0.5, 1.1),vec3(0.08,0.1,0.1),rainStrength)*length(sunlight)*bounced.w;
		 ambientC += 0.25*sunlight*(bounced.x + bounced.z)*(0.03+tr*0.17)/0.4*(1.0-rainStrength*0.98)  + length(sunlight)*0.2*(1.0-rainStrength*0.9);
		 ambientC += sunlight*(NdotL*0.5+0.45)*visibility.x*(1.0-tr)*(1.0-tr)*4.*(1.0-rainStrength*0.98);

	//lighting during night time
	const vec3 moonlight = vec3(0.0024, 0.00432, 0.0078);	
	vec3 moon_ambient = (moonlight*2.0 + moonlight*bounced.y)*(4.0-rainStrength*0.95)*0.2;
	vec3 moonC = (moon_ambient*visibility.y)*SkyL2*(0.03*0.65+tr*0.17*0.65);

	float finalminlight = (nightVision > 0.01)? 0.075: ((minlight+0.006)+(screenBrightness*0.0125))*0.25;
	ambientNdotL.rgb = ambientC*SkyL2*0.3 + moonC + emissiveLightC + finalminlight;
		
	//sunlight = mix(sunlight,moonlight*(1.0-rainStrength*0.9),visibility.y)*tr;
	sunlight = mix(sunlight,moonlight*(1.0-rainStrength*0.9),visibility.y);	//remove time check to improve day-night transition
	//---


	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
					 tangent.y, binormal.y, normal.y,
					 tangent.z, binormal.z, normal.z);

	float dist = length(gl_ModelViewMatrix * gl_Vertex);
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector.xy = viewVector.xy / dist * 8.25;
}