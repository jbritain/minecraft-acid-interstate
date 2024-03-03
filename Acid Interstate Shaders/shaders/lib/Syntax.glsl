#if defined fsh
	#define varying in
#endif

#if defined vsh
	#define attribute in
	#define varying out
#endif

#define io inout

#define ON  true
#define OFF false

#define cbool  const bool
#define cbvec2 const bvec2
#define cbvec3 const bvec3
#define cbvec4 const bvec4

#define cuint  const uint
#define cuvec2 const uvec2
#define cuvec3 const uvec3
#define cuvec4 const uvec4

#define cint   const int
#define civec2 const ivec2
#define civec3 const ivec3
#define civec4 const ivec4

#define cfloat const float
#define cvec2  const vec2
#define cvec3  const vec3
#define cvec4  const vec4

#define DEFINE_genFType(func) func(float) func(vec2) func(vec3) func(vec4)
#define DEFINE_genVType(func) func(vec2) func(vec3) func(vec4)
#define DEFINE_genDType(func) func(double) func(dvec2) func(dvec3) func(dvec4)
#define DEFINE_genIType(func) func(int) func(ivec2) func(ivec3) func(ivec4)
#define DEFINE_genUType(func) func(uint) func(uvec2) func(uvec3) func(uvec4)
#define DEFINE_genBType(func) func(bool) func(bvec2) func(bvec3) func(bvec4)
