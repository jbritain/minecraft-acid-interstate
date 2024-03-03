uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

flat varying float FOV;

#ifdef FOV_OVERRIDE
	flat varying mat4 projection;
	flat varying mat4 projectionInverse;
	
	void SetupProjection() {
		projection = gbufferProjection;
		projectionInverse = gbufferProjectionInverse;
		
		float gameTrueFOV = degrees(atan(1.0 / gbufferProjection[1].y) * 2.0);
		
		cfloat gameSetFOV = FOV_DEFAULT_TENS;
		cfloat targetSetFOV = FOV_TRUE_TENS + FOV_TRUE_FIVES;
		
		FOV = targetSetFOV + (gameTrueFOV - gameSetFOV) * targetSetFOV / gameSetFOV;
		
		projection      = gbufferProjection;
		projection[1].y = 1.0 / tan(radians(FOV) * 0.5);
		projection[0].x = projection[1].y * gbufferProjection[0].x / gbufferProjection[1].y;
		
		
		vec3 i = 1.0 / vec3(diagonal2(projection), projection[3].z);
		
		projectionInverse = mat4(
			i.x, 0.0,  0.0, 0.0,
			0.0, i.y,  0.0, 0.0,
			0.0, 0.0,  0.0, i.z,
			0.0, 0.0, -1.0, projection[2].z * i.z);
	}
	
	#define projMatrix projection
	#define projInverseMatrix projectionInverse
#else
	void SetupProjection() {
		FOV = degrees(atan(1.0 / gbufferProjection[1].y) * 2.0);
	}
	
	#define projMatrix gbufferProjection
	#define projInverseMatrix gbufferProjectionInverse
#endif
