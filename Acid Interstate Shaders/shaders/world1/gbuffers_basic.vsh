#version 120

varying vec4 color;
varying vec4 texcoord;
varying vec3 normal;

void main() {
	
	gl_Position = ftransform();
	
	color = gl_Color;
	
	texcoord = vec4((gl_MultiTexCoord0).xy,(gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);	
	normal = normalize(gl_NormalMatrix * gl_Normal);	
	
	gl_FogFragCoord = gl_Position.z;
}