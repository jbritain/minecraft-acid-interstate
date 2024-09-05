flat varying mat4 shadowView;

#define shadowViewMatrix shadowView

vec3 sunAngles; // (time, path rotation, twist)

#define timeAngle sunAngles.x
#define pathRotationAngle sunAngles.y
#define twistAngle sunAngles.z


#include "/UserProgram/Time_Override.vsh"

void GetDaylightVariables(out float isNight, out vec3 worldLightVector) {
	timeAngle = sunAngle * 360.0;
	pathRotationAngle = sunPathRotation;
	twistAngle = 0.0;
	
	
#ifdef TIME_OVERRIDE
	TimeOverride();
#endif
	
	
	timeAngle = -timeAngle;
//	pathRotationAngle = (mod(pathRotationAngle + 90.0, 180.0) - 90.0);
	
	sunAngles = radians(sunAngles);
	
	vec3 cosine = cos(sunAngles);
	vec3   sine = sin(sunAngles);
	
	#define A cosine.x
	#define B   sine.x
	#define C cosine.y
	#define D   sine.y
	#define E cosine.z
	#define F   sine.z
	
	shadowView = mat4(
	-B*E + D*A*F,  -C*F,  A*E + D*B*F,  shadowModelView[0].w,
			-C*A,    -D,         -C*B,  shadowModelView[1].w,
	 D*A*E + B*F,  -C*E,  D*B*E - A*F,  shadowModelView[2].w,
	 shadowModelView[3]);
	
#ifdef TELEFOCAL_SHADOWS
	#ifdef SHADOWS_FOCUS_CENTER
		vec3 position = vec3(0.0, 0.0, centerDepthSmooth * 2.0 - 1.0);
		     position = projMAD(gbufferProjectionInverse, position) / (position.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
		     position = mat3(gbufferModelViewInverse) * position;
	#else
		#include "/UserProgram/ShadowFocus.vsh"
		
		#if !defined gbuffers_shadow
			vec3 camPos = previousCameraPosition;
		#else
			vec3 camPos = cameraPosition;
		#endif
		
		vec3 position = vec3(Shadow_Focus_X, Shadow_Focus_Y, Shadow_Focus_Z) - camPos;
		
		#undef X
		#undef Y
		#undef Z
	#endif
	
	shadowView[3].xyz -= mat3(shadowView) * position;
#endif
	
	worldLightVector = vec3(F*D*B + E*A,  -C*B,  E*D*B - F*A);
	
	isNight = float(worldLightVector.y < -0.05);
	
	if (isNight == 1.0) {
		worldLightVector = -worldLightVector;
		shadowView[0].xyz = -shadowView[0].xyz;
		shadowView[1].xyz = -shadowView[1].xyz;
		shadowView[2].xyz = -shadowView[2].xyz;
	}
}

void CalculateShadowView() {
	float isNight;
	vec3  worldLightVector;
	
	GetDaylightVariables(isNight, worldLightVector);
}
