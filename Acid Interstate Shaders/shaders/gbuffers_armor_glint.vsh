#version 120

varying vec4 color;
varying vec2 texcoord;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#define composite2
#include "shaders.settings"

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
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
#ifdef TAA
	gl_Position.xy += offsets[framemod8] * gl_Position.w*texelSize;
#endif
	
	color = gl_Color;
	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}