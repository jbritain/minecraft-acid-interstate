#include "/lib/Syntax.glsl"


varying vec2 texcoord;

#include "/lib/Uniform/Shading_Variables.glsl"


/***********************************************************************/
#if defined vsh

uniform sampler3D colortex7;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float sunAngle;
uniform float far;

uniform float biomeWetness;
uniform float biomePrecipness;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"

#include "/lib/Uniform/Shadow_View_Matrix.vsh"
#include "/lib/Fragment/PrecomputedSky.glsl"
#include "/lib/Vertex/Shading_Setup.vsh"

void main() {
	texcoord    = gl_MultiTexCoord0.st;
	gl_Position = ftransform();
	
	gl_Position.xy = ((gl_Position.xy * 0.5 + 0.5) * COMPOSITE0_SCALE) * 2.0 - 1.0;
	
	
	
	SetupShading();
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex11;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D noisetex;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D portalshadowtex;

uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform sampler2D bluenoisetex;

#ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
uniform sampler2DShadow shadowtex0HW;
uniform sampler2DShadow shadowtex1HW;
#endif


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;

uniform float biomeWetness;
uniform float biomePrecipness;

uniform int isEyeInWater;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Uniform/Projection_Matrices.fsh"
#include "/lib/Uniform/Shadow_View_Matrix.fsh"
#include "/lib/Fragment/Masks.fsh"

float GetDepth(vec2 coord) {
	return textureRaw(depthtex0, coord).x;
}

float GetDepthLinear(vec2 coord) {
	return (near * far) / (textureRaw(depthtex0, coord).x * (near - far) + far);
}

vec3 CalculateViewSpacePosition(vec3 screenPos) {
	screenPos = screenPos * 2.0 - 1.0;
	
	return projMAD(gbufferProjectionInverse, screenPos) / (screenPos.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}

vec3 GetNormal(vec2 coord) {
	return DecodeNormal(textureRaw(colortex4, coord).xy);
}


vec2 GetDitherred2DNoise(vec2 coord, float n) { // Returns a random noise pattern ranging {-1.0 to 1.0} that repeats every n pixels
	coord *= vec2(viewWidth, viewHeight);
	coord  = mod(coord, vec2(n));
	return texelFetch(noisetex, ivec2(coord), 0).xy;
}

float ExpToLinearDepth(float depth) {
	return 2.0 * near * (far + near - depth * (far - near));
}

#include "/lib/Fragment/ComputeGI.fsh"
#include "/lib/Fragment/ComputeSSAO.fsh"
#include "/lib/Fragment/ComputeVolumetricLight.fsh"


/* RENDERTARGETS:5,6,12 */
#include "/lib/Exit.glsl"

void main() {
	float backDepth = GetDepth(texcoord);
	
// #ifndef VL_ENABLED
// 	if (backDepth >= 1.0) { discard; }
// #endif
	
	
#ifdef COMPOSITE0_NOISE
	vec2 noise2D = GetDitherred2DNoise(texcoord * COMPOSITE0_SCALE, 4.0) * 2.0 - 1.0;
#else
	vec2 noise2D = vec2(0.0);
#endif
	
	vec4 texture4 = textureRaw(colortex4, texcoord);
	
	vec4  decode4       = Decode4x8F(texture4.r);
	vec4 	decode4b			= Decode4x8F(texture4.b);
	Mask  mask          = CalculateMasks(decode4.r);
	float specularity    = decode4.g;
	float torchLightmap = decode4.b;
	float skyLightmap   = decode4.a;
	float SSS				= clamp01(decode4b.g);
	
	float frontDepth = (mask.hand > 0.5 ? backDepth : textureRaw(depthtex1, texcoord).x);
	
	mat2x3 backPos;
	backPos[0] = CalculateViewSpacePosition(vec3(texcoord, frontDepth));
	backPos[1] = mat3(gbufferModelViewInverse) * backPos[0];
	
	mat2x3 frontPos;
	frontPos[0] = CalculateViewSpacePosition(vec3(texcoord, backDepth));
	frontPos[1] = mat3(gbufferModelViewInverse) * frontPos[0];
	
	if (backDepth != frontDepth)
		mask.water = Decode4x8F(texture(colortex0, texcoord).r).b;
	
	vec2 VL = ComputeVolumetricLight(backPos[1], frontPos[1], noise2D, clamp01(mask.water + float(isEyeInWater == 1.0)));
	gl_FragData[1] = vec4(VL, 0.0, 0.0);
	
	if (frontDepth >= 1.0) // Back surface is sky
		{ gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0); exit(); return; }
	
	
	vec3 wNormal = DecodeNormal(texture4.g, 11);
	vec3 normal  = mat3(gbufferModelView) * wNormal;
	vec3 wGeometryNormal = DecodeNormal(texture4.a, 16);
	vec3 geometryNormal = mat3(gbufferModelView) * wGeometryNormal;
	
	float AO = ComputeSSAO(backPos[0], mat3(gbufferModelView) * wNormal);
	
	if (isEyeInWater != mask.water) // If surface is in water
		{ gl_FragData[0] = vec4(0.0, 0.0, 0.0, AO); exit(); return; }
	
	
	vec3 GI = ComputeGI(backPos[1], wNormal, skyLightmap, GI_RADIUS * 2.0, noise2D, mask);
	
	gl_FragData[0] = vec4(sqrt(GI * 0.2), AO);
	exit();
}

#endif
/***********************************************************************/
