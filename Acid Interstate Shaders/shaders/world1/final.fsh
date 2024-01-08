#version 120

#define final
#include "/shaders.settings"

varying vec2 texcoord;

uniform sampler2D gaux4;	//final image

#ifdef Bloom
uniform sampler2D colortex6; //overwritten by bloom
#endif

#if Showbuffer > 0
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
#endif
uniform int isEyeInWater;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;

#if defined Depth_of_Field || defined Motionblur
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
#endif

#ifdef Motionblur
uniform vec3 cameraPosition; 
uniform vec3 previousCameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
#endif

#if defined Depth_of_Field
uniform float near;
uniform float far;
float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}
#endif

#ifdef Depth_of_Field
//Dof constant values
const float focal = 0.024;
float aperture = 0.008;	
const float sizemult = DoF_Strength;
uniform float centerDepthSmooth; 
const float centerDepthHalflife = 2.0f; 
	//hexagon pattern
	const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
											vec2(  0.0000,  0.2500 ),
											vec2( -0.2165,  0.1250 ),
											vec2( -0.2165, -0.1250 ),
											vec2( -0.0000, -0.2500 ),
											vec2(  0.2165, -0.1250 ),
											vec2(  0.4330,  0.2500 ),
											vec2(  0.0000,  0.5000 ),
											vec2( -0.4330,  0.2500 ),
											vec2( -0.4330, -0.2500 ),
											vec2( -0.0000, -0.5000 ),
											vec2(  0.4330, -0.2500 ),
											vec2(  0.6495,  0.3750 ),
											vec2(  0.0000,  0.7500 ),
											vec2( -0.6495,  0.3750 ),
											vec2( -0.6495, -0.3750 ),
											vec2( -0.0000, -0.7500 ),
											vec2(  0.6495, -0.3750 ),
											vec2(  0.8660,  0.5000 ),
											vec2(  0.0000,  1.0000 ),
											vec2( -0.8660,  0.5000 ),
											vec2( -0.8660, -0.5000 ),
											vec2( -0.0000, -1.0000 ),
											vec2(  0.8660, -0.5000 ),
											vec2(  0.2163,  0.3754 ),
											vec2( -0.2170,  0.3750 ),
											vec2( -0.4333, -0.0004 ),
											vec2( -0.2163, -0.3754 ),
											vec2(  0.2170, -0.3750 ),
											vec2(  0.4333,  0.0004 ),
											vec2(  0.4328,  0.5004 ),
											vec2( -0.2170,  0.6250 ),
											vec2( -0.6498,  0.1246 ),
											vec2( -0.4328, -0.5004 ),
											vec2(  0.2170, -0.6250 ),
											vec2(  0.6498, -0.1246 ),
											vec2(  0.6493,  0.6254 ),
											vec2( -0.2170,  0.8750 ),
											vec2( -0.8663,  0.2496 ),
											vec2( -0.6493, -0.6254 ),
											vec2(  0.2170, -0.8750 ),
											vec2(  0.8663, -0.2496 ),
											vec2(  0.2160,  0.6259 ),
											vec2( -0.4340,  0.5000 ),
											vec2( -0.6500, -0.1259 ),
											vec2( -0.2160, -0.6259 ),
											vec2(  0.4340, -0.5000 ),
											vec2(  0.6500,  0.1259 ),
											vec2(  0.4325,  0.7509 ),
											vec2( -0.4340,  0.7500 ),
											vec2( -0.8665, -0.0009 ),
											vec2( -0.4325, -0.7509 ),
											vec2(  0.4340, -0.7500 ),
											vec2(  0.8665,  0.0009 ),
											vec2(  0.2158,  0.8763 ),
											vec2( -0.6510,  0.6250 ),
											vec2( -0.8668, -0.2513 ),
											vec2( -0.2158, -0.8763 ),
											vec2(  0.6510, -0.6250 ),
											vec2(  0.8668,  0.2513 ));								
#endif

vec3 Uncharted2Tonemap(vec3 x) {
	x*= Brightness;
	float A = 0.28;
	float B = 0.29;		
	float C = 0.10;
	float D = 0.2;
	float E = 0.025;
	float F = 0.35;
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

#if Showbuffer == 1 || Showbuffer == 2 || Showbuffer == 3
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
#endif

void main() {

#if defined Depth_of_Field || defined Motionblur
//Setup depths, do it here because amd drivers suck and texture reads outside of void main or functions are broken, thanks amd
float depth0 = texture2D(depthtex0, texcoord).x;
float depth1 = texture2D(depthtex1, texcoord).x;
float depth2 = texture2D(depthtex2, texcoord).x;
bool hand = (depth0 < depth1) || !(depth0 < depth2);
#endif

	float rainlens = 0.0;
	vec2 fake_refract = vec2(0.0);
#ifdef Refraction
		fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0));
#endif
	vec2 newTC = clamp(texcoord + fake_refract * 0.01 * (rainlens+isEyeInWater*0.2),1.0/vec2(viewWidth,viewHeight),1.0-1.0/vec2(viewWidth,viewHeight));
	vec3 color = texture2D(gaux4, newTC.xy).rgb*50.0;

#ifdef Depth_of_Field
if(hand){
	float pw = 1.0/ viewWidth;
	float z = ld(texture2D(depthtex0, newTC.st).r)*far;
	#ifdef smoothDof
	float focus = ld(centerDepthSmooth)*far;
	#else
	float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	#endif
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*15.0);
#ifdef Distance_Blur
	float getdist = 1-(exp(-pow(ld(texture2D(depthtex1, newTC.st).r)/Dof_Distance_View*far,4.0-(2.7*rainStrength))*4.0));	
	pcoc = min(getdist*pw*20.0,pw*20.0);
#endif
	vec3 bcolor = vec3(0.0);
		for ( int i = 0; i < 60; i++) {
			bcolor += texture2D(gaux4, newTC.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb;
			}
		color.rgb = bcolor/61.0*50.0;
}
#endif
	
#ifdef Motionblur
if(hand){
	vec4 currentPosition = vec4(texcoord, depth1, 1.0)*2.0-1.0;
	
	vec4 fragposition = gbufferProjectionInverse * currentPosition;
		 fragposition = gbufferModelViewInverse * fragposition;
		 fragposition /= fragposition.w;
		 fragposition.xyz += cameraPosition;
	
	vec4 previousPosition = fragposition;
		 previousPosition.xyz -= previousCameraPosition;
		 previousPosition = gbufferPreviousModelView * previousPosition;
		 previousPosition = gbufferPreviousProjection * previousPosition;
		 previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).st * MB_strength;
	vec2 coord = texcoord.st + velocity;

	int mb = 1;
	for (int i = 0; i < 15; ++i, coord += velocity) {
		if (coord.s > 1.0 || coord.t > 1.0 || coord.s < 0.0 || coord.t < 0.0) break;
		color += texture2D(gaux4, coord).xyz*50.0;
		++mb;
	}
	color /= mb;
}
#endif

#ifdef Bloom
	color.rgb += texture2D(colortex6, texcoord.xy*0.25).rgb; //upscale bloom buffer.
#endif
	color.rgb += rainlens*0.01; //draw rainlens
	
	vec3 curr = Uncharted2Tonemap(color*4.7);
	color = pow(curr/Uncharted2Tonemap(vec3(15.2)),vec3(1.0/Contrast));

#if Showbuffer == 1
	color = vec3(texture2D(colortex0,texcoord).rg,0.0);

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
#endif
#if Showbuffer == 2
	color = decode(texture2D(colortex1, texcoord).xy);
#endif
#if Showbuffer == 25
	color = vec3(0.0, texture2D(colortex1, texcoord.xy).zw);	//lightmap
#endif
#if Showbuffer == 3
	color = decode(texture2D(colortex2, texcoord).xy);
#endif
#if Showbuffer == 35
	color = vec3(0.0, texture2D(colortex2, texcoord.xy).zw);	//lightmap	
#endif	
#if Showbuffer == 4	
	color = texture2D(colortex3, texcoord.xy).rgb * 200.0;
#endif	
#if Showbuffer == 5	
	color = texture2D(gaux1, texcoord.xy).rgb * 25.0;
#endif	
#if Showbuffer == 6	
	color = texture2D(gaux2, texcoord.xy).rgb * 25.0;
#endif	
#if Showbuffer == 7	
	color = texture2D(gaux3, texcoord.xy*0.25).rgb * 25.0;
#endif	
#if Showbuffer == 8
	color = texture2D(gaux4, texcoord.xy).rgb * 50.0;
#endif

	gl_FragColor = vec4(color,1.0);
}
