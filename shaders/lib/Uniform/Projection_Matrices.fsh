

#ifdef FOV_OVERRIDE
	flat varying mat4 projection;
	flat varying mat4 projectionInverse;
	
	#define gbufferProjection projection
	#define gbufferProjectionInverse projectionInverse
#else
	uniform mat4 gbufferProjection;
	uniform mat4 gbufferProjectionInverse;
	
	#define gbufferProjection gbufferProjection
	#define gbufferProjectionInverse gbufferProjectionInverse
#endif
