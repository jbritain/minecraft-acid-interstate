#include "/lib/Syntax.glsl"


varying vec2 texcoord;

#include "/lib/Uniform/Shading_Variables.glsl"


/***********************************************************************/
#if defined vsh

uniform sampler3D colortex7;

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float sunAngle;
uniform float far;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Uniform/Projection_Matrices.vsh"
#include "/UserProgram/centerDepthSmooth.glsl"
#include "/lib/Uniform/Shadow_View_Matrix.vsh"
#include "/lib/Fragment/PrecomputedSky.glsl"
#include "/lib/Vertex/Shading_Setup.vsh"

void main() {
	texcoord    = gl_MultiTexCoord0.st;
	gl_Position = ftransform();
	
	SetupProjection();
	SetupShading();
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D gdepthtex;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform vec2 pixelSize;

uniform float rainStrength;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Uniform/Projection_Matrices.fsh"
#include "/lib/Uniform/Shadow_View_Matrix.fsh"
#include "/lib/Fragment/Masks.fsh"
#include "/lib/Fragment/Tonemap.fsh"

vec3 GetColor(vec2 coord) {
	return DecodeColor(texture2D(colortex3, coord).rgb);
}

float GetDepth(vec2 coord) {
	return texture2D(gdepthtex, coord).x;
}

vec3 CalculateViewSpacePosition(vec3 screenPos) {
	return projMAD(projInverseMatrix, screenPos) / (screenPos.z * projInverseMatrix[2].w + projInverseMatrix[3].w);
}

vec3 ViewSpaceToScreenSpace(vec3 viewSpacePosition) {
	return projMAD(projMatrix, viewSpacePosition) / -viewSpacePosition.z;
}

vec3 MotionBlur(vec3 color, float depth, float handMask) {
#ifndef MOTION_BLUR
	return color;
#endif
	
	if (handMask > 0.5) return color;
	
	vec3 position = vec3(texcoord, depth) * 2.0 - 1.0; // Signed [-1.0 to 1.0] screen space position
	
	vec3 previousPos    = CalculateViewSpacePosition(position);
	     previousPos    = transMAD(gbufferModelViewInverse, previousPos);
	     previousPos   += cameraPosition - previousCameraPosition;
	     previousPos    = transMAD(gbufferPreviousModelView, previousPos);
	     previousPos.xy = projMAD(projMatrix, previousPos).xy / -previousPos.z;
	
	cfloat intensity = MOTION_BLUR_INTENSITY * 0.5;
	cfloat maxVelocity = MAX_MOTION_BLUR_AMOUNT * 0.1;
	
	vec2 velocity = (position.st - previousPos.st) * intensity; // Screen-space motion vector
	     velocity = clamp(velocity, vec2(-maxVelocity), vec2(maxVelocity));
	
#if VARIABLE_MOTION_BLUR_SAMPLES == 1
	float sampleCount = length(velocity / pixelSize) * VARIABLE_MOTION_BLUR_SAMPLE_COEFFICIENT; // There should be exactly 1 sample for every pixel when the sample coefficient is 1.0
	      sampleCount = floor(clamp(sampleCount, 1, MAX_MOTION_BLUR_SAMPLE_COUNT));
#else
	cfloat sampleCount = CONSTANT_MOTION_BLUR_SAMPLE_COUNT;
#endif
	
	vec2 sampleStep = velocity / sampleCount;
	
	color *= 0.001;
	
	for(float i = 1.0; i <= sampleCount; i++) {
		vec2 coord = texcoord - sampleStep * i;
		
		color += pow2(texture2D(colortex3, clampScreen(coord, pixelSize)).rgb);
	}
	
	return color * 1000.0 / max(sampleCount + 1.0, 1.0);
}

vec3 GetBloomTile(cint scale, vec2 offset) {
	vec2 coord  = texcoord;
	     coord /= scale;
	     coord += offset + pixelSize;
	
	return DecodeColor(texture2D(colortex1, coord).rgb);
}

vec3 GetBloom(vec3 color) {
#ifndef BLOOM_ENABLED
	return color;
#endif
	
	vec3[8] bloom;
	
	// These arguments should be identical to those in composite2.fsh
	bloom[1] = GetBloomTile(  4, vec2(0.0                         ,                          0.0));
	bloom[2] = GetBloomTile(  8, vec2(0.0                         , 0.25     + pixelSize.y * 2.0));
	bloom[3] = GetBloomTile( 16, vec2(0.125    + pixelSize.x * 2.0, 0.25     + pixelSize.y * 2.0));
	bloom[4] = GetBloomTile( 32, vec2(0.1875   + pixelSize.x * 4.0, 0.25     + pixelSize.y * 2.0));
	bloom[5] = GetBloomTile( 64, vec2(0.125    + pixelSize.x * 2.0, 0.3125   + pixelSize.y * 4.0));
	bloom[6] = GetBloomTile(128, vec2(0.140625 + pixelSize.x * 4.0, 0.3125   + pixelSize.y * 4.0));
	bloom[7] = GetBloomTile(256, vec2(0.125    + pixelSize.x * 2.0, 0.328125 + pixelSize.y * 6.0));
	
	bloom[0] = vec3(0.0);
	
	for (uint index = 1; index <= 7; index++)
		bloom[0] += bloom[index];
	
	bloom[0] /= 7.0;
	
	return mix(color, min(pow(bloom[0], vec3(BLOOM_CURVE)), bloom[0]), BLOOM_AMOUNT);
}

vec3 Vignette(vec3 color) {
	float edge = distance(texcoord, vec2(0.5));
	
	return color * (1.0 - pow(edge * 1.0, 1.5));
}

#include "/lib/Exit.glsl"

void main() {
	float depth = GetDepth(texcoord);
	vec3  color = GetColor(texcoord);
	Mask  mask  = CalculateMasks(texture2D(colortex2, texcoord).r);
	
	color = MotionBlur(color, depth, mask.hand);
	color =   GetBloom(color);
	color =   Vignette(color);
	color =    Tonemap(color);
	
	gl_FragColor = vec4(color, 1.0);
	
	exit();
}

#endif
/***********************************************************************/
