#if !defined DEBUG_GLSL
#define DEBUG_GLSL


//#define DEBUG
#define DEBUG_VIEW 0 // [-1 0 1 2 3 7]

#if ShaderStage < 0 && defined vsh
	out vec3 vDebug;
	#define Debug vDebug
#elif ShaderStage < 0 && defined fsh
	in vec3 vDebug;
	vec3 Debug = vDebug;
#else
	vec3 Debug = vec3(0.0);
#endif

void show( bool x) { Debug = vec3(float(x)); }
void show(float x) { Debug = vec3(x); }
void show( vec2 x) { Debug = vec3(x, 0.0); }
void show( vec3 x) { Debug = x; }
void show( vec4 x) { Debug = x.rgb; }

#define show(x) show(x);

#endif
