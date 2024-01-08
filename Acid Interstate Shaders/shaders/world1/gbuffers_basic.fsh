#version 120
/* DRAWBUFFERS:0 */ //01 breaks selection box color but fixes leads

varying vec4 color;
varying vec4 texcoord;
varying vec3 normal;

uniform sampler2D texture;

//encode normal in two channel (xy),torch and material(z) and sky lightmap (w)
vec4 encode (vec3 n){
    float p = sqrt(n.z*8+8);
    return vec4(n.xy/p + 0.5,texcoord.z,texcoord.w);
}

vec3 RGB2YCoCg(vec3 c){
	return vec3( 0.25*c.r+0.5*c.g+0.25*c.b, 0.5*c.r-0.5*c.b +0.5, -0.25*c.r+0.5*c.g-0.25*c.b +0.5);
}

void main() {

vec4 cAlbedo = vec4(RGB2YCoCg(color.rgb),color.a);

bool pattern = (mod(gl_FragCoord.x,2.0)==mod(gl_FragCoord.y,2.0));
cAlbedo.g = (pattern)?cAlbedo.b: cAlbedo.g;
cAlbedo.b = 1.0;

	gl_FragData[0] = cAlbedo;
	gl_FragData[1] = encode(normal.xyz);	
}