vec3 CalculateEndPortal(vec3 wDir) {
	vec2 coord;
	coord = wDir.xz * (2.5 * (2.0 - wDir.y) * noiseScale);
	
	float noise  = texture(noisetex, coord * 0.5).r;
	      noise += texture(noisetex, coord).r * 0.5;

  float star = clamp01(noise - 1.3 / 1.1) * 10.0 * pow2(clamp01(abs(wDir.y)));

  return star * vec3(0.8, 0.7, 1.0);
}