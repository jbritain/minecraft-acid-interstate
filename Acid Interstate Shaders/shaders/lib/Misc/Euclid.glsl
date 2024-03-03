#if !defined EUCLID_GLSL
#define EUCLID_GLSL

float DistanceToPlane(vec3 point, vec3 p0, vec3 p1, vec3 p2) {
	vec3   normal = normalize(cross(p1 - p0, p2 - p0));
	return dot(normal, point) - dot(normal, p0);
}

float DistanceToPlane(vec3 point, vec3 p1, vec3 p2) {
	vec3   normal = normalize(cross(p1, p2));
	return dot(normal, point);
}

bool IsInsideFrustum(vec3 pos, vec3 center, float horizontalSpan, float verticalSpan) {
	vec3 topLeft  = center + vec3(0.0,  verticalSpan, -horizontalSpan );
	vec3 topRight = center + vec3(0.0,  verticalSpan,  horizontalSpan );
	vec3 botLeft  = center + vec3(0.0, -verticalSpan, -horizontalSpan );
	vec3 botRight = center + vec3(0.0, -verticalSpan,  horizontalSpan );
	
	vec3 camPos = cameraPosition + vec3(1000*0,0,0) + gbufferModelViewInverse[3].xyz;
	
	bool b1 = DistanceToPlane(pos, camPos, topLeft, topRight) < 0.0;
	bool b2 = DistanceToPlane(pos, camPos, topRight, botRight) < 0.0;
	bool b3 = DistanceToPlane(pos, camPos, botRight, botLeft) < 0.0;
	bool b4 = DistanceToPlane(pos, camPos, botLeft, topLeft) < 0.0;
	
	if (camPos.x < center.x)
		return !(b1||b2||b3||b4);
	else
		return !(b1&&b2&&b3&&b4);
}

/* Example:
if (IsInsideFrustum(position[1]+cameraPosition+gbufferModelViewInverse[3].xyz, vec3(1177-1000,81.0,5.5), 0.5, 1.0)) {
    diffuse.rgb*= 0.0;
    diffuse.a *= 0.0;
}
*/

#endif
