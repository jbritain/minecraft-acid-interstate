#version 120
/* DRAWBUFFERS:67 */

/* Temporal anti-aliasing (TAA) and adaptive sharpening implementation based on Chocapic13, all credits belong to him:
https://www.minecraftforum.net/forums/mapping-and-modding-java-edition/minecraft-mods/1293898-1-14-chocapic13s-shaders */

#define composite2
#include "shaders.settings"

varying vec2 texcoord;
uniform float viewWidth;
uniform float viewHeight;
vec2 texelSize = vec2(1.0/viewWidth,1.0/viewHeight);
uniform sampler2D colortex6;

uniform sampler2D colortex3;			//Input everything from composite1
uniform sampler2D colortex7;			//Output bloom and TAA
const bool colortex7Clear = false;

#ifdef TAA
uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float near;
uniform float far;

//setup mats
float getmat = texture2D(colortex0,texcoord).b;
vec3 normal = texture2D(colortex2,texcoord).xyz;
bool emissive = getmat > 0.59 && getmat < 0.61;
bool iswater = normal.z < 0.2499 && dot(normal,normal) > 0.0;
float depth0 = texture2D(depthtex0, texcoord).x;

#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

vec3 toClipSpace3Prev(vec3 viewSpacePosition) {
    return projMAD(gbufferPreviousProjection, viewSpacePosition) / -viewSpacePosition.z * 0.5 + 0.5;
}

vec3 toScreenSpace(vec3 p) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = p * 2.0 - 1.0;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragposition.xyz / fragposition.w;
}

#define BLEND_FACTOR 0.1 			//[0.01 0.02 0.03 0.04 0.05 0.06 0.08 0.1 0.12 0.14 0.16] higher values = more flickering but sharper image, lower values = less flickering but the image will be blurrier
#define MOTION_REJECTION 1.0		//[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.5] //Higher values=sharper image in motion at the cost of flickering
#define ANTI_GHOSTING 0.0			//[0.0 0.25 0.5 0.75 1.0] High values reduce ghosting but may create flickering
#define FLICKER_REDUCTION 1.0		//[0.0 0.25 0.5 0.75 1.0] High values reduce flickering but may reduce sharpness

//returns the projected coordinates of the closest point to the camera in the 3x3 neighborhood
vec3 closestToCamera5taps(vec2 texcoord){
	vec2 du = vec2(texelSize.x*2., 0.0);
	vec2 dv = vec2(0.0, texelSize.y*2.);

	vec3 dtl = vec3(texcoord,0.) + vec3(-texelSize, texture2D(depthtex0, texcoord - dv - du).x);
	vec3 dtr = vec3(texcoord,0.) +  vec3( texelSize.x, -texelSize.y, texture2D(depthtex0, texcoord - dv + du).x);
	vec3 dmc = vec3(texcoord,0.) + vec3( 0.0, 0.0, texture2D(depthtex0, texcoord).x);
	vec3 dbl = vec3(texcoord,0.) + vec3(-texelSize.x, texelSize.y, texture2D(depthtex0, texcoord + dv - du).x);
	vec3 dbr = vec3(texcoord,0.) + vec3( texelSize.x, texelSize.y, texture2D(depthtex0, texcoord + dv + du).x);

	vec3 dmin = dmc;
	dmin = dmin.z > dtr.z? dtr : dmin;
	dmin = dmin.z > dtl.z? dtl : dmin;
	dmin = dmin.z > dbl.z? dbl : dmin;
	dmin = dmin.z > dbr.z? dbr : dmin;
	return dmin;
}

//approximation from SMAA presentation from siggraph 2016
vec3 FastCatmulRom(sampler2D colorTex, vec2 texcoord, vec4 rtMetrics, float sharpenAmount){
    vec2 position = rtMetrics.zw * texcoord;
    vec2 centerPosition = floor(position - 0.5) + 0.5;
    vec2 f = position - centerPosition;
    vec2 f2 = f * f;
    vec2 f3 = f * f2;

    float c = sharpenAmount;
    vec2 w0 =        -c  * f3 +  2.0 * c         * f2 - c * f;
    vec2 w1 =  (2.0 - c) * f3 - (3.0 - c)        * f2         + 1.0;
    vec2 w2 = -(2.0 - c) * f3 + (3.0 -  2.0 * c) * f2 + c * f;
    vec2 w3 =         c  * f3 -                c * f2;

    vec2 w12 = w1 + w2;
    vec2 tc12 = rtMetrics.xy * (centerPosition + w2 / w12);
    vec3 centerColor = texture2D(colorTex, vec2(tc12.x, tc12.y)).rgb;

    vec2 tc0 = rtMetrics.xy * (centerPosition - 1.0);
    vec2 tc3 = rtMetrics.xy * (centerPosition + 2.0);
    vec4 color = vec4(texture2D(colorTex, vec2(tc12.x, tc0.y )).rgb, 1.0) * (w12.x * w0.y ) +
                   vec4(texture2D(colorTex, vec2(tc0.x,  tc12.y)).rgb, 1.0) * (w0.x  * w12.y) +
                   vec4(centerColor,                                      1.0) * (w12.x * w12.y) +
                   vec4(texture2D(colorTex, vec2(tc3.x,  tc12.y)).rgb, 1.0) * (w3.x  * w12.y) +
                   vec4(texture2D(colorTex, vec2(tc12.x, tc3.y )).rgb, 1.0) * (w12.x * w3.y );
	return color.rgb/color.a;

}

vec3 calcTAA(){
	//reproject previous frame
	vec3 closestToCamera = closestToCamera5taps(texcoord);
	vec3 fragposition = toScreenSpace(closestToCamera);
		 fragposition = mat3(gbufferModelViewInverse) * fragposition + gbufferModelViewInverse[3].xyz + (cameraPosition - previousCameraPosition);
	vec3 previousPosition = mat3(gbufferPreviousModelView) * fragposition + gbufferPreviousModelView[3].xyz;
		 previousPosition = toClipSpace3Prev(previousPosition);
		 previousPosition.xy = texcoord + (previousPosition.xy - closestToCamera.xy);

	//to reduce error propagation caused by interpolation during history resampling, we will introduce back some aliasing in motion
	vec2 d = 0.5-abs(fract(previousPosition.xy*vec2(viewWidth,viewHeight)-texcoord*vec2(viewWidth,viewHeight))-0.5);
	float rej = dot(d,d)*MOTION_REJECTION;
	//reject history if off-screen and early exit
	if (previousPosition.x < 0.0 || previousPosition.y < 0.0 || previousPosition.x > 1.0 || previousPosition.y > 1.0) return texture2D(colortex3, texcoord).rgb;

	vec3 albedoCurrent0 = texture2D(colortex3, texcoord).rgb;
  	vec3 albedoCurrent1 = texture2D(colortex3, texcoord + vec2(texelSize.x,texelSize.y)).rgb;
	vec3 albedoCurrent2 = texture2D(colortex3, texcoord + vec2(texelSize.x,-texelSize.y)).rgb;
	vec3 albedoCurrent3 = texture2D(colortex3, texcoord + vec2(-texelSize.x,-texelSize.y)).rgb;
	vec3 albedoCurrent4 = texture2D(colortex3, texcoord + vec2(-texelSize.x,texelSize.y)).rgb;
	vec3 albedoCurrent5 = texture2D(colortex3, texcoord + vec2(0.0,texelSize.y)).rgb;
	vec3 albedoCurrent6 = texture2D(colortex3, texcoord + vec2(0.0,-texelSize.y)).rgb;
	vec3 albedoCurrent7 = texture2D(colortex3, texcoord + vec2(-texelSize.x,0.0)).rgb;
	vec3 albedoCurrent8 = texture2D(colortex3, texcoord + vec2(texelSize.x,0.0)).rgb;	

	//turn sharpening off if set to 0.0, don't sharpen emissive blocks, water, sky and clouds
	if(TAA_sharpness > 0.0 && !iswater && !emissive && depth0 < 1.0-near/far/far){
    vec3 m1 = (albedoCurrent0 + albedoCurrent1 + albedoCurrent2 + albedoCurrent3 + albedoCurrent4 + albedoCurrent5 + albedoCurrent6 + albedoCurrent7 + albedoCurrent8)/9.0;
    vec3 std = abs(albedoCurrent0 - m1) + abs(albedoCurrent1 - m1) + abs(albedoCurrent2 - m1) + abs(albedoCurrent3 - m1) + abs(albedoCurrent3 - m1) + 
			   abs(albedoCurrent4 - m1) + abs(albedoCurrent5 - m1) + abs(albedoCurrent6 - m1) + abs(albedoCurrent7 - m1) + abs(albedoCurrent8 - m1);

    float contrast = 1.0 - dot(std,vec3(0.299, 0.587, 0.114))/9.0;
    albedoCurrent0 = albedoCurrent0*(1.0+TAA_sharpness*contrast)-(albedoCurrent5+albedoCurrent6+albedoCurrent7+albedoCurrent8+(albedoCurrent1 + albedoCurrent2 + albedoCurrent3 + albedoCurrent4)/2.0)/6.0*TAA_sharpness*contrast;
	}

	//Assuming the history color is a blend of the 3x3 neighborhood, we clamp the history to the min and max of each channel in the 3x3 neighborhood
	vec3 cMax = max(max(max(albedoCurrent0,albedoCurrent1),albedoCurrent2),max(albedoCurrent3,max(albedoCurrent4,max(albedoCurrent5,max(albedoCurrent6,max(albedoCurrent7,albedoCurrent8))))));
	vec3 cMin = min(min(min(albedoCurrent0,albedoCurrent1),albedoCurrent2),min(albedoCurrent3,min(albedoCurrent4,min(albedoCurrent5,min(albedoCurrent6,min(albedoCurrent7,albedoCurrent8))))));

	vec3 albedoPrev = FastCatmulRom(colortex7, previousPosition.xy,vec4(texelSize, 1.0/texelSize), 0.82).xyz;

	vec3 finalcAcc = clamp(albedoPrev,cMin,cMax);

	//increases blending factor if history is far away from aabb, reduces ghosting at the cost of some flickering
	float luma = dot(albedoPrev,vec3(0.21, 0.72, 0.07));
	float isclamped = distance(albedoPrev,finalcAcc)/luma;

	//reduces blending factor if current texel is far from history, reduces flickering
	float lumDiff2 = distance(albedoPrev,albedoCurrent0)/luma;
	lumDiff2 = 1.0-clamp(lumDiff2*lumDiff2,0.0,1.0)*FLICKER_REDUCTION;

	//Blend current pixel with clamped history
	return mix(finalcAcc,albedoCurrent0,clamp(BLEND_FACTOR*lumDiff2+rej+isclamped*ANTI_GHOSTING+0.01,0.0,1.0));
}
#endif

#ifdef Bloom
vec3 calcBloom(){
	const int nSteps = 25;
	const int center = 12;		//=nSteps-1 / 2

	vec3 blur = vec3(0.0);
	float tw = 0.0;
	for (int i = 0; i < nSteps; i++) {
		float dist = abs(i-float(center))/center;
		float weight = (exp(-(dist*dist)/ 0.28));

		vec3 bsample = texture2D(colortex7,(texcoord*4.0 + 2.0*texelSize*vec2(i-center,0.0))).rgb;

		blur += bsample*weight;
		tw += weight;
	}
	blur /= tw;

	return clamp(blur,0.0,1.0); //fix flashing black square
}
#endif

void main() {

#ifdef Bloom
	gl_FragData[0] = vec4(calcBloom(), 1.0); 
#else
	gl_FragData[0] = vec4(0.0); 
#endif	
#ifdef TAA
	gl_FragData[1] = vec4(calcTAA(), 1.0);
#else
	gl_FragData[1] = texture2D(colortex3, texcoord);	//if TAA is disabled just passthrough data from previous buffer.
#endif
}
