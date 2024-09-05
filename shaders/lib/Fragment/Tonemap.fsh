#if !defined TONEMAP_GLSL
#define TONEMAP_GLSL

void Tonemap(inout vec3 color) {
	vec3 averageLuminance = vec3(EXPOSURE);
	
	vec3 value = color.rgb / (color.rgb + averageLuminance);
	
	color.rgb = value;
	color.rgb = min(color.rgb, vec3(1.0));
	color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
}
#endif
