// Set the length of a vector
#define setLength_(type) type setLength(type v, float x) { \
	return v * (inversesqrt(dot(v, v)) * x); \
}
DEFINE_genVType(setLength_)

// Get the scaling coefficient to normalize a vector
#define norm_(type) float norm(type v) { \
	return inversesqrt(dot(v, v)); \
}
DEFINE_genVType(norm_)


// Get the cosine-angle between a non-normalized vector, and an already normalized one
#define dotNorm_(type) float dotNorm(type v, type normal) { \
	return dot(v, normal) * norm(v); \
}
DEFINE_genVType(dotNorm_)

// Get the cosine-angle between two non-normalized vectors
#define dotNorm2_(type) float dotNorm2(type v1, type v2) { \
	return dot(v1, v2) * norm(v1) * norm(v2); \
}
DEFINE_genVType(dotNorm2_)


#define length2_(type) float length2(type x) { \
return dot(x, x); \
}
DEFINE_genFType(length2_)

#define length8_(type) float length8(type x) { \
	x *= x; \
	x *= x; \
	return pow(dot(x, x), 0.125); \
}
DEFINE_genFType(length8_)

float lengthN(vec2 x, float N) {
	x = pow(abs(x), vec2(N));
	return pow(x.x + x.y, 1.0 / N);
}

float dot4(vec4 v1, vec4 v2) { // Generally faster than dot() unless the output is operating on a vector, in which case dot() seems to be faster. dot4() still seems to be faster when being ASSIGNED to a vector however.
	v1 *= v2;
	return (v1.x + v1.y) + (v1.z + v1.w);
}
