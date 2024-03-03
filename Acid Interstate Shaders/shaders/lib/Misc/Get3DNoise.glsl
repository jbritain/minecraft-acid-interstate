float Get3DNoise(vec3 position) {
	vec3 whole = floor(position);
	vec3 part = cubesmooth(position - whole);
	
	cvec3 zscale = vec3(17.0, 0.5, 17.5);
	
	vec4 coord  = (whole.xyxy + part.xyxy) + (whole.z * zscale.x) + zscale.yyzz;
	     coord /= noiseTextureResolution;
	
	float Noise1 = texture2D(noisetex, coord.xy).x;
	float Noise2 = texture2D(noisetex, coord.zw).x;
	
	return mix(Noise1, Noise2, part.z);
}
