void SetupShading() {
	float isNight;
	GetDaylightVariables(isNight, worldLightVector);
	
	lightVector = mat3(gbufferModelView) * worldLightVector;
	sunVector   = worldLightVector * (1.0 - isNight * 2.0);
	
	float LdotUp = sunVector.y;
	
	timeDay   = 1.0 - pow4(1.0 - clamp01( LdotUp - 0.02) / 0.98);
	timeNight = 1.0 - pow4(1.0 - clamp01(-LdotUp - 0.02) / 0.98);
	
	timeHorizon	= clamp01(1.0 - distance(sunVector.y, -0.05) / 0.05);
	
	
	
	
#ifdef PRECOMPUTED_ATMOSPHERE

	vec3 transmit = vec3(1.0);
	vec3 fakeTransmit = vec3(1.0);
	SkyAtmosphere(sunVector, transmit);
	//transmit /= mix(1.0, 8.0, biomeWetness);
	sunlightColor = 7.0 * transmit + CalculateNightSky(sunVector, fakeTransmit) * 7.0 * (1.0 - timeHorizon) * isNight;

	transmit = vec3(1.0);
	skylightColor = SkyAtmosphere(normalize(vec3(0,1,0)), transmit) * 0.5 * mix(1.0, 0.5, biomePrecipness);
	
	transmit = vec3(1.0);
//	sunlightDay = GetSunAndSkyIrradiance(kPoint(vec3(0.0)), vec3(0,1,0), sunVector, skylightDay);
	
#else
	sunlightDay     = setLength(sunlightDay    , 4.0)*3.0;
	sunlightNight   = setLength(sunlightNight  , 0.1);
	sunlightSunrise = setLength(sunlightSunrise, 4.0);

	skylightDay     = setLength(skylightDay    , 0.40);
	skylightNight   = setLength(skylightNight  , 0.004);
	skylightSunrise = setLength(skylightSunrise, 0.01);
	skylightHorizon = setLength(skylightHorizon, 0.003);

	sunlightColor = mix(sunlightDay, sunlightSunrise, timeHorizon) * timeDay + sunlightNight * timeNight;
	skylightColor = mix(skylightDay, skylightSunrise, timeHorizon) * timeDay + skylightNight * timeNight + skylightHorizon * timeHorizon;
#endif
}
