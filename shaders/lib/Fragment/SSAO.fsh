#if !defined SSAO_FSH
#define SSAO_FSH

vec2 Hammersley(int i, int N) {
	return vec2(float(i) / float(N), float(bitfieldReverse(i)) * 2.3283064365386963e-10);
}

vec2 Circlemap(vec2 p) {
	p.y *= TAU;
	return vec2(cos(p.y), sin(p.y)) * p.x;
}

#define AO_SAMPLE_COUNT 6   // [3 4 6 8 12 16]
#define AO_RADIUS       1.3 // [0.5 0.6 0.7 0.8 0.9 1.1 1.2 1.3 1.4 1.5]
#define AO_INTENSITY    1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]

float ComputeSSAO(vec3 vPos, vec3 normal) {
#ifndef AO_ENABLED
	return 1.0;
#endif
	
	cint steps = AO_SAMPLE_COUNT;
	cfloat r = AO_RADIUS;
	cfloat rInv = 1.0 / r;
	
	vec2 p  = gl_FragCoord.xy / COMPOSITE0_SCALE + 1.0 / vec2(viewWidth, viewHeight);
	     p /= vec2(viewWidth, viewHeight);
	
	int x = int(gl_FragCoord.x) % 4;
	int y = int(gl_FragCoord.y) % 4;
	int index = (x << 2) + y + 1;
	
	vPos = CalculateViewSpacePosition(vec3(p, textureRaw(depthtex1, p).x));
	
	vec2 clipRadius = r * vec2(viewHeight / viewWidth, 1.0) / length(vPos);
	
	float nvisibility = 0.0;
	
	for (int i = 0; i < steps; i++) {
		vec2 circlePoint = Circlemap(Hammersley(i * 15 + index, 16 * steps)) * clipRadius;
		
		vec2 p1 = p + circlePoint;
		vec2 p2 = p + circlePoint * 0.25;
		
		vec3 o  = CalculateViewSpacePosition(vec3(p1, textureRaw(depthtex1, p1).x)) - vPos;
		vec3 o2 = CalculateViewSpacePosition(vec3(p2, textureRaw(depthtex1, p2).x)) - vPos;
		
		vec2 len = vec2(length(o), length(o2));
		
		vec2 ratio = clamp01(len * rInv - 1.0); // (len - r) / r
		
		nvisibility += clamp01(1.0 - max(dot(o, normal) / len.x - ratio.x, dot(o2, normal) / len.y - ratio.y));
	}
	
	nvisibility /= float(steps);
	
	return clamp01(mix(1.0, nvisibility, AO_INTENSITY));
}

#endif
