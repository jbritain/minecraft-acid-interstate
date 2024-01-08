#version 120
/* DRAWBUFFERS:34 */

#define gbuffers_shadows
#define composite0
#define composite2
#define lightingColors
#include "/shaders.settings"

#ifdef HandLight
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

varying vec2 texcoord;
varying vec3 sunVec;
varying vec3 upVec;
varying vec3 sunlight;
varying float tr;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D composite;

uniform mat4 gbufferProjectionInverse;

uniform int isEyeInWater;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float nightVision;
uniform float screenBrightness;

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


vec3 decode (vec2 enc){
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}

vec3 YCoCg2RGB(vec3 c){
	c.y-=0.5;
	c.z-=0.5;
	return vec3(c.r+c.g-c.b, c.r + c.b, c.r - c.g - c.b);
}

#ifdef Celshading
float edepth(vec2 coord) {
	return texture2D(depthtex1,coord).z;
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

#ifdef TAA
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

vec3 toScreenSpace(vec3 p) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = p * 2.0 - 1.0;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragposition.xyz / fragposition.w;
}

#ifdef SSDO
uniform float frameTimeCounter;
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

vec2 decodeVec2(float a){
    const vec2 constant1 = 65535. / vec2( 256., 65536.);
    const float constant2 = 256. / 255.;
    return fract( a * constant1 ) * constant2 ;
}

uniform mat4 gbufferModelViewInverse;

void main() {

//Setup depth
float depth0 = texture2D(depthtex0, texcoord).x;	//everything
float depth1 = texture2D(depthtex1, texcoord).x;	//transparency

bool sky = (depth1 >= 1.0);

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

	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03*0.65+tr*0.17*0.65);
	float finalminlight = (nightVision > 0.01)? 0.15 : (minlight+0.006)+(screenBrightness*0.0125); //add nightvision support but make sure minlight is still adjustable.	
	vec3 ambientC = ao*amb1 + emissiveLightC*(emitted*15.*color + torch_lightmap*ao)*0.66 + ao*finalminlight*min(skyL+6/16.,9/16.)*normalize(amb1+0.0001);
	/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	
	color *= (ambientC*(isnsun?1.0/(SkyL2*skyL*0.5+0.5):1.0)*1.4)*0.63;
}

//Draw skytexture from gbuffers_skytextured
if (sky)color = pow(texture2D(composite, texcoord.xy).rgb,vec3(2.2));

gl_FragData[0] = vec4(0.0);	//used by custom skycolor, godrays and VL not needed in end dimension
gl_FragData[1] = vec4(pow(color/257.0,vec3(0.454)), 1.0);
}
