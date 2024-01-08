#version 120
/* DRAWBUFFERS:56 */
//Render entities etc in here, boost and fix enchanted armor effect in gbuffers_armor_glint
#define gbuffers_shadows
#define gbuffers_texturedblock
#include "shaders.settings"

varying vec4 color;
varying vec2 texcoord;
varying vec3 normal;
varying vec3 ambientNdotL;
varying vec3 finalSunlight;
varying float skyL;
#ifdef Shadows
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform sampler2DShadow shadowtex0;

vec3 toScreenSpace(vec3 pos) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
	if(gl_ProjectionMatrix[2][2] > -0.5) pos.z += 0.38;		//hand
	vec3 p3 = pos * 2.0 - 1.0;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragposition.xyz / fragposition.w;
}

float shadowfilter(vec3 shadowpos, float dif){
	vec2 offset = vec2(0.65, -0.65) / shadowMapResolution;	
	return clamp(dot(vec4(shadow2D(shadowtex0,vec3(shadowpos.xy + offset.xx, shadowpos.z)).x,
						  shadow2D(shadowtex0,vec3(shadowpos.xy + offset.yx, shadowpos.z)).x,
						  shadow2D(shadowtex0,vec3(shadowpos.xy + offset.xy, shadowpos.z)).x,
						  shadow2D(shadowtex0,vec3(shadowpos.xy + offset.yy, shadowpos.z)).x),vec4(0.25))*dif,0.0,1.0);
}
#endif
uniform sampler2D texture;

uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;

uniform vec3 shadowLightPosition;
uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;
uniform vec4 entityColor;
uniform int entityId; 

void main() {

	float diffuse = clamp(dot(normalize(shadowLightPosition),normal),0.0,1.0);
	vec4 albedo = texture2D(texture, texcoord.xy)*color;
	#ifdef MobsFlashRed
	albedo.rgb = mix(albedo.rgb,entityColor.rgb,entityColor.a);
	#endif

	#ifdef Shadows
	#define diagonal3(mat) vec3((mat)[0].x, (mat)[1].y, (mat)[2].z)
	//don't do shading if transparent/translucent (not opaque)
	if (diffuse > 0.0 && rainStrength < 0.9 && albedo.a > 0.01){
	vec3 fragposition = toScreenSpace(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z));

	vec3 worldposition = mat3(gbufferModelViewInverse) * fragposition.xyz + gbufferModelViewInverse[3].xyz;
		 worldposition = mat3(shadowModelView) * worldposition.xyz + shadowModelView[3].xyz;
		 worldposition = diagonal3(shadowProjection) * worldposition.xyz + shadowProjection[3].xyz;
	
	float distortion = calcDistortion(worldposition.xy);
	float threshMul = max(2048.0/shadowMapResolution*shadowDistance/128.0,1.5); //increased offset to fix self shadowing on armor
	float distortThresh = (sqrt(1.0-diffuse*diffuse)/diffuse+0.7)/distortion;	
	float bias = distortThresh/6000.0*threshMul;

		worldposition.xy *= distortion;
		worldposition.xyz = worldposition.xyz * vec3(0.5,0.5,0.5/6.0) + vec3(0.5,0.5,0.5);
		worldposition.z -= bias;

	//Fast and simple shadow drawing for proper rendering of entities etc
	diffuse *= shadowfilter(worldposition, diffuse);
	diffuse *= (1.0 - rainStrength);
	diffuse *= mix(skyL,1.0,clamp((eyeBrightnessSmooth.y/255.0-2.0/16.)*4.0,0.0,1.0)); //avoid light leaking underground	
	}
	#else
	diffuse *= mix(skyL,1.0,clamp((eyeBrightnessSmooth.y/255.0-4.0/16.)*4.0,0.0,1.0)); //Fix lighting in caves with if shadows are disabled
	#endif

	vec3 finalColor = pow(albedo.rgb,vec3(2.2)) * (finalSunlight*diffuse+ambientNdotL.rgb);

	//Lightning rendering
	if(entityId == 11000.0){
		float night = clamp((worldTime-13000.0)/300.0,0.0,1.0)-clamp((worldTime-22800.0)/200.0,0.0,1.0);
		finalColor = vec3(0.025, 0.03, 0.05) * (1.0-0.75*night);
		albedo.a = 1.0;
	}

	gl_FragData[0] = vec4(finalColor, albedo.a);
	gl_FragData[1] = vec4(normalize(albedo.rgb+0.00001), albedo.a);		
}