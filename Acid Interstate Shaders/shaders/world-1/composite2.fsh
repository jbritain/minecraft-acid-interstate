#version 120
/* DRAWBUFFERS:7 */

/* Temporal anti-aliasing (TAA) and adaptive sharpening implementation based on Chocapic13, all credits belong to him:
https://www.minecraftforum.net/forums/mapping-and-modding-java-edition/minecraft-mods/1293898-1-14-chocapic13s-shaders */

#define composite2
#include "/shaders.settings"

varying vec2 texcoord;
uniform sampler2D composite;		//everything from composite1

#ifdef TAA
const bool gaux4Clear = false;
uniform sampler2D gaux4;			//composite, TAA mixed with everything
uniform sampler2D depthtex0;
/*
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform float near;
uniform float far;
*/
uniform float viewWidth;
uniform float viewHeight;
vec2 texelSize = vec2(1.0/viewWidth,1.0/viewHeight);
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;


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
	float depth0 = texture2D(depthtex0,texcoord).x;
	vec3 closestToCamera = vec3(texcoord,depth0);
	vec3 fragposition = toScreenSpace(closestToCamera);
		 fragposition = mat3(gbufferModelViewInverse) * fragposition + gbufferModelViewInverse[3].xyz + (cameraPosition - previousCameraPosition);
	vec3 previousPosition = mat3(gbufferPreviousModelView) * fragposition + gbufferPreviousModelView[3].xyz;
		 previousPosition = toClipSpace3Prev(previousPosition);
		 previousPosition.xy = texcoord + (previousPosition.xy - closestToCamera.xy);

	//to reduce error propagation caused by interpolation during history resampling, we will introduce back some aliasing in motion
	vec2 d = 0.5-abs(fract(previousPosition.xy*vec2(viewWidth,viewHeight)-texcoord*vec2(viewWidth,viewHeight))-0.5);
	float rej = dot(d,d)*0.5;
	//reject history if off-screen and early exit
	if (previousPosition.x < 0.0 || previousPosition.y < 0.0 || previousPosition.x > 1.0 || previousPosition.y > 1.0) return texture2D(composite, texcoord).rgb;

	//Samples current frame 3x3 neighboorhood
	vec3 albedoCurrent0 = texture2D(composite, texcoord).rgb;
  	vec3 albedoCurrent1 = texture2D(composite, texcoord + vec2(texelSize.x,texelSize.y)).rgb;
	vec3 albedoCurrent2 = texture2D(composite, texcoord + vec2(texelSize.x,-texelSize.y)).rgb;
	vec3 albedoCurrent3 = texture2D(composite, texcoord + vec2(-texelSize.x,-texelSize.y)).rgb;
	vec3 albedoCurrent4 = texture2D(composite, texcoord + vec2(-texelSize.x,texelSize.y)).rgb;
	vec3 albedoCurrent5 = texture2D(composite, texcoord + vec2(0.0,texelSize.y)).rgb;
	vec3 albedoCurrent6 = texture2D(composite, texcoord + vec2(0.0,-texelSize.y)).rgb;
	vec3 albedoCurrent7 = texture2D(composite, texcoord + vec2(-texelSize.x,0.0)).rgb;
	vec3 albedoCurrent8 = texture2D(composite, texcoord + vec2(texelSize.x,0.0)).rgb;

/* - TODO
	float getmat = texture2D(gcolor,texcoord).b;
	bool emissive = getmat > 0.59 && getmat < 0.61;
	vec3 normal = texture2D(gnormal,texcoord).xyz;
	bool iswater = normal.z < 0.2499 && dot(normal,normal) > 0.0;
	if(!iswater && !emissive && depth0 < 1.0-near/far/far){	//don't sharpen emissive blocks, water and sky, clouds
    vec3 m1 = (albedoCurrent0 + albedoCurrent1 + albedoCurrent2 + albedoCurrent3 + albedoCurrent4 + albedoCurrent5 + albedoCurrent6 + albedoCurrent7 + albedoCurrent8)/9.0;
    vec3 std = abs(albedoCurrent0 - m1) + abs(albedoCurrent1 - m1) + abs(albedoCurrent2 - m1) + abs(albedoCurrent3 - m1) + abs(albedoCurrent3 - m1) + 
			   abs(albedoCurrent4 - m1) + abs(albedoCurrent5 - m1) + abs(albedoCurrent6 - m1) + abs(albedoCurrent7 - m1) + abs(albedoCurrent8 - m1);

    float contrast = 1.0 - dot(std,vec3(0.299, 0.587, 0.114))/9.0;
    albedoCurrent0 = albedoCurrent0*(1.0+AS_sharpening*contrast)-(albedoCurrent5+albedoCurrent6+albedoCurrent7+albedoCurrent8+(albedoCurrent1 + albedoCurrent2 + albedoCurrent3 + albedoCurrent4)/2.0)/6.0*AS_sharpening*contrast;
	}
*/

	//Assuming the history color is a blend of the 3x3 neighborhood, we clamp the history to the min and max of each channel in the 3x3 neighborhood
	vec3 cMax = max(max(max(albedoCurrent0,albedoCurrent1),albedoCurrent2),max(albedoCurrent3,max(albedoCurrent4,max(albedoCurrent5,max(albedoCurrent6,max(albedoCurrent7,albedoCurrent8))))));
	vec3 cMin = min(min(min(albedoCurrent0,albedoCurrent1),albedoCurrent2),min(albedoCurrent3,min(albedoCurrent4,min(albedoCurrent5,min(albedoCurrent6,min(albedoCurrent7,albedoCurrent8))))));

	vec3 albedoPrev = FastCatmulRom(gaux4, previousPosition.xy,vec4(texelSize, 1.0/texelSize), 0.82).xyz;
	vec3 finalcAcc = clamp(albedoPrev,cMin,cMax);

	//increases blending factor if history is far away from aabb, reduces ghosting at the cost of some flickering
	float luma = dot(albedoPrev,vec3(0.21, 0.72, 0.07));
	float isclamped = distance(albedoPrev,finalcAcc)/luma;

	//reduces blending factor if current texel is far from history, reduces flickering
	float lumDiff2 = distance(albedoPrev,albedoCurrent0)/luma;
	lumDiff2 = 1.0-clamp(lumDiff2*lumDiff2,0.0,1.0)*0.75;

	//Blend current pixel with clamped history
	return mix(finalcAcc,albedoCurrent0,clamp(0.1*lumDiff2+rej+isclamped+0.01,0.0,1.0));
}
#endif

void main() {

#ifdef TAA
	gl_FragData[0] = vec4(calcTAA(), 1.0);
#else
	gl_FragData[0] = texture2D(composite, texcoord);	//if TAA is disabled just passthrough data from composite0, previous buffer.
#endif
}
