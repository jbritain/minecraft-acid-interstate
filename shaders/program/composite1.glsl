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
	
	
	SetupShading();
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

#include "/lib/Settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler3D colortex7;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;

#ifdef FLOODFILL_BLOCKLIGHT
uniform sampler3D lightVoxelTex;
uniform sampler3D lightVoxelFlipTex;
#endif

#if (defined GI_ENABLED) || (defined AO_ENABLED)
const bool colortex5MipmapEnabled = true;
uniform sampler2D colortex5;
#endif

#ifdef VL_ENABLED
const bool colortex6MipmapEnabled = true;
uniform sampler2D colortex6;
#endif

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

uniform sampler2D shadowtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D portalshadowtex;

uniform sampler2D bluenoisetex;

#if defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
uniform sampler2DShadow shadowtex0HW;
uniform sampler2DShadow shadowtex1HW;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform vec3 previousCameraPosition;
uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform vec3 eyePosition;

uniform vec2 pixelSize;
uniform float aspectRatio;

uniform float viewWidth;
uniform float viewHeight;
uniform float biomeWetness;
uniform float biomePrecipness;
uniform float humiditySmooth;
uniform float biomeCanRainSmooth;

uniform float nightVision;
uniform float near;
uniform float far;

uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Uniform/Projection_Matrices.fsh"
#include "/lib/Uniform/Shadow_View_Matrix.fsh"
#include "/lib/Fragment/Masks.fsh"
#include "/lib/Fragment/3D_Clouds.fsh"

vec3 GetDiffuse(vec2 coord) {
	return texture(colortex1, coord).rgb;
}

float GetDepth(vec2 coord) {
	return texture(depthtex0, coord).x;
}

float GetTransparentDepth(vec2 coord) {
	return texture(depthtex1, coord).x;
}


float ExpToLinearDepth(float depth) {
	return 2.0 * near * (far + near - depth * (far - near));
}

vec3 CalculateViewSpacePosition(vec3 screenPos) {
	screenPos = screenPos * 2.0 - 1.0;
	
	return projMAD(gbufferProjectionInverse, screenPos) / (screenPos.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}


#include "/lib/Voxel/VoxelPosition.glsl"
#include "/lib/Fragment/ComputeShadedFragment.fsh"




#include "/lib/Fragment/BilateralUpsample.fsh"

#include "/lib/Misc/CalculateFogfactor.glsl"

/* RENDERTARGETS:1,4,6,5,10 */
#include "/lib/Exit.glsl"

void main() {
	vec4 texture4 = ScreenTex(colortex4);
	
	vec4  decode4       = Decode4x8F(texture4.r);
	vec4 	decode4b			= Decode4x8F(texture4.b);
	Mask  mask          = CalculateMasks(decode4.r);
	float torchLightmap = decode4.b;
	float skyLightmap   = decode4.a;
	float emission			= texture(colortex9, texcoord).b;
	float materialAO		= clamp01(decode4b.r);
	float SSS				= clamp01(decode4b.g);

	
	float backDepth = (GetDepth(texcoord));
	
	vec3 wNormal = DecodeNormal(texture4.g, 11);
	vec3 normal  = mat3(gbufferModelView) * wNormal;
	vec3 wGeometryNormal = DecodeNormal(texture4.a, 16);
	vec3 geometryNormal = mat3(gbufferModelView) * wGeometryNormal;
	
	float frontDepth = mask.hand > 0.5 ? backDepth : GetTransparentDepth(texcoord);
	
	mask.transparent = clamp01(float(texture(colortex3, texcoord).a != 0.0) + float(frontDepth != backDepth) + mask.transparent);


	if (mask.transparent == 1.0) {
		vec2 texture0 = texture(colortex0, texcoord).rg;
		
		vec4 decode0 = Decode4x8F(texture0.r);
		
		mask.water       = decode0.b;
		mask.bits.xy     = vec2(mask.transparent, mask.water);
		mask.materialIDs = EncodeMaterialIDs(1.0, mask.bits);

		texture4.rg = vec2(Encode4x8F(vec4(mask.materialIDs, decode0.r, 0.0, decode0.g)), texture0.g);
	}
	
	vec4 GI; vec2 VL;
	BilateralUpsample(wNormal, frontDepth, GI, VL);

	
	gl_FragData[1] = vec4(texture4.rg, 0.0, 1.0);
	gl_FragData[2] = vec4(VL.xy, 0.0, 1.0);
	
	
	mat2x3 backPos;
	backPos[0] = CalculateViewSpacePosition(vec3(texcoord, frontDepth));
	backPos[1] = mat3(gbufferModelViewInverse) * backPos[0];	

	mat2x3 preAcidPosition;
	vec4 texture11 = texture(colortex11, texcoord);
	preAcidPosition[1] = texture11.rgb;
	bool rightOfPortal = texture11.a > 0.5;

	show(texture(shadowtex0, texcoord));

	// preAcidPosition[0] = mat3(gbufferModelView) * preAcidPosition[1];

	#ifdef WORLD_OVERWORLD
	vec4 cloud = CalculateClouds3(backPos[1], frontDepth);
	gl_FragData[3] = vec4(sqrt(cloud.rgb / 50.0), cloud.a);
	#endif



	if (frontDepth - mask.hand >= 1.0) {
		 exit(); 
		 return; 
	}
	
	
	vec3 diffuse = GetDiffuse(texcoord);

	vec3 viewSpacePosition0 = CalculateViewSpacePosition(vec3(texcoord, backDepth));
	
	vec3 sunlight = ComputeSunlight(preAcidPosition[1], normal, geometryNormal, 1.0, SSS, skyLightmap, rightOfPortal);

	if(mask.water == 1.0){
		float distCoeff = GetDistanceCoeff(backPos[1]);
		sunlight = mix(sunlight, WATER_COLOR.rgb * (1.0 - WATER_COLOR.a), distCoeff);
	}
	

	vec3 composite = ComputeShadedFragment(powf(diffuse, 2.2), mask, torchLightmap, skyLightmap, GI, normal, emission, backPos, materialAO, SSS, geometryNormal, sunlight);

	gl_FragData[4] = vec4(sunlight, 1.0);

	gl_FragData[0] = vec4(max0(composite), 1.0);
	
	exit();
}

#endif
/***********************************************************************/
