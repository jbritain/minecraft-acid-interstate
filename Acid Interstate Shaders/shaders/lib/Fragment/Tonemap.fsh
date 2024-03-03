#if !defined TONEMAP_GLSL
#define TONEMAP_GLSL

#define Tonemap(x) ACESFitted(x)

const mat3 ACESInputMat = mat3(
	0.59719, 0.35458, 0.04823,
	0.07600, 0.90834, 0.01566,
	0.02840, 0.13383, 0.83777
);

// ODT_SAT => XYZ => D60_2_D65 => sRGB
const mat3 ACESOutputMat = mat3(
	1.60475, -0.53108, -0.07367,
	-0.10208,  1.10813, -0.00605,
	-0.00327, -0.07276,  1.07602
);

vec3 RRTAndODTFit(vec3 v) {
	vec3 a = v * (v + 0.0245786f) - 0.000090537f;
	vec3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
	return a / b;
}

vec3 ACESFitted(vec3 color) {
	color *= EXPOSURE;
	
	const vec3 W = vec3(0.2125, 0.7154, 0.0721);
	color = mix(vec3(dot(color, W)), color, SATURATION);
	
	color = color * ACESInputMat;
	
	
	// Apply RRT and ODT
	color = RRTAndODTFit(color);
	
	color = color * ACESOutputMat;
	
	color = pow(color, vec3(1.0 / 2.2));
	
	return color;
}

#endif
