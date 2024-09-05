#include "/lib/iPBR/IDs.glsl"

// Colour values from Complementary by Emin
// https://github.com/ComplementaryDevelopment/ComplementaryReimagined/blob/3d69187a3569e08722e3aa85bb3131ac4ea04cca/shaders/lib/colors/blocklightColors.glsl

const vec3 fireColor = vec3(2.0, 0.87, 0.27) * 3.8;
const vec3 redstoneColor = vec3(4.0, 0.1, 0.1);
const vec3 soulFireColor = vec3(0.3, 2.0, 2.2);

vec3 getLightColor(int ID){
  switch(ID){
    case IPBR_TORCH:
      return fireColor;
    case IPBR_REDSTONE_WIRE:
      return redstoneColor;
    case IPBR_REDSTONE_COMPONENT:
      return redstoneColor;
    case IPBR_REDSTONE_TORCH:
      return redstoneColor;
    case IPBR_SOUL_TORCH:
      return soulFireColor;
    case IPBR_JACK_O_LANTERN:
      return fireColor;
    case IPBR_BIOLUMINESCENT:
      return vec3(0.7, 1.5, 1.5) * 1.7;
    case IPBR_AMETHYST_BUD:
      return vec3(0.325, 0.15, 0.425) * 2.0;
    case IPBR_SCULK:
      return vec3(0.1, 0.3, 0.4) * 0.5;
    case IPBR_RESPAWN_ANCHOR:
      return vec3(1.7, 0.9, 0.4) * 2.0;
    case IPBR_ARTFICIAL_LIGHT:
      return vec3(1.7, 0.9, 0.4) * 4.0;
    case IPBR_LAVA:
      return vec3(3.0, 0.9, 0.2) * 4.0;
    case IPBR_NETHER_PORTAL:
      return vec3(1.8, 0.4, 2.9) * 0.8;
    case IPBR_FURNACE:
      return fireColor;
    case IPBR_FIRE:
      return fireColor;
    case IPBR_BEACON:
      return vec3(1.0, 1.5, 2.0) * 3.0;
    case IPBR_HANGING_LANTERN:
      return fireColor;
    case IPBR_GLOW_BERRIES:
      return vec3(2.3, 0.9, 0.2) * 3.4;
    case IPBR_CANDLES:
      return fireColor;
    case IPBR_END_ROD:
      return vec3(1.0, 1.0, 1.0) * 4.0;
    case IPBR_SOUL_FIRE:
      return soulFireColor;
    case IPBR_SEA_LANTERN:
      return vec3(1.0, 1.25, 1.5) * 3.4;
    case IPBR_CRYING_OBSIDIAN:
      return vec3(1.8, 0.4, 2.9) * 0.8;
    case IPBR_OCHRE_FROGLIGHT:
      return vec3(1.1, 0.85, 0.35) * 5.0;
    case IPBR_VERDANT_FROGLIGHT:
      return vec3(0.6, 1.3, 0.6) * 4.5;
    case IPBR_PEARLESCENT_FROGLIGHT:
      return vec3(1.1, 0.5, 0.9) * 4.5;
    case IPBR_COPPER_BULB_LIT:
      return vec3(1.7, 0.9, 0.4) * 4.0;
    case IPBR_END_PORTAL_FRAME:
      return vec3(0.0, 1.4, 1.4) * 1.5;
    case IPBR_ENCHANTING_TABLE:
      return vec3(1.4, 1.1, 0.5);
    default:
      return torchColor;
    
  }
}