//#define FAST_MATH

#ifdef FAST_MATH
	#define fsqrt(x) intBitsToFloat(0x1FBD1DF5 + (floatBitsToInt(x) >> 1)) // Error of 1.42%
	
	#define finversesqrt(x) intBitsToFloat(0x5F33E79F - (floatBitsToInt(x) >> 1)) // Error of 1.62%
	
	float facos(float x) { // Under 3% error
		float ax = abs(x);
		float res = -0.156583 * ax + HPI;
		res *= fsqrt(1.0 - ax);
		return x >= 0 ? res : PI - res;
	}
	
	#define facos_(type) type facos(type x) { \
		type ax = abs(x); \
		type res = (-0.156583 * ax + HPI); \
		res *= fsqrt(1.0 - ax); \
		return mix(PI - res, res, b##type(greaterThanEqual(x, type(0.0)))); \
	}
	DEFINE_genVType(facos_)
	
#else
	#define fsqrt(x) sqrt(x)
	#define finversesqrt(x) inversesqrt(x)
	#define facos(x) acos(x)
#endif


#define flength_(type) float flength(type x) { return fsqrt(dot(x, x)); }
DEFINE_genFType(flength_)
