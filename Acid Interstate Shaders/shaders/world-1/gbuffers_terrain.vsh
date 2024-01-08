#version 120

#define composite2
#define gbuffers_terrain
#include "/shaders.settings"

//Moving entities IDs
//See block.properties for mapped ids
#define ENTITY_SMALLGRASS   10031.0
#define ENTITY_LOWERGRASS   10175.0		//lower half only in 1.13+
#define ENTITY_UPPERGRASS	10176.0		//upper half only used in 1.13+
#define ENTITY_SMALLENTS    10059.0
#define ENTITY_LEAVES       10018.0
#define ENTITY_VINES        10106.0
#define ENTITY_LILYPAD      10111.0
#define ENTITY_FIRE         10051.0
#define ENTITY_LAVA   		10010.0
#define ENTITY_EMISSIVE		10089.0 	//emissive blocks defined in block.properties
#define ENITIY_SOULFIRE		10091.0
#define METALLIC_BLOCK		10080.0		//defined in block.properties
#define POLISHED_BLOCK		10081.0
#define ENTITY_INVERTED_LOWER 10177.0	//hanging_roots

varying vec4 color;
varying vec4 texcoord;
varying vec4 normal;
varying vec3 worldpos;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
const float PI = 3.1415927;
const float PI48 = 150.796447372;
float pi2wt = (PI48*frameTimeCounter) * animationSpeed;

#if nMap >= 1 || defined metallicRefl || defined polishedRefl
attribute vec4 at_tangent;                      //xyz = tangent vector, w = handedness, added in 1.7.10
varying float block;
varying float dist;
varying vec3 viewVector;
varying mat3 tbnMatrix;
varying vec4 vtexcoordam; // .st for add, .pq for mul
varying vec2 vtexcoord;
#endif

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
	ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
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
	
	//Positioning
	/*
	bool entities = (mc_Entity.x == ENTITY_VINES || mc_Entity.x == ENTITY_SMALLENTS || mc_Entity.x == 10030.0 || mc_Entity.x == 10031.0 || mc_Entity.x == 10115.0 || mc_Entity.x == ENTITY_LILYPAD 
					|| mc_Entity.x == ENTITY_LAVA || mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_SMALLGRASS || mc_Entity.x == ENTITY_UPPERGRASS || mc_Entity.x == ENTITY_LOWERGRASS);
	*/
	normal.a = 0.02;
	normal.xyz = normalize(gl_NormalMatrix * gl_Normal);
	texcoord = vec4((gl_MultiTexCoord0).xy,(gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
	
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
		 worldpos = position.xyz + cameraPosition;
	bool istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t;

#ifdef Waving_Tallgrass
if (mc_Entity.x == ENTITY_LOWERGRASS && istopv || mc_Entity.x == ENTITY_UPPERGRASS)
			position.xyz += calcMove(worldpos.xyz,
			0.0041,
			0.0070,
			0.0044,
			0.0038,
			0.0240,
			0.0000,
			vec3(0.8,0.0,0.8),
			vec3(0.4,0.0,0.4));

#endif
if (istopv) {
	#ifdef Waving_Grass
	if ( mc_Entity.x == ENTITY_SMALLGRASS)
			position.xyz += calcMove(worldpos.xyz,
				0.0041,
				0.0070,
				0.0044,
				0.0038,
				0.0063,
				0.0000,
				vec3(3.0,1.6,3.0),
				vec3(0.0,0.0,0.0));
	#endif
	#ifdef Waving_Entities
	if ( mc_Entity.x == ENTITY_SMALLENTS)
			position.xyz += calcMove(worldpos.xyz,
			0.0041,
			0.0070,
			0.0044,
			0.0038,
			0.0240,
			0.0000,
			vec3(0.8,0.0,0.8),
			vec3(0.4,0.0,0.4));
	#endif
	#ifdef Waving_Fire
	if ( mc_Entity.x == ENTITY_FIRE)
			position.xyz += calcMove(worldpos.xyz,
			0.0105,
			0.0096,
			0.0087,
			0.0063,
			0.0097,
			0.0156,
			vec3(1.2,0.4,1.2),
			vec3(0.8,0.8,0.8));
	#endif
}

	#ifdef Waving_Leaves
	if ( mc_Entity.x == ENTITY_LEAVES)
			position.xyz += calcMove(worldpos.xyz,
			0.0040,
			0.0064,
			0.0043,
			0.0035,
			0.0037,
			0.0041,
			vec3(1.0,0.2,1.0),
			vec3(0.5,0.1,0.5));
	#endif
	#ifdef Waving_Vines
	if ( mc_Entity.x == ENTITY_VINES)
			position.xyz += calcMove(worldpos.xyz,
			0.0040,
			0.0064,
			0.0043,
			0.0035,
			0.0037,
			0.0041,
			vec3(0.5,1.0,0.5),
			vec3(0.25,0.5,0.25));

	if (mc_Entity.x == ENTITY_INVERTED_LOWER && gl_MultiTexCoord0.t > mc_midTexCoord.t)
			position.xyz += calcMove(worldpos.xyz,
			0.0041,
			0.0070,
			0.0044,
			0.0038,
			0.0240,
			0.0000,
			vec3(0.8,0.0,0.8),
			vec3(0.4,0.0,0.4));			
	#endif

	#ifdef Waving_Lava
	if(mc_Entity.x == ENTITY_LAVA){
		float fy = fract(worldpos.y + 0.001);
		float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.2 + worldpos.x /  7.0 + worldpos.z / 13.0))
				   + 0.05 * sin(2 * PI * (frameTimeCounter*0.15 + worldpos.x / 11.0 + worldpos.z /  5.0));
		position.y += clamp(wave, -fy, 1.0-fy)*0.5;
	}
	#endif
	
	#ifdef Waving_Lilypads
	if(mc_Entity.x == ENTITY_LILYPAD){
		float fy = fract(worldpos.y + 0.001);
		float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.8 + worldpos.x /  2.5 + worldpos.z / 5.0))
				   + 0.05 * sin(2 * PI * (frameTimeCounter*0.6 + worldpos.x / 6.0 + worldpos.z /  12.0));
		position.y += clamp(wave, -fy, 1.0-fy)*1.05;
	}
	#endif
	
	#ifdef Waving_Lanterns
	if(mc_Entity.x == 10090.0){
		vec3 fxyz = fract(worldpos.xyz + 0.001);
		float wave = 0.025 * sin(2 * PI * (frameTimeCounter*0.4 + worldpos.x * 0.5 + worldpos.z * 0.5));
		float waveY = 0.05 * cos(frameTimeCounter*2.0 + worldpos.y);
		position.x -= clamp(wave, -fxyz.x, 1.0-fxyz.x);
		position.y += clamp(waveY*0.25, -fxyz.y, 1.0-fxyz.y)+0.015;		
		position.z += clamp(wave*0.45, -fxyz.z, 1.0-fxyz.z);
	}
	#endif

	color = gl_Color;

	if(mc_Entity.x == METALLIC_BLOCK) normal.a = 0.4;
	if(mc_Entity.x == POLISHED_BLOCK) normal.a = 0.5;

	//Fix colors on emissive blocks, removed lava as it might cause issues with custom optifine color maps.
	if (mc_Entity.x == ENTITY_FIRE
	|| mc_Entity.x == ENTITY_EMISSIVE
	|| mc_Entity.x == ENITIY_SOULFIRE		
	|| mc_Entity.x == 10090.0){
	normal.a = 0.6;	
	color = vec4(1.0);
	}

	if(mc_Entity.x == ENITIY_SOULFIRE || mc_Entity.x == 10090.0) texcoord.z = 0.85;

	if(mc_Entity.x == ENTITY_LAVA) normal.a = 0.6;

	if(mc_Entity.x == 10300.0) color = vec4(1.0); //fix lecterns


	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
#ifdef TAA
	gl_Position.xy += offsets[framemod8] * gl_Position.w*texelSize;
#endif

#if nMap >= 1 || defined metallicRefl || defined polishedRefl
	block = mc_Entity.x;
	if(mc_Entity.x == ENTITY_EMISSIVE) block = -1.0; //enable bump and parallax mapping for defined ids.
	#ifdef entityBump
		block = 1.0;
	#endif		
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texcoordminusmid = texcoord.xy-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord.xy ,midcoord-texcoordminusmid);
	vtexcoord.xy    = sign(texcoordminusmid)*0.5+0.5;
	
	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	
	tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
					 tangent.y, binormal.y, normal.y,
					 tangent.z, binormal.z, normal.z);
	
	//viewVector = tbnMatrix * (mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz);
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	dist = length(gl_ModelViewMatrix * gl_Vertex);
#endif
}