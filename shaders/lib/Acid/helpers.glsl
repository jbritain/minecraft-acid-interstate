#ifndef HELPERS_GLSL
#define HELPERS_GLSL

mat3 rotateZ(in float rad){
	mat3 rot;
	rot[0] = vec3(cos(rad), -sin(rad), 0.0f);
	rot[1] = vec3(sin(rad), cos(rad), 0.0f);
	rot[2] = vec3(0.0f, 0.0f, 1.0f);

	return rot;
}

mat3 rotateX(in float rad){
    mat3 rot;
    rot[0] = vec3(1.0f, 0.0f, 0.0f);
    rot[1] = vec3(0.0f, cos(rad), -sin(rad));
    rot[2] = vec3(0.0f, sin(rad), cos(rad));

    return rot;
}

float shouldEnableBetweenX(in float startX, in float endX, in float X){
	return clamp(ceil((X - startX)*(-1 * X + endX)), 0, 1);
}

// https://github.com/zadvorsky/three.bas/blob/master/src/glsl/ease_cubic_in_out.glsl
float easeCubicInOut(float t) {
  return (t /= 0.5) < 1.0 ? 0.5 * t * t * t : 0.5 * ((t-=2.0) * t * t + 2.0);
}

float easeCubicOut(float t) {
  float f = t - 1.0;
  return f * f * f + 1.0;
}

float easeCubicIn(float t) {
  return t * t * t;
}

vec3 rotate(vec3 point, vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    vec3 skew = cross(axis, point) * (1.0 - c);

    return point * c + skew + axis * dot(axis, point) * (1.0 - c);
}

vec3 translate(inout vec3 point, in vec3 translation) {
	return point + translation;
}

#endif