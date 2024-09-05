#ifndef IPBR
#define IPBR

#include "/lib/iPBR/IDs.glsl"
#include "/lib/iPBR/Groups.glsl"

struct PBRData {
  vec4 albedo;
  vec3 hsv;
  float perceptualSmoothness;
  float baseReflectance;
  float porosity;
  float SSS;
  float emission;

  float materialAO;
  float height;
  vec3 normal;
};

void applyiPBR(inout float val, float newVal){
  if(val == 0.0){
    val = newVal;
  }
}

float generateEmission(PBRData data, float lumaThreshold, float satThreshold){

  #ifndef HARDCODED_EMISSION
  return 0.0;
  #endif

  float luma = data.hsv.b;
	float sat = data.hsv.g;

  if(luma < lumaThreshold){
    return smoothstep(satThreshold, 1.0, sat);
  }

  return luma;
}

#ifdef gbuffers_main
  PBRData getRawPBRData(vec2 coord){
    PBRData data = PBRData(vec4(0.0), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, vec3(0.0));

    data.albedo = GetDiffuse(coord);
    data.hsv = hsv(data.albedo.rgb);

    #ifdef SPECULAR_MAPS
    vec4 specularData = texture(specular, coord);

    

    data.perceptualSmoothness = specularData.r;
    data.baseReflectance = specularData.g;

    float porositySSS = specularData.b;
    data.porosity = porositySSS <= 0.25 ? porositySSS * 4.0 : 0.0;
    data.SSS = porositySSS > 0.25 ? (porositySSS - 0.25) * (4.0/3.0) : 0.0;

    if(data.porosity == 0){
      data.porosity = (1.0 - data.perceptualSmoothness) * data.baseReflectance;
    }

    data.emission = specularData.a != 1.0 ? specularData.a : 0.0;
    #endif

    #ifdef NORMAL_MAPS
    vec4 normalData = texture(normals, coord);
    data.materialAO = normalData.b;
    data.height = normalData.a * 0.75 + 0.25;
    data.normal.xy = normalData.xy * 2.0 - 1.0;
    data.normal.z = sqrt(1.0 - dot(data.normal.xy, data.normal.xy));
    data.normal = normalize(data.normal);
    #else
    data.normal = vec3(0.0, 0.0, 1.0);
    #endif

    return data;
  }

  void injectIPBR(inout PBRData data, float ID){
    PBRData oldData = data;

    bool hasRPPorosity = !(data.SSS == 0.0 && data.porosity == 0.0);

    // =================================================================================

    switch(int(ID + 0.5)){
      case IPBR_NETHER_PORTAL:
        applyiPBR(data.perceptualSmoothness, 1.0);
        applyiPBR(data.baseReflectance, 0.02);
        applyiPBR(data.emission, 0.7);
        break;

      case IPBR_LAVA:
        applyiPBR(data.emission, 1.0);
        break;


      case IPBR_SEA_LANTERN:
        applyiPBR(data.emission, pow2(1.0 - data.hsv.g) * 0.7);
        break;

      case IPBR_COPPER_BULB_LIT:
        applyiPBR(data.emission, data.hsv.b * max(0.01, step(0.9, data.hsv.b)));
        //applyiPBR(data.baseReflectance, data.emission > 0.1 ? 0.0 : data.baseReflectance);
        break;

      case IPBR_CANDLES:
        applyiPBR(data.emission, 0.01);
        break;

      case IPBR_SCULK:
        applyiPBR(data.emission, data.hsv.b * max(0.01, step(0.2, data.hsv.b)));
        break;

      case IPBR_BIOLUMINESCENT:
        applyiPBR(data.emission, pow2(clamp01(data.hsv.b - 0.3)) * rcp(0.7));
        break;

      case IPBR_JACK_O_LANTERN:
        applyiPBR(data.emission, data.hsv.b * max(0.01, step(0.9, data.hsv.b)));
        break;

      case IPBR_REDSTONE_WIRE:
        applyiPBR(data.emission, max((data.hsv.b - 0.4) * rcp(0.6), 0.001));
        break;

      case IPBR_REDSTONE_COMPONENT:
        applyiPBR(data.emission, max((data.hsv.b - 0.4) * rcp(0.6) * step(0.8, data.hsv.g), 0.001));
        break;

      case IPBR_NO_LIGHT_REDSTONE:
        applyiPBR(data.emission, max((data.hsv.b - 0.4) * rcp(0.6) * step(0.8, data.hsv.g), 0.001));
        break;
    }

    // if(IPBR_IS_RAIL(ID)){
    //   applyiPBR(data.baseReflectance, data.hsv.g < 0.2 ? 230.0/255.0 : 0.0);
    //   applyiPBR(data.perceptualSmoothness, data.hsv.g < 0.2 ? 0.9 : 0.0);

    //   if((data.hsv.r > 357.0/360.0 || data.hsv.r < 5.0/255.0) && data.hsv.b > 0.5 && data.hsv.g > 0.5){
    //     applyiPBR(data.emission, 0.4);
    //   }
    // }

    if(IPBR_IS_FOLIAGE(ID)){
      applyiPBR(data.SSS, 1.0);
      applyiPBR(data.baseReflectance, 0.03);
      applyiPBR(data.perceptualSmoothness, 0.25 * smoothstep(0.16, 0.5, data.hsv.b));
    }   

    if(IPBR_IS_FROGLIGHT(ID)){
      applyiPBR(data.emission, pow2(1.0 - data.hsv.g) * 0.5);
    }

    // =================================================================================

    // not a great way of doing this but otherwise I'd have to reorganise and make things overall more complicated
    #ifndef HARDCODED_SPECULAR
      data.perceptualSmoothness = oldData.perceptualSmoothness;
      data.baseReflectance = oldData.baseReflectance;
    #endif

    #ifndef HARDCODED_SSS
      data.SSS = oldData.SSS;
    #endif

    if(int(ID + 0.5) == IPBR_WATER){
        data.perceptualSmoothness = 1.0;
        data.baseReflectance = 0.02;
    }

    if(!hasRPPorosity) data.porosity = 0.2;

    if (data.porosity > 0 && int(ID + 0.5) != IPBR_WATER){
			data.baseReflectance = mix(data.baseReflectance, 0.02, (1.0 - data.porosity) * biomeWetness * vertLightmap.g);
			data.perceptualSmoothness = mix(data.perceptualSmoothness, (1.0 - data.porosity), biomeWetness * vertLightmap.g);
		}

    if(IPBR_EMITS_LIGHT(ID))   applyiPBR(data.emission, generateEmission(data, 0.8, 0.6));

  }
#endif

#endif