/* Availible variables:
 * 
 * float time:     Counts up 1.0 every frame
 * vec3  position: The player's world space position
 * float dayCycle: Cycles from 0.0 to 1.0 over the course of a day
 * 
 * 
 * Output variables:
 * 
 * timeAngle:         The angle that by default determines what time of day it is
 * pathRotationAngle: The angle that by default is determined by the "Sun Path Rotation" setting
 * twistAngle:        Rotates the sun around the y-axis
 * 
 * All outputs are floating point degree units.
*/

#include "/lib/Acid/time.glsl"

#define time frameTimeCounter
#define dayCycle sunAngle
#define position cameraPosition

void UserRotation() {
	timeAngle = getTimeAngle(getTime(position.x));
	//timeAngle = position.x * 25.0;
}

void TimeOverride() {
#if TIME_OVERRIDE_MODE == 1 // Constant Time
	
	timeAngle = CONSTANT_TIME_HOUR * 15.0;
	
#elif TIME_OVERRIDE_MODE == 2 // Day/Night Only
	
	timeAngle = mod(timeAngle, 180.0) + 180.0 * float(CUSTOM_DAY_NIGHT == 2);
	
#elif TIME_OVERRIDE_MODE == 3 // Misc Time Effect
	
	
	#if CUSTOM_TIME_MISC == 1 // Old North
		
		twistAngle = 90.0;
		
	#elif CUSTOM_TIME_MISC == 2 // Debug
		
		UserRotation();
		
	#endif
	
	
#endif
}

#undef time
#undef dayCycle
#undef position
