#if !defined COMPUTESSREFLECTIONS_FSH
#define COMPUTESSREFLECTIONS_FSH

int GetMaxSteps(vec3 pos, vec3 ray, float maxRayDepth, float rayGrowth) { // Returns the number of steps until the ray goes offscreen, or past maxRayDepth
	vec4 c =  vec4(diagonal2(projMatrix) * pos.xy + projMatrix[3].xy, diagonal2(projMatrix) * ray.xy);
	     c = -vec4((c.xy - pos.z) / (c.zw - ray.z), (c.xy + pos.z) / (c.zw + ray.z)); // Solve for (M*(pos + ray*c) + A) / (pos.z + ray.z*c) = +-1.0
	
	c = mix(c, vec4(1000000.0), lessThan(c, vec4(0.0))); // Remove negative coefficients from consideration by making them B I G
	
	float x = minVec4(c); // Nearest ray length to reach screen edge
	
	if (ray.z < 0.0) // If stepping away from player
		x = min(x, (maxRayDepth + pos.z) / -ray.z); // Clip against maxRayDepth
	
	x = (log2(1.0 - x*(1.0 - rayGrowth))) / log2(rayGrowth); // Solve geometric sequence with  a = 1.0  and  r = rayGrowth
	
	return min(75, int(x));
}

bool ComputeSSRaytrace(vec3 vPos, vec3 dir, out vec3 screenPos) {
	cfloat rayGrowth      = 1.15;
	cfloat rayGrowthL2    = log2(rayGrowth);
	cint   maxRefinements = 0;
	cbool  doRefinements  = maxRefinements != 0;
	float  maxRayDepth    = far * 1.75;
	int    maxSteps       = GetMaxSteps(vPos, dir, maxRayDepth, rayGrowth);
	
	vec3 rayStep = dir;
	vec3 ray = vPos + rayStep;
	
	float refinements = 0.0;
	
	vec2 zMAD = -vec2(projInverseMatrix[2][3] * 2.0, projInverseMatrix[3][3] - projInverseMatrix[2][3]);
	
	for (int i = 0; i < maxSteps; i++) {
		screenPos.st = ViewSpaceToScreenSpace(ray);
		
	//	if (any(greaterThan(abs(screenPos.st - 0.5), vec2(0.5))) || -ray.z > maxRayDepth) return false;
		
		screenPos.z = texture2D(depthtex1, screenPos.st).x;
		
		float depth = screenPos.z * zMAD.x + zMAD.y;
		
		if (ray.z * depth >= 1.0) { // if (1.0 / (depth * a + b) >= ray.z), quick way to compare ray with hyperbolic sample depth without doing a division
			float diff = (1.0 / depth) - ray.z;
			
			if (doRefinements) {
				float error = exp2(i * rayGrowthL2 + refinements); // length(rayStep) * exp2(refinements)
				
				if (refinements <= maxRefinements && diff <= error * 2.0) {
					rayStep *= 0.5;
					ray -= rayStep;
					refinements++;
					continue;
				} else if (refinements > maxRefinements && diff <= error * 4.0) {
					return true;
				}
			} else return (diff <= exp2(i * rayGrowthL2 + 1.0));
		}
		
		ray += rayStep;
		
		rayStep *= rayGrowth;
	}
	
	return false;
}

void ComputeSSReflections(io vec3 color, mat2x3 position, vec3 normal, float smoothness, float skyLightmap) {
	if (isEyeInWater == 1) return;
	
	float alpha = pow2(clamp01(1.0 + dotNorm(position[0], normal))) * smoothness;
	
	if (length(alpha) < 0.0005) return;
	
	
	mat2x3 refRay;
	refRay[0] = reflect(position[0], normal);
	refRay[1] = mat3(gbufferModelViewInverse) * refRay[0];
	
	vec3 refCoord;
	vec3 reflection;
	
	float sunlight = ComputeSunlight(position[1], GetLambertianShading(normal) * skyLightmap);
	
	float fogFactor = 1.0;
	
	bool hit = ComputeSSRaytrace(position[0], normalize(refRay[0]), refCoord);
	
	vec3 transmit = vec3(1.0);
	vec3 in_scatter = vec3(0.0);
	
	if (hit) {
		reflection = GetColor(refCoord.st);
		
		vec3 refVPos = CalculateViewSpacePosition(refCoord);
		
		fogFactor = length(abs(position[0] - refVPos) / 500.0);
		
		float angleCoeff = clamp01(pow(normal.z + 0.15, 0.25) * 2.0) * 0.2 + 0.8;
		float dist       = length8(abs(refCoord.st - vec2(0.5)));
		float edge       = clamp01(1.0 - pow2(dist * 2.0 * angleCoeff));
		fogFactor        = clamp01(fogFactor + pow(1.0 - edge, 10.0));
		
		in_scatter = SkyAtmosphereToPoint(position[1], mat3(gbufferModelViewInverse) * refVPos, transmit);
	} else {
		in_scatter = ComputeSky(normalize(refRay[1]), position[1], transmit, 1.0, true);
		transmit = vec3(1.0);
	}
	
	
	reflection = reflection * transmit + in_scatter;
	
	color = mix(color, reflection, alpha);
}


#endif
