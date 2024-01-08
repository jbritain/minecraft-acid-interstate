#version 120
/* DRAWBUFFERS:01 */

#define Clouds 3	//[0 1 2 3 4] Toggle clouds. 0=Off, 1=Default MC, 2=2D, 3=VL, 4=2D+VL

uniform sampler2D texture;
varying vec4 color;
varying vec4 texcoord;
varying vec3 normal;

#if Clouds == 1
vec3 RGB2YCoCg(vec3 c){
	return vec3( 0.25*c.r+0.5*c.g+0.25*c.b, 0.5*c.r-0.5*c.b +0.5, -0.25*c.r+0.5*c.g-0.25*c.b +0.5);
}
vec4 encode (vec3 n){
    return vec4(n.xy*inversesqrt(n.z*8.0+8.0) + 0.5, texcoord.zw);
}
#endif

void main() {

#if Clouds == 1
	vec4 albedo = texture2D(texture, texcoord.xy)*color;
	vec4 cAlbedo = vec4(RGB2YCoCg(albedo.rgb),albedo.a);

	bool pattern = (mod(gl_FragCoord.x,2.0)==mod(gl_FragCoord.y,2.0));
	cAlbedo.g = (pattern)?cAlbedo.b: cAlbedo.g;
	cAlbedo.b = 0.02;

	gl_FragData[0] = cAlbedo;
	gl_FragData[1] = encode(normal.xyz);
#else
	discard;
#endif

}