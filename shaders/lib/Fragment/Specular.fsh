#if !defined SPECULAR_FSH
#define SPECULAR_FSH

vec3 GetMetalf0(float baseReflectance, vec3 color){
	switch(int(baseReflectance * 255 + 0.5)){
			case 230: // Iron
					
					return vec3(0.78, 0.77, 0.74);
			case 231: // Gold
					return vec3(1.00, 0.90, 0.61);
			case 232: // Aluminum
					return vec3(1.00, 0.98, 1.00);
			case 233: // Chrome
					return vec3(0.77, 0.80, 0.79);
			case 234: // Copper
					return vec3(1.00, 0.89, 0.73);
			case 235: // Lead
					return vec3(0.79, 0.87, 0.85);
			case 236: // Platinum
					return vec3(0.92, 0.90, 0.83);
			case 237: // Silver
					return vec3(1.00, 1.00, 0.91);
	}
	return clamp01(color);
}

vec3 GetMetalf82(float baseReflectance, vec3 color){
	switch(int(baseReflectance * 255 + 0.5)){
			case 230: // Iron
					return vec3(0.74, 0.76, 0.76);
			case 231: // Gold
					return vec3(1.00, 0.93, 0.73);
			case 232: // Aluminum
					return vec3(0.96, 0.97, 0.98);
			case 233: // Chrome
					return vec3(0.74, 0.79, 0.78);
			case 234: // Copper
					return vec3(1.00, 0.90, 0.80);
			case 235: // Lead
					return vec3(0.83, 0.80, 0.83);
			case 236: // Platinum
					return vec3(0.89, 0.87, 0.81);
			case 237: // Silver
					return vec3(1.00, 1.00, 0.95);
	}
	
	return clamp01(color);
}

// from bliss, which means it's probably by chocapic
// https://backend.orbit.dtu.dk/ws/portalfiles/portal/126824972/onb_frisvad_jgt2012_v2.pdf
void ComputeFrisvadTangent(in vec3 n, out vec3 f, out vec3 r){
    if(n.z < -0.9) {
        f = vec3(0.,-1,0);
        r = vec3(-1, 0, 0);
    } else {
    	float a = 1./(1.+n.z);
    	float b = -n.x*n.y*a;
    	f = vec3(1. - n.x*n.x*a, b, -n.x) ;
    	r = vec3(b, 1. - n.y*n.y*a , -n.y);
    }
}


// by Zombye
// https://discordapp.com/channels/237199950235041794/525510804494221312/1118170604160421918
vec3 SampleVNDFGGX(
    vec3 viewerDirection, // Direction pointing towards the viewer, oriented such that +Z corresponds to the surface normal
    vec2 alpha, // Roughness parameter along X and Y of the distribution
    vec2 xy // Pair of uniformly distributed numbers in [0, 1)
) {
    // Transform viewer direction to the hemisphere configuration
    viewerDirection = normalize(vec3(alpha * viewerDirection.xy, viewerDirection.z));

    // Sample a reflection direction off the hemisphere
    const float tau = 6.2831853; // 2 * pi
    float phi = tau * xy.x;
    float cosTheta = fma(1.0 - xy.y, 1.0 + viewerDirection.z, -viewerDirection.z);
    float sinTheta = sqrt(clamp(1.0 - cosTheta * cosTheta, 0.0, 1.0));
    vec3 reflected = vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);

    // Evaluate halfway direction
    // This gives the normal on the hemisphere
    vec3 halfway = reflected + viewerDirection;

    // Transform the halfway direction back to hemiellispoid configuation
    // This gives the final sampled normal
    return normalize(vec3(alpha * halfway.xy, halfway.z));
}

// https://advances.realtimerendering.com/s2017/DecimaSiggraph2017.pdf
float GetNoHSquared(float NoL, float NoV, float VoL) {
    float radiusCos = 1.0 - SUN_ANGULAR_PERCENTAGE;
		float radiusTan = tan(facos(radiusCos));
    
    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL, 0.0, 1.0));
    
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;    
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr + 
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;
    
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

float CalculateGGX (vec3 N, vec3 V, vec3 L, float roughness) { // trowbridge-reitz
  float alpha = roughness;

  vec3 H = normalize(L + V);
	// float dotNHSquared = pow2(dot(N, H));
	float dotNHSquared = GetNoHSquared(dot(N, L), dot(N, V), dot(V, L));
	float distr = dotNHSquared * (alpha - 1.0) + 1.0;
	return alpha / (PI * pow2(distr));
}

float CalculateSchlick(float f0, float nDotV){
	bool checkTIR = false;
	#ifdef WATER_REFRACTION
		checkTIR = true;
	#endif

	if(abs(f0 - 0.02) > 0.001 || !checkTIR){ // if not water don't bother checking for TIR
		return f0 + (1 - f0) * pow(1 - nDotV, 5);
	}

	f0 = pow2(f0);
	if(isEyeInWater == 1.0){
		float sinT2 = pow2(1.33)*(1.0 - pow2(nDotV));
		if(sinT2 > 1.0){
			return 1.0;
		}
		nDotV = sqrt(1.0-sinT2);
	}
	float x = 1.0-nDotV;
	return f0 + (1 - f0) * pow(x, 5);
}

// https://www.shadertoy.com/view/DdlGWM
// weird place to get it from, I know
vec3 CalculateLazanyiSchlick(vec3 f0, vec3 f82, float nDotV) {
    // vec3 a = (f0 + (1.-f0)*pow(1.-(1./7.),5.)-f82)/((1./7.)*pow(1.-(1./7.),6.));
    // vec3 a = 7.*(pow(7./6.,6.) * (f0 - f82) + (7./6.) * (1.0 - f0));
    vec3 a = (823543./46656.) * (f0 - f82) + (49./6.) * (1.0 - f0);

    float p1 = 1.0 - nDotV;
    float p2 = p1*p1;
    float p4 = p2*p2;

    return clamp(f0 + ((1.0 - f0) * p1 - a * nDotV * p2) * p4, 0., 1. );
    //return clamp(f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0) - a * cosTheta * pow(1.0 - cosTheta, 6.0),0.,1.);
}

#endif