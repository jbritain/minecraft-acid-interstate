#if (defined TELEFOCAL_SHADOWS) && (defined SHADOWS_FOCUS_CENTER)
uniform float centerDepthSmooth;
#else
#define centerDepthSmooth 0.9992
#endif
