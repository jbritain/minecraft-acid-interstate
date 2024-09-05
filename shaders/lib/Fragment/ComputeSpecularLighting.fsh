#if !defined COMPUTESSREFLECTIONS_FSH
#define COMPUTESSREFLECTIONS_FSH

#include "/lib/Fragment/Specular.fsh"

int GetMaxSteps(vec3 pos, vec3 ray, float maxRayDepth, float rayGrowth) { // Returns the number of steps until the ray goes offscreen, or past maxRayDepth
	vec4 c =  vec4(diagonal2(gbufferProjection) * pos.xy + gbufferProjection[3].xy, diagonal2(gbufferProjection) * ray.xy);
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
	
	vec2 zMAD = -vec2(gbufferProjectionInverse[2][3] * 2.0, gbufferProjectionInverse[3][3] - gbufferProjectionInverse[2][3]);
	
	for (int i = 0; i < maxSteps; i++) {
		screenPos.st = ViewSpaceToScreenSpace(ray);
		
	//	if (any(greaterThan(abs(screenPos.st - 0.5), vec2(0.5))) || -ray.z > maxRayDepth) return false;
		
		screenPos.z = texture(depthtex1, screenPos.st).x;
		if(screenPos.z < 0.56){
			return false;
		}

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

mat3 CalculateTBN(vec3 normal){
	vec3 tangent, bitangent;
	ComputeFrisvadTangent(normal, tangent, bitangent);
	return mat3(tangent, bitangent, normal);
}

void ComputeSpecularLighting(io vec3 color, mat2x3 position, vec3 normal, float baseReflectance, float perceptualSmoothness, float skyLightmap, vec3 sunlight) {
	if (baseReflectance == 0) return;

	float roughness = pow(1.0 - perceptualSmoothness, 2.0);

	float nDotV;

	vec3 v = normalize(-position[0]);
	vec3 n = normal;
	if (roughness > 0){
		vec3 roughN = normalize(v + n);
		nDotV = clamp01(dot(roughN, v));
	} else {
		nDotV = dot(n, v);
	}

	float specularHighlight = CalculateGGX(n, v, lightVector, max(roughness, 0.0001));
	

	vec3 fresnel;

	if (baseReflectance < (229.5 / 255.0)) {
		fresnel = vec3(CalculateSchlick(baseReflectance, nDotV));
		fresnel = mix(vec3(baseReflectance), vec3(1.0), fresnel);

	} else {
		
		vec3 f0 = GetMetalf0(baseReflectance, color); // lazanyi 2019 schlick
		vec3 f82 = GetMetalf82(baseReflectance, color);
		fresnel = CalculateLazanyiSchlick(f0, f82, nDotV);
	}

	if(length(fresnel) < 0.01){
		return;
	}


	mat2x3 refRay;
	
	vec3 refCoord;

	int samples = REFLECTION_SAMPLES;
	samples = max(1, samples);
	
	
	float fogFactor = 1.0;
	
	vec3 reflectionSum = vec3(0);
	vec3 offsetNormal = normal;

	refRay[0] = reflect(position[0], offsetNormal);
	refRay[1] = mat3(gbufferModelViewInverse) * refRay[0];

	for(int i = 0; i < samples; i++){
		
		if(roughness > ROUGH_REFLECTION_THRESHOLD){
			break;
		}

		if (roughness > 0){ // rough reflections
			float r1 = InterleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter * samples + i);
			float r2 = InterleavedGradientNoise(floor(gl_FragCoord.xy) + vec2(23, 97), frameCounter * samples + i);

			vec2 noise = vec2(r1, r2);
			//vec4 noise = blueNoise(ivec2(floor(gl_FragCoord.xy) + ivec2(23, 97) * (frameCounter * samples + i)));

			mat3 tbn = CalculateTBN(normal);
			offsetNormal = tbn * (SampleVNDFGGX(normalize(-position[0] * tbn), vec2(roughness), noise.xy)); // I should be squaring roughness for alpha but it makes things way too reflective
			
		}

		refRay[0] = reflect(position[0], offsetNormal);
		refRay[1] = mat3(gbufferModelViewInverse) * refRay[0];

		vec3 reflection = vec3(0);
		bool hit = ComputeSSRaytrace(position[0], normalize(refRay[0]), refCoord);
	
		vec3 transmit = vec3(1.0);
		vec3 in_scatter = vec3(0.0);

		
		if (hit) {
			reflection = GetColor(refCoord.st);
			
			vec3 refVPos = CalculateViewSpacePosition(refCoord);
			
			fogFactor = length(abs(position[0] - refVPos) / 500.0);
			
			float angleCoeff = clamp01(pow(offsetNormal.z + 0.15, 0.25) * 2.0) * 0.2 + 0.8;
			float dist       = length8(abs(refCoord.st - vec2(0.5)));
			float edge       = clamp01(1.0 - pow2(dist * 2.0 * angleCoeff));
			fogFactor        = clamp01(fogFactor + pow(1.0 - edge, 10.0));
			
			#ifndef WORLD_THE_NETHER
			
			in_scatter = SkyAtmosphereToPoint(position[1], mat3(gbufferModelViewInverse) * refVPos, transmit, VL);
			#endif
		} else {
			
			#ifdef WORLD_THE_NETHER
				reflection = mix(color, vec3(0.02, 0.02, 0), 0.5);
			#else
			transmit = vec3(1.0);

			float sunFactor = 0.0;
			in_scatter = ComputeSky(normalize(refRay[1]), position[1], transmit, 1.0, true, sunFactor);

			#ifdef CLOUD3D
				vec2 reflectedTexCoord = ViewSpaceToScreenSpace(refRay[0]);
				if(clamp01(reflectedTexCoord) == reflectedTexCoord){
					vec4 cloud = textureLod(colortex5, reflectedTexCoord, VolCloudLOD);
					cloud.rgb = pow2(cloud.rgb) * 50.0;
					
					#ifndef WAVING_WATER
					bool fadeCloudsOnWater = true;
					#else
					bool fadeCloudsOnWater = false;
					#endif


					if(roughness == 0){
						cloud.a = clamp01(mix(cloud.a, 0.0, pow4(length(abs(reflectedTexCoord - 0.5) * 2)))); // fade out sky towards edge of reflections, not noticeable on most surfaces apart from smooth water
					}
					
					in_scatter = mix(in_scatter, cloud.rgb, cloud.a);
				}
			#endif
			

			in_scatter *= (1.0 - float(isEyeInWater == 1.0));

			if(isEyeInWater == 1.0){
				transmit = vec3(1.0);
				reflection = mix(waterColor * sunlightColor, waterColor / 4, 1.0 - skyLightmap) * dot(-normal, lightVector);
			}
			
			#endif
		}
		
		reflection = reflection * transmit + in_scatter;
		if(!hit){
			reflection = mix(reflection, color, 1.0 - skyLightmap); // horrible way to reduce sky reflections without making reflections too dark
		}
		
		reflectionSum += reflection;

		

		if (roughness == 0){
			break;
		}
	}

	
	
	if (roughness > 0){
		reflectionSum /= samples;
	}

	

	vec3 transmit = vec3(1.0);
	vec3 sunspot = sunlightColor * specularHighlight * sunlight;
	sunspot = max(vec3(0.0), normalize(sunspot) * min(length(sunspot), 1024.0));

	if(roughness > ROUGH_REFLECTION_THRESHOLD){
		reflectionSum = color;
	}

	reflectionSum += sunspot;
	
	

	#ifdef MULTIPLY_METAL_ALBEDO
		if (baseReflectance >= (229.5 / 255.0)) {
			reflectionSum *= color;
		}
	#endif
	
	if (baseReflectance < 1.0){
		color = mix(color, reflectionSum, clamp01(fresnel));
	}
	
}


#endif
