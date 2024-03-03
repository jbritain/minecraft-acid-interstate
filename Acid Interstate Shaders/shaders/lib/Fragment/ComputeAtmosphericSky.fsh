vec2 AtmosphereDistances(vec3 worldPosition, vec3 worldDirection, cfloat atmosphereRadius, cvec2 radiiSquared) {
	// Considers the planet's center as the coordinate origin, as per convention
	
	float b  = -dot(worldPosition, worldDirection);
	float bb = b * b;
	vec2  c  = dot(worldPosition, worldPosition) - radiiSquared;
	
	vec2 delta   = sqrt(max0(bb - c)); // .x is for planet distance, .y is for atmosphere distance
	     delta.x = -delta.x; // Invert delta.x so we don't have to subtract it later
	
	if (worldPosition.y < atmosphereRadius) { // If inside the atmosphere, uniform condition
		if (bb < c.x || b < 0.0) return vec2(b + delta.y, 0.0); // If the earth is not visible to the ray, check against the atmosphere instead
		
		vec2 dist     = b + delta;
		vec3 hitPoint = worldPosition + worldDirection * dist.x;
		
		float horizonCoeff = dotNorm(hitPoint, worldDirection);
		      horizonCoeff = exp2(horizonCoeff * 5.0);
		
		return vec2(mix(dist.x, dist.y, horizonCoeff), 0.0);
	} else {
		if (b < 0.0) return vec2(0.0);
		
		if (bb < c.x) return vec2(2.0 * delta.y, b - delta.y);
		
		return vec2((delta.y + delta.x) * 2.0, b - delta.y);
	}
}

vec3 ComputeAtmosphericSky(vec3 worldDirection, io vec3 transmit) {
	cfloat iSteps = 23;
	
	cvec3  OZoneCoeff    =  vec3(3.426, 8.298, 0.356) * 6e-7;
	cvec3  rayleighCoeff =  vec3(0.58, 1.35, 3.31) * 1e-5               * -1.0;
	cvec3  rayleighOZone = (vec3(0.58, 1.35, 3.31) * 1e-5 + OZoneCoeff) * -1.0;
	cfloat      mieCoeff = 7e-6 * -1.0;
	
	cfloat rayleighHeight = 8.0e3 * 1.0;
	cfloat      mieHeight = 1.2e3 * 2.0;
	
	cfloat     planetRadius = 6371.0e2;
	cfloat atmosphereRadius = 6471.0e2;
	
	cvec2 radiiSquared = vec2(planetRadius, atmosphereRadius) * vec2(planetRadius, atmosphereRadius);
	
	vec3 worldPosition = vec3(0.0, planetRadius + 1000.0 + (cameraPosition.y - 256) * 40.0*0, 0.0);
	
	vec2 atmosphereDistances = AtmosphereDistances(worldPosition, worldDirection, atmosphereRadius, radiiSquared);
	
	if (atmosphereDistances.x <= 0.0)
		{ return vec3(0.0); }
	
	float iStepSize  = atmosphereDistances.x / iSteps; // Calculate the step size of the primary ray
	vec3  iStep      = worldDirection * iStepSize;
	
	cvec2 scatterMUL = -1.0 / vec2(rayleighHeight, mieHeight);
	vec4  scatterADD = vec2(log2(iStepSize), 0.0).xxyy - planetRadius * scatterMUL.rgrg;
	
	
	vec3 iPos = worldPosition + worldDirection * (iStepSize * 0.5 + atmosphereDistances.y); // Calculate the primary ray sample position
	
	vec3 c = vec3(dot(iPos, iPos), dot(iPos, iStep) * 2.0, pow2(iStepSize)); // dot(iStep, iStep)
	vec2 e = vec2(dot(iPos, sunVector), dot(iStep, sunVector));
	
	
	vec3 rayleigh = vec3(0.0); // Accumulators for Rayleigh and Mie scattering
	vec3 mie      = vec3(0.0);
	
	vec2 opticalDepth = vec2(0.0); // Optical depth accumulators
	
    // Sample the primary ray
	for (float i = 0; i < iSteps; i++) {
		float iPosLength2 = fma(fma(c.z, i, c.y), i, c.x);
		
		float b = fma(e.y, i, e.x); // b = dot(iPos, sunVector);
		float jStepSize = sqrt(fma(b, b, radiiSquared.y - iPosLength2)) - b; // jStepSize = sqrt(b*b + radiiSquared.y - dot(iPos, iPos)) - b;
		
		float jPosLength2 = fma(fma(jStepSize, 0.25, b), jStepSize, iPosLength2);
		
		vec4 opticalStep = exp2(sqrt(vec2(iPosLength2, jPosLength2)).xxyy * scatterMUL.rgrg + scatterADD); // Calculate the optical depth of the Rayleigh and Mie scattering for this step
		opticalDepth += opticalStep.rg;
		opticalStep.ba = opticalStep.ba * jStepSize + opticalDepth;
		
		vec3 attn = exp2(rayleighOZone * opticalStep.b + (mieCoeff * opticalStep.a));
		
		rayleigh += opticalStep.r * attn;
		mie      += opticalStep.g * attn;
		transmit *= attn;
    }
	
	// Calculate the Rayleigh and Mie phases
	float g = 0.9;
	float gg = g * g;
    float mu = e.y / iStepSize; // dot(worldDirection, sunVector);
    float rayleighPhase = 1.5 * (1.0 + mu * mu);
    float      miePhase = rayleighPhase * (1.0 - gg) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));
	
	mie = max0(mie);
	
	vec3 inScatter = -(rayleigh * rayleighPhase * rayleighCoeff + mie * miePhase * mieCoeff);
	
    return inScatter;
}
