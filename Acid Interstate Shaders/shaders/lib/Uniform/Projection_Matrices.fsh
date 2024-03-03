flat varying float FOV;

#ifdef FOV_OVERRIDE
	flat varying mat4 projection;
	flat varying mat4 projectionInverse;
	
	#define projMatrix projection
	#define projInverseMatrix projectionInverse
#else
	uniform mat4 gbufferProjection;
	uniform mat4 gbufferProjectionInverse;
	
	#define projMatrix gbufferProjection
	#define projInverseMatrix gbufferProjectionInverse
#endif
