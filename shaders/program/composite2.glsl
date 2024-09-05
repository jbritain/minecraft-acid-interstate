#include "/lib/Syntax.glsl"

varying vec2 texcoord;

#include "/lib/Uniform/Shading_Variables.glsl"

/***********************************************************************/
#if defined vsh

uniform sampler3D colortex7;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float sunAngle;
uniform float far;

uniform float biomeWetness;
uniform float biomePrecipness;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"

#include "/lib/Uniform/Shadow_View_Matrix.vsh"
#include "/lib/Fragment/PrecomputedSky.glsl"
#include "/lib/Vertex/Shading_Setup.vsh"

void main() {
    texcoord = gl_MultiTexCoord0.st;
    gl_Position = ftransform();

    
    SetupShading();
}

#endif
/***********************************************************************/

/***********************************************************************/
#if defined fsh

uniform sampler3D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;

uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex10;
uniform sampler2D colortex13;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform sampler2D noisetex;
uniform sampler2D bluenoisetex;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;

uniform sampler2D shadowcolor0;

uniform vec3 shadowLightPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;

uniform vec3 cameraPosition;

uniform vec2 pixelSize;
uniform float viewWidth;
uniform float viewHeight;

uniform float humiditySmooth;
uniform float biomeCanRainSmooth;
uniform float biomeWetness;
uniform float biomePrecipness;

uniform float near;
uniform float far;

uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;

uniform vec3 fogColor;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Uniform/Projection_Matrices.fsh"
#include "/lib/Uniform/Shadow_View_Matrix.fsh"
#include "/lib/Fragment/Masks.fsh"
#include "/lib/Misc/CalculateFogfactor.glsl"

#ifdef CLOUD3D
const bool colortex5MipmapEnabled = true;
#endif

vec3 GetColor(vec2 coord) {
    return texture(colortex1, coord).rgb;
}

float GetDepth(vec2 coord) {
    return texture(depthtex0, coord).x;
}

float GetTransparentDepth(vec2 coord) {
    return texture(depthtex2, coord).x;
}

vec3 CalculateViewSpacePosition(vec3 screenPos) {
    screenPos = screenPos * 2.0 - 1.0;

    return projMAD(gbufferProjectionInverse, screenPos) / (screenPos.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}

vec2 ViewSpaceToScreenSpace(vec3 viewSpacePosition) {
    return (diagonal2(gbufferProjection) * viewSpacePosition.xy + gbufferProjection[3].xy) / -viewSpacePosition.z * 0.5 + 0.5;
}

float backDepth;
float frontDepth;
float skyLightmap;
vec2 VL;

#include "/lib/Fragment/WaterDepthFog.fsh"
#include "/lib/Fragment/Sky.fsh"
#include "/lib/Fragment/ComputeSpecularLighting.fsh"
#include "/lib/Fragment/ComputeWaveNormals.fsh"

/* DRAWBUFFERS:32 */
#include "/lib/Exit.glsl"

void main() {
    vec2 texture4 = ScreenTex(colortex4).rg;

    vec4 decode4 = Decode4x8F(texture4.r);
    Mask mask = CalculateMasks(decode4.r);
    float specularity = decode4.g;
    float baseReflectance = ScreenTex(colortex9).g;
    float perceptualSmoothness = ScreenTex(colortex9).r;
    skyLightmap = decode4.a;
    vec4 transparentColor = texture(colortex3, texcoord);
    mask.transparent = clamp01(step(0.01, transparentColor.a) + mask.water);
    mask.transparent *= (1.0 - mask.hand);
    VL = ScreenTex(colortex6).xy;
    vec3 sunlight = ScreenTex(colortex10).rgb;
    gl_FragData[1] = vec4(decode4.r, 0.0, 0.0, 1.0);

    backDepth = GetDepth(texcoord);

    if (backDepth < 0.56) {
        mask.hand = 1.0;
        backDepth = 0.55;
    }

    frontDepth = GetTransparentDepth(texcoord);

    vec3 wNormal = DecodeNormal(texture4.g, 11);
    vec3 normal = mat3(gbufferModelView) * wNormal;

    mat2x3 frontPos;
    frontPos[0] = CalculateViewSpacePosition(vec3(texcoord, backDepth));
    frontPos[1] = mat3(gbufferModelViewInverse) * frontPos[0];

    mat2x3 backPos = frontPos;
    if (mask.transparent == 1.0) {
        backPos[0] = CalculateViewSpacePosition(vec3(texcoord, frontDepth));
        backPos[1] = mat3(gbufferModelViewInverse) * backPos[0];
        baseReflectance = ScreenTex(colortex8).g;
        perceptualSmoothness = ScreenTex(colortex8).r;
        sunlight = ScreenTex(colortex13).rgb;
    }

    vec3 color = texture(colortex1, texcoord).rgb;

    #ifdef WATER_REFRACTION
    if (mask.water > 0.5) {
        vec3 refracted = normalize(refract(frontPos[0], normal, isEyeInWater == 1.0 ? 1.33 : (1.0 / 1.33)));

        vec3 refractedPos;
        bool refractHit = ComputeSSRaytrace(frontPos[0], refracted, refractedPos);

        if (refractHit) {
            frontDepth = refractedPos.z;
            backPos[0] = CalculateViewSpacePosition(refractedPos);
            backPos[1] = mat3(gbufferModelViewInverse) * backPos[0];
            color = texture(colortex1, refractedPos.xy).rgb;
        } else if (isEyeInWater == 1.0 && EBS == 1.0) {
            color = normalize(waterColor);
            frontDepth = 1.0;
            backPos[0] = CalculateViewSpacePosition(vec3(texcoord, frontDepth));
            backPos[1] = mat3(gbufferModelViewInverse) * backPos[0];
        }
    }
    #endif

    vec2 refractedTexCoord = texcoord;
    // render sky
    if (frontDepth == 1.0) {
        vec3 transmit = vec3(1.0);

        vec3 incident = normalize(frontPos[1]);
        vec3 refracted = incident;


        if (mask.water > 0.5) {
            #ifdef WATER_REFRACTION
            refracted = refract(incident, normalize(mat3(gbufferModelViewInverse) * normal), isEyeInWater == 1.0 ? 1.33 : 1.0 / 1.33);
            refractedTexCoord = ViewSpaceToScreenSpace(mat3(gbufferModelView) * refracted).xy;
            #endif
        }

        color = ComputeSky(refracted, vec3(0.0), transmit, 1.0, false, 1.0);
    }

    if (transparentColor.a == 0) { // check if there is something transparent in front of the reflective surface
        ComputeSpecularLighting(color, frontPos, normal, baseReflectance, perceptualSmoothness, skyLightmap, sunlight);
    }

    #ifdef WORLD_OVERWORLD

    // apply atmospheric fog to solid things
    if (((mask.water == 0.0 && isEyeInWater == 0.0) || (mask.water == 1.0 && isEyeInWater == 1.0)) && frontDepth != 1.0) { // surface not behind water so apply atmospheric fog
        vec3 fogTransmit = vec3(1.0);
        vec3 fog = SkyAtmosphereToPoint(vec3(0.0), backPos[1], fogTransmit, VL);
        color = mix(fog, color, fogTransmit);
    }
    #else
    color = mix(color, fogColor, vec3(CalculateFogFactor(backPos[1])));
    #endif

    #if defined WORLD_OVERWORLD && defined CLOUD3D
        vec4 cloud = textureLod(colortex5, refractedTexCoord, VolCloudLOD);
        cloud.rgb = pow2(cloud.rgb) * 50.0;
        if (isEyeInWater == 1.0) {
            cloud.a = clamp01(mix(cloud.a, 0.0, pow4(length(abs(refractedTexCoord - 0.5) * 2))));
        }
        color = mix(color, cloud.rgb, cloud.a);
    #endif


    // blend in transparent stuff
    color = mix(color, transparentColor.rgb, transparentColor.a);

    if (transparentColor.a != 0) {
        ComputeSpecularLighting(color, frontPos, normal, baseReflectance, perceptualSmoothness, skyLightmap, sunlight);
    }

    if (isEyeInWater == 1.0) { // stuff inside the water when the player is in the water
        color = waterdepthFog(frontPos[0], backPos[0], color);
    }

    #ifdef WORLD_OVERWORLD
    if (mask.transparent == 1.0 && isEyeInWater == 0.0) {
        vec3 fogTransmit = vec3(1.0);
        vec3 fog = SkyAtmosphereToPoint(vec3(0.0), frontPos[1], fogTransmit, VL);
        color = mix(fog, color, fogTransmit);
    }
    #else
    if (mask.transparent == 1.0) color = mix(color, fogColor, vec3(CalculateFogFactor(frontPos[1])));
    #endif

    if (isEyeInWater > 1.0) {
        color = mix(color, fogColor, vec3(CalculateFogFactor(frontPos[1] * 64)));
    }

    gl_FragData[0] = vec4(clamp01(EncodeColor(color)), 1.0);
    exit();
}

#endif
/***********************************************************************/
