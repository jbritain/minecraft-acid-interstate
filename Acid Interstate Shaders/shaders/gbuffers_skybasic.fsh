#version 120

void main() {
	gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0); //fill with zeros to avoid issues, alpha has to be set to 1.0 to fix an optifine issue in 1.17+ causing the sky to be black at certain angles.
}