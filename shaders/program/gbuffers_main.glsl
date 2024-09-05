#include "/lib/Syntax.glsl"

#define gbuffers_main

varying vec3 color;
varying vec2 texcoord;
varying vec2 vertLightmap;
flat varying ivec2 textureResolution;

varying mat3 tbnMatrix;

varying mat2x3 position;
varying mat2x3 preAcidPosition;
varying mat2x3 prePortalPosition;

varying vec3 midblock;

varying vec3 worldDisplacement;

flat varying float materialIDs;

varying float blocklight;

#include "/lib/Uniform/Shading_Variables.glsl"

/***********************************************************************/
#if defined vsh

attribute vec4 mc_Entity;
attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;
attribute vec4 at_midBlock;

uniform float thunderStrength;

uniform sampler2D lightmap;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float far;
uniform int blockEntityId;

uniform float biomeWetness;
uniform float biomePrecipness;
uniform float biomeCanRainSmooth;

#include "/lib/iPBR/IDs.glsl"
#include "/lib/iPBR/Groups.glsl"
#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"

uniform sampler3D colortex4;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform float sunAngle;

#include "/lib/Uniform/Shadow_View_Matrix.vsh"
#include "/lib/Fragment/PrecomputedSky.glsl"
#include "/lib/Vertex/Shading_Setup.vsh"

#include "/lib/Acid/portals.glsl"

vec2 GetDefaultLightmap() {
    vec2 lightmapCoord = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;

    return clamp01(lightmapCoord / vec2(0.8745, 0.9373)).rg;
}

vec3 GetWorldSpacePosition() {
    vec3 position = transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);

    return mat3(gbufferModelViewInverse) * position;
}

vec4 ProjectViewSpace(vec3 viewSpacePosition) {
    #if !defined gbuffers_hand
    return vec4(projMAD(gbufferProjection, viewSpacePosition), viewSpacePosition.z * gbufferProjection[2].w);
    #else
    return vec4(projMAD(gl_ProjectionMatrix, viewSpacePosition), viewSpacePosition.z * gl_ProjectionMatrix[2].w);
    #endif
}

#include "/lib/Vertex/Waving.vsh"
#include "/lib/Vertex/Vertex_Displacements.vsh"

mat3 CalculateTBN(vec3 worldPosition) {
    vec3 tangent = normalize(at_tangent.xyz);
    vec3 binormal = normalize(-cross(gl_Normal, at_tangent.xyz));

    #if defined gbuffers_water || defined gbuffers_textured
    tangent += CalculateVertexDisplacements(worldPosition + tangent) - worldDisplacement;
    binormal += CalculateVertexDisplacements(worldPosition + binormal) - worldDisplacement;
    #endif

    tangent = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * tangent);
    binormal = mat3(gbufferModelViewInverse) * gl_NormalMatrix * binormal;

    vec3 normal = normalize(cross(-tangent, binormal));

    binormal = cross(tangent, normal); // Orthogonalize binormal

    return mat3(tangent, binormal, normal);
}

uniform ivec2 atlasSize;

void main() {
    materialIDs = mc_Entity.x;
    #ifdef gbuffers_terrain
    materialIDs = max(materialIDs, blockEntityId);
    #endif

    midblock = at_midBlock.xyz;

    color = gl_Color.rgb;
    texcoord = gl_MultiTexCoord0.st;
    vertLightmap = GetDefaultLightmap();

    #ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
    blocklight = at_midBlock.w;
    #else
    blocklight = vertLightmap.r;
    #endif

    vec3 worldSpacePosition = GetWorldSpacePosition();

    prePortalPosition[1] = worldSpacePosition;
    // prePortalPosition[0] = mat3(gbufferModelView) * prePortalPosition[1];

    worldSpacePosition += cameraPosition;
    doPortals(worldSpacePosition, at_midBlock.xyz);
    worldSpacePosition -= cameraPosition;
    
    preAcidPosition[1] = worldSpacePosition;

    worldDisplacement = CalculateVertexDisplacements(worldSpacePosition);

    position[1] = worldSpacePosition + worldDisplacement;
    position[0] = mat3(gbufferModelView) * position[1];

    gl_Position = ProjectViewSpace(position[0]);

    tbnMatrix = CalculateTBN(worldSpacePosition);

    SetupShading();

    // thanks to NinjaMike and Null
    vec2 halfSize = abs(texcoord - mc_midTexCoord.xy);
    vec4 textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);

    textureResolution = ivec2(((textureBounds.zw - textureBounds.xy) * atlasSize) + vec2(0.5));
}

#endif
/***********************************************************************/

/***********************************************************************/
#if defined fsh

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D portalshadowtex;
uniform sampler2D shadowcolor0;
uniform sampler2D bluenoisetex;

#if defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
uniform sampler2DShadow shadowtex0HW;
uniform sampler2DShadow shadowtex1HW;
#endif

uniform sampler2D colortex10;
uniform float alphaTestRef;

uniform sampler3D lightVoxelTex;
uniform sampler3D lightVoxelFlipTex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;

uniform vec3 cameraPosition;
uniform vec3 eyePosition;

uniform float nightVision;

#ifdef gbuffers_entities
uniform vec4 entityColor;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 atlasSize;

uniform float biomeWetness;
uniform float biomePrecipness;
uniform float near;
uniform float far;

#include "/lib/Settings.glsl"
#include "/lib/Debug.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Uniform/Projection_Matrices.fsh"
#include "/lib/Misc/CalculateFogfactor.glsl"
#include "/lib/Fragment/Masks.fsh"

uniform sampler3D colortex4;

#include "/lib/Uniform/Shadow_View_Matrix.fsh"
#include "/lib/Voxel/VoxelPosition.glsl"
#include "/lib/Fragment/ComputeShadedFragment.fsh"
#include "/lib/Fragment/ComputeWaveNormals.fsh"

float LOD;

#ifdef TERRAIN_PARALLAX
#define GetTexture(x, y) texture2DLod(x, y, LOD)
#else
#define GetTexture(x, y) texture(x, y)
#endif

#ifdef gbuffers_water
#define GetTexture(x, y) texture(x, y)
#endif

vec4 GetDiffuse(vec2 coord, float materialIDs) {
    vec3 color = color;
    vec3 waterColor = normalize(vec3(63.0/255.0, 118.0/255.0, 228.0/255.0));

    vec4 diffuse;
    if (materialIDs == 1) { // water
        diffuse = GetTexture(gtexture, coord) * vec4(color, 1.0);
        float lum = diffuse.r + diffuse.g + diffuse.b;
        lum /= 3.0;
        lum = pow(lum, 1.0) * 1.0;
        lum += 0.0;

        diffuse = vec4(0.1, 0.7, 1.0, 210.0/255.0);
        diffuse.rgb *= 0.8 * waterColor.rgb;
        diffuse.rgb *= vec3(lum);
        return diffuse;
    }

    if(materialIDs == 3){ // grass
        vec3 color2 = hsv(color);
        if(color2.g > 0.0){
            color2.r = 104/360.0;
            color2.g = 0.55;
            color2.b = 0.85;
        }
        color = rgb(color2);
    }

    if(materialIDs == 2001){ // leaves
        color = vec3(51.0/255.0, 153.0/255.0, 51.0/255.0);

    }

    diffuse = vec4(color.rgb, 1.0) * GetTexture(gtexture, coord);

    #ifdef gbuffers_entities
    diffuse.rgb = mix(diffuse.rgb, entityColor.rgb, entityColor.a);
    #endif

    #ifdef SMOOTH_ICE
    if(materialIDs == 2) { // ice
        diffuse.rgb = WATER_COLOR.rgb;
    }
    #endif

    return diffuse;
}

vec4 GetDiffuse(vec2 coord) {
    return GetDiffuse(coord, -1);
}

bool handLight = false;

// adapted from NinjaMike's method
// https://discord.com/channels/237199950235041794/525510804494221312/1004459522095579186
vec2 getdirectionalLightingFactor(vec3 faceNormal, vec3 mappedNormal, vec3 worldPos, vec2 lightmap) {
    vec3 dFdworldPosX = dFdx(worldPos);
    vec3 dFdworldPosY = dFdy(worldPos);

    float torch = 1.0;
    vec2 dFdTorch = vec2(dFdx(lightmap.r), dFdy(lightmap.r));

    vec3 torchDir = dFdworldPosX * dFdTorch.x + dFdworldPosY * dFdTorch.y;
    if (length(dFdTorch) > 1e-6) {
        torch = clamp01(dot(normalize(torchDir), mappedNormal) + 0.8) * 0.8 + 0.2;
    } else {
        torch = clamp01(dot(mappedNormal, faceNormal)) * 0.8 + 0.2;
    }

    float sky = 1.0;
    // vec2 dFdSky = vec2(dFdx(lightmap.g), dFdy(lightmap.g));

    // vec3 skyDir = dFdViewposX * dFdSky.x + dFdViewposY * dFdSky.y;
    // if(length2(dFdSky) > 1e-12) sky = clamp(dot(normalize(skyDir), viewNormal) + 0.8, 0.0, 1.0) * 0.8 + 0.2;

    return (vec2(torch, sky));
}

#include "/lib/iPBR/iPBR.glsl"
#include "/lib/Fragment/EndPortal.fsh"
#include "/lib/Acid/portals.glsl"

#if defined gbuffers_water
/* RENDERTARGETS: 0,3,8,13 */
#elif defined gbuffers_textured || defined gbuffers_hand
/* RENDERTARGETS: 0,3,8,13 */
#else
/* RENDERTARGETS: 1,4,9,10,11 */
#endif

#include "/lib/Exit.glsl"

void main() {
    doPortals(prePortalPosition[1] + cameraPosition, midblock);
    bool rightOfPortal = prePortalPosition[1].z + cameraPosition.z + midblock.z / 64 > 0;

    vec2 vertLightmap = vertLightmap;
    vec2 coord = texcoord;

    PBRData PBR;
    PBR = getRawPBRData(coord);
    injectIPBR(PBR, materialIDs);

    #ifdef gbuffers_hand
    if (heldBlockLightValue + heldBlockLightValue2 > 0) {
        handLight = true;
    }
    #endif

    #ifndef VL_ENABLED
    if (CalculateFogFactor(position[0]) >= 1.0)
    {
        discard;
    }
    #endif

    
    vec4 diffuse = GetDiffuse(coord, materialIDs);

    #ifdef gbuffers_weather
    #ifndef RAIN
    discard;
    #endif

    float rainNoise = InterleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter);
    diffuse = vec4(0.9, 0.9, 1.0, step(0.5, rainNoise) * 0.5 * diffuse.a);

    #endif

    if (diffuse.a < alphaTestRef) {
        discard;
    }

    vec3 faceNormal = tbnMatrix * vec3(0.0, 0.0, 1.0);
    vec3 normal = tbnMatrix * PBR.normal;
    #ifdef DIRECTIONAL_LIGHTING
    vec2 directionalLightingFactor = getdirectionalLightingFactor(faceNormal, normal, position[1], vertLightmap.rg);
    #else
    vec2 directionalLightingFactor = vec2(1.0);
    #endif

    #ifdef gbuffers_hand
    directionalLightingFactor = vec2(1.0);
    #endif

    #ifdef gbuffers_spidereyes
    PBR.emission = 1.0;
    #endif

    #ifdef gbuffers_textured
    PBR.perceptualSmoothness = 0.0;
    PBR.baseReflectance = 0.0;
    directionalLightingFactor = vec2(1.0);
    #endif

    vertLightmap.r *= directionalLightingFactor.r;
    vertLightmap.g *= directionalLightingFactor.g;

    #ifdef gbuffers_terrain
    if (materialIDs == IPBR_END_PORTAL) {
        vec3 wDir = normalize(position[1]);
        wDir.y = abs(wDir.y);
        diffuse.rgb = CalculateEndPortal(wDir);
        PBR.emission = 1.0;
        PBR.baseReflectance = 0.0;
        PBR.perceptualSmoothness = 0.0;
    }



    gl_FragData[5] = vec4(1.0);
    #endif

    #if defined gbuffers_water || defined gbuffers_textured || defined gbuffers_hand
    Mask mask = EmptyMask;

    #ifdef gbuffers_water

    if (materialIDs == IPBR_WATER) {
        normal = tbnMatrix * ComputeWaveNormals(position[1], tbnMatrix[2]);
        mask.water = 1.0;
    }
    #endif

    vec3 sunlight = vec3(ComputeSunlight(preAcidPosition[1], mat3(gbufferModelView) * normal, tbnMatrix[2], 1.0, PBR.SSS, vertLightmap.g, rightOfPortal));
    vec3 composite = ComputeShadedFragment(powf(diffuse.rgb, 2.2), mask, vertLightmap.r, vertLightmap.g, vec4(0.0, 0.0, 0.0, 1.0), mat3(gbufferModelView) * normal, PBR.emission, position, PBR.materialAO, PBR.SSS, tbnMatrix[2], sunlight);

    gl_FragData[3] = vec4(sunlight, 1.0);

    vec2 encode;
    encode.x = Encode4x8F(vec4(0.0, vertLightmap.g, mask.water, 0.1));
    encode.y = EncodeNormal(normal, 11.0);

    gl_FragData[0] = vec4(encode, 0.0, 1.0);
    gl_FragData[1] = vec4(composite, diffuse.a);
    gl_FragData[2] = vec4(PBR.perceptualSmoothness, PBR.baseReflectance, 0.0, 1.0);
    vec3 blockLightColor = vec3(0.0);

    if (IPBR_EMITS_LIGHT(materialIDs)) {
        blockLightColor = texture(gtexture, texcoord).rgb * clamp01(PBR.emission);
    }

    #ifndef gbuffers_textured
    if (PBR.emission == 0.0) {
        gl_FragData[4] = vec4(0);
    } else {
        gl_FragData[4] = vec4(blockLightColor, 1.0);
    }
    #endif
    #else

    diffuse.rgb = mix(diffuse.rgb, diffuse.rgb * (((1.0 - PBR.porosity) / 2) + 0.5), biomeWetness * vertLightmap.y);

    float encodedMaterialIDs = EncodeMaterialIDs(0.0, vec4(0.0, 0.0, 0.0, 0.0));

    if (any(isnan(diffuse))) {
        discard;
    }

    gl_FragData[0] = vec4(diffuse.rgb, 1.0);
    gl_FragData[1] = vec4(
            Encode4x8F(vec4(
                    encodedMaterialIDs,
                    0.0,
                    vertLightmap.rg
                )),

            EncodeNormal(normal, 11.0),

            Encode4x8F(vec4(
                    PBR.materialAO,
                    PBR.SSS,
                    0.0,
                    0.0
                )),

            #if defined gbuffers_terrain
            EncodeNormal(tbnMatrix[2], 16.0)
            #else
            1.0
        #endif
        );
    gl_FragData[2] = vec4(PBR.perceptualSmoothness, PBR.baseReflectance, PBR.emission, 1.0);

    vec3 blockLightColor = vec3(0.0);
    if (IPBR_EMITS_LIGHT(materialIDs) || handLight) {
        blockLightColor = texture(gtexture, texcoord).rgb * clamp01(PBR.emission);
    }

    if (materialIDs == IPBR_TORCH) {
        blockLightColor = vec3(0.5, 0.2, 0.05) * 4.0 * PBR.emission;
    }

    gl_FragData[4] = vec4(preAcidPosition[1], float(rightOfPortal));
    #endif

    exit();
}

#endif
/***********************************************************************/
