#define powf(x, f) exp2((f) * log2(x))

#define pow2_(type) type pow2(type x) { return x * x; }
#define pow3_(type) type pow3(type x) { return x * x * x; }
#define pow4_(type) type pow4(type x) { x *= x; return x * x; }
#define pow5_(type) type pow5(type x) { type x2 = x * x; return x2 * x2 * x; }
#define pow6_(type) type pow6(type x) { type x2 = x * x; return x2 * x2 * x2; }
#define pow7_(type) type pow7(type x) { type x2 = x * x; return x2 * x2 * x2 * x; }
#define pow8_(type) type pow8(type x) { x *= x; x *= x; return x * x; }

DEFINE_genFType(pow2_)
DEFINE_genFType(pow3_)
DEFINE_genFType(pow4_)
DEFINE_genFType(pow5_)
DEFINE_genFType(pow6_)
DEFINE_genFType(pow7_)
DEFINE_genFType(pow8_)
