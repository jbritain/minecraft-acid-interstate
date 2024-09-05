const int shadowMapResolution = 8192; // [1024 2048 3072 4096 6144 8192 16384]
#define PORTAL_SHADOW_RESOLUTION 8192
const float sunPathRotation = -40.0; // [-60.0 -50.0 -40.0 -30.0 -20.0 -10.0 0.0 10.0 20.0 30.0 40.0 50.0 60.0]
const float shadowDistance = 512; // [128 192 256 512]
const float shadowIntervalSize = 4.0;

const bool shadowHardwareFiltering = true;

const bool shadowtex1Mipmap = true;
const bool shadowcolor0Mipmap = true;
const bool shadowcolor1Mipmap = true;

const bool shadowtex0Nearest = false;
const bool shadowtex1Nearest = false;
const bool shadowcolor0Nearest = true;
const bool shadowcolor1Nearest = false;

const float eyeBrightnessHalflife = 1.5;
const float ambientOcclusionLevel = 0.65;

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = true;
const bool colortex4Clear = true;
const bool colortex5Clear = true;
const bool colortex6Clear = false;

const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 colortex5ClearColor = vec4(0.1, 0.1, 0.1, 1.0);

const float wetnessHalflife = 40.0;
const float drynessHalflife = 40.0;

const float centerDepthHalflife = 0.5;

#define INFO 0 // [0 1]
#define VERSION 0 // [0 1]

/*
** Transparent Gbuffers **
const int colortex0Format = RG32F;
const int colortex3Format = RGBA16F;

** Flat Gbuffers **
const int colortex1Format = R11F_G11F_B10F;
const int colortex4Format = RGBA32F;

** composite0 Buffers **
const int colortex5Format = RGBA16;
const int colortex6Format = RG8;
const int colortex11Format = RGBA16F;



*/

const float voxelDistance = 256.0;

const int noiseTextureResolution = 64; // [16 32 64 128 256 512 1024]
cfloat noiseRes = float(noiseTextureResolution);
cfloat noiseResInverse = 1.0 / noiseRes;
cfloat noiseScale = 64.0 / noiseRes;

const float zShrink = 4.0;

//#define DEFAULT_TEXTURE_PACK

#define EXPOSURE            1.2 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define SATURATION          1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SUN_LIGHT_LEVEL     1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define SKY_LIGHT_LEVEL     1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define AMBIENT_LIGHT_LEVEL 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define TORCH_LIGHT_LEVEL   1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define SKY_BRIGHTNESS      1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
//#define DIRECTIONAL_LIGHTING

#define SHADOW_MAP_BIAS 0.80 // [0.00 0.60 0.70 0.80 0.85 0.90 0.95]
#define SHADOW_TYPE 2 // [0 1 2 3]
#define PLAYER_SHADOW
#define TRANSPARENT_SHADOWS
#define SHADOW_SOFTNESS 2 // [1 2 3 4 5 6 7 8]
#define SHADOW_SAMPLES 16 // [4 8 16 32 64]
#define MAX_PENUMBRA_WIDTH 16.0
#define MIN_PENUMBRA_WIDTH SHADOW_SOFTNESS * rcp(10)
#define BLOCKER_SEARCH_SAMPLES 1
#define BLOCKER_SEARCH_RADIUS 0.5

cvec3 torchColor = vec3(1.0, 0.46, 0.25) * 0.85;
#define WATER_COLOR vec4(0.001, 0.068, 0.098, 1.0)

#define SUBSURFACE_SCATTERING

//#define RAIN

#if SHADOW_TYPE != 0
#define SHADOWS
#endif
//#define LIMIT_SHADOW_DISTANCE

// #define GI_ENABLED
// #define AO_ENABLED
// #define VL_ENABLED

#define VL_QUALITY 8 // [8 16 32 64]

//#define PLAYER_GI_BOUNCE
#define GI_RADIUS        8   // [2 4 6 8 12 16 24 32]
#define GI_SAMPLE_COUNT 40  // [20 40 80 128 160 256]
#define GI_TRANSLUCENCE  0.5 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GI_BRIGHTNESS    1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define GI_BOOST

// #define BLOOM_ENABLED
#define BLOOM_AMOUNT  0.2 // [0.1 0.2 0.3 0.4 0.5 0.6]
#define BLOOM_CURVE   1.5 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0]

//#define MOTION_BLUR
#define VARIABLE_MOTION_BLUR_SAMPLES            1     // [0 1]
#define VARIABLE_MOTION_BLUR_SAMPLE_COEFFICIENT 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define MAX_MOTION_BLUR_SAMPLE_COUNT            50    // [10 25 50 100 200 500 100]
#define CONSTANT_MOTION_BLUR_SAMPLE_COUNT       2     // [2 3 4 5 10 20 50]
#define MOTION_BLUR_INTENSITY                   1.0   // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define MAX_MOTION_BLUR_AMOUNT                  1.0   // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define TERRAIN_PARALLAX_QUALITY    2.0  // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define TERRAIN_PARALLAX_DISTANCE  32.0  // [4.0 8.0 16.0 32.0 64.0 128.0]
#define TERRAIN_PARALLAX_INTENSITY  1.0 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

// #define WAVING_GRASS
// #define WAVING_LEAVES
#define WAVING_WATER

#define COMPOSITE0_SCALE 1.0 // [0.25 0.33 0.40 0.50 0.60 0.75 1.00]
#define COMPOSITE0_NOISE
#if (defined GI_ENABLED) || (defined AO_ENABLED) || (defined VL_ENABLED)
#define COMPOSITE0_ENABLED
#endif

#define CLOUD2D
#define CLOUD2D_HEIGHT   512  // [256 320 384 448 512 576 640 704 768 832 896 960 1024]
#define CLOUD2D_COVERAGE 0.4  // [0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70]
#define CLOUD2D_SPEED    1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]

// #define CLOUD3D
#define CLOUD3D_START_HEIGHT 260    // [0 50 100 200 260 300 350 400 450 500 550 600 650 700 750 800 850 900 950 1000]
#define CLOUD3D_DEPTH        250    // [50 100 150 200 250 300 350 400 450 500]
#define CLOUD3D_SAMPLES       15    // [3 4 5 6 7 8 9 10 15 20 25 30 40 50 100]
#define CLOUD3D_COVERAGE       0.5  // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]
#define CLOUD3D_DENSITY        0.95 // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 0.97 0.99]
#define CLOUD3D_SPEED          1.0  // [0.25 0.5 1.0 2.5 5.0 10.0]
#define CLOUD3D_LIGHTING     3      // [1 2 3]
#define VolCloudLOD 1 // [0 1 2]
#define BIOME_WEATHER

//#define WATER_PARALLAX
// #define WATER_CAUSTICS
#include "/userProgram/WaterHeight.glsl"
#define VARIABLE_WATER_HEIGHT
// #define WATER_REFRACTION
#define BIOME_WATER_TINT 0.0 // [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.85 0.90 0.95 1.0]
// #define SMOOTH_ICE

#define WAVE_MULT  1.0 // [0.0 0.5 1.0 1.5 2.0]
#define WAVE_SPEED 1.0 // [0.0 0.5 1.0 2.0]

#define DEFORM
#define DEFORMATION 4 // [1 2 3 4]

//#define HIDE_ENTITIES
//#define CLEAR_WATER

#define TIME_OVERRIDE
#define TIME_OVERRIDE_MODE 3 // [1 2 3]
#define CONSTANT_TIME_HOUR 3 // [0 3 6 9 12 15 18 21]
#define CUSTOM_DAY_NIGHT   1 // [1 2]
#define CUSTOM_TIME_MISC   2 // [1 2]

#define SUN_ANGULAR_PERCENTAGE 0.0006

//#define TELEFOCAL_SHADOWS
#define SHADOWS_FOCUS_CENTER

#define TEXTURE_PACK_RESOLUTION 0 // [0 16 32 64 128 256 512 1024 2048 4096]
#define MULTIPLY_METAL_ALBEDO
#define NORMAL_MAPS
//#define TERRAIN_PARALLAX
#define SPECULAR_MAPS
#define EMISSION
#define HARDCODED_EMISSION
// #define HARDCODED_SPECULAR
#define HARDCODED_SSS
#define ROUGH_REFLECTION_THRESHOLD 0.0 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
// #define GLOWING_ORES

#define REFLECTION_SAMPLES 1 // [1 2 4 8 16 32 64]

#define FOG_ENABLED

#define LABPBR_VERSION 1.3 // [1.3 1.3]

// #define FLOODFILL_BLOCKLIGHT

#if defined FLOODFILL_BLOCKLIGHT && defined IRIS_FEATURE_CUSTOM_IMAGES
#define SHADOWCOMP_ENABLED
#endif

// #define FXAA
#define FXAA_SUBPIXEL 0.75 //[0.00 0.25 0.50 0.75 1.00]
#define FXAA_EDGE_SENSITIVITY 1 //[0 1 2]

// #define HANDLIGHT
