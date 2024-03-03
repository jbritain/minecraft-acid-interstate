#if !defined EXIT_GLSL
	#define EXIT_GLSL

	#if defined DEBUG && ShaderStage <= -10

	#elif defined DEBUG && ShaderStage < 50

		#if DEBUG_VIEW == ShaderStage
		/* DRAWBUFFERS:3 */
		#elif DEBUG_VIEW < ShaderStage
		/* DRAWBUFFERS:0 */
		#endif

	#elif defined DEBUG && ShaderStage == 7

		#if DEBUG_VIEW <= -10
			uniform sampler2D shadowcolor0;
		#elif DEBUG_VIEW < 50
			uniform sampler2D colortex4;
		#endif

	#endif

	void exit() {
	#ifdef DEBUG
		#if ShaderStage < 7
			#if (DEBUG_VIEW < ShaderStage)
				discard;
			#elif (DEBUG_VIEW == ShaderStage)
				gl_FragData[0] = vec4(Debug, 1.0);
			#else
			#endif
		#else
			#if DEBUG_VIEW < 7
				gl_FragColor = vec4(texture(colortex3, texcoord).rgb, 1.0);
			#elif DEBUG_VIEW == 7
				gl_FragColor = vec4(Debug, 1.0);
			#endif
		#endif
	#endif
	}

#endif
