#include "/lib/Syntax.glsl"


varying vec2 texcoord;


/***********************************************************************/
#if defined vsh

uniform vec2 pixelSize;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"


void main() {
#ifdef BLOOM_ENABLED
	texcoord    = gl_MultiTexCoord0.st;
	gl_Position = ftransform();
	
	vec2 vertexScale = vec2(0.25 + pixelSize.x * 2.0, 0.375 + pixelSize.y * 4.0);
	
	gl_Position.xy = ((gl_Position.xy * 0.5 + 0.5) * vertexScale) * 2.0 - 1.0; // Crop the vertex to only cover the areas that are being used
	
	texcoord *= vertexScale; // Compensate for the vertex adjustment to make this a true "crop" rather than a "downscale"
	
#else
	gl_Position = vec4(-1.0);
#endif
}

#endif
/***********************************************************************/



/***********************************************************************/
#if defined fsh

const bool colortex3MipmapEnabled = true;

uniform sampler2D colortex3;

uniform vec2 pixelSize;

#include "/lib/Settings.glsl"
#include "/lib/Utility.glsl"
#include "/lib/Debug.glsl"

vec3 ComputeBloomTile(cfloat scale, vec2 offset) { // Computes a single bloom tile, the tile's blur level is inversely proportional to its size
	// Each bloom tile uses (1.0 / scale + pixelSize * 2.0) texcoord-units of the screen
	
	vec2 coord  = texcoord;
	     coord -= offset + pixelSize; // A pixel is added to the offset to give the bloom tile a padding
	     coord *= scale;
	
	vec2 padding = pixelSize * scale;
	
	if (any(greaterThanEqual(abs(coord - 0.5), padding + 0.5)))
		return vec3(0.0);
	
	
	float Lod = log2(scale);
	
	cfloat range     = 2.0 * scale; // Sample radius has to be adjusted based on the scale of the bloom tile
	cfloat interval  = 1.0 * scale;
	float  maxLength = length(vec2(range));
	
	vec3  bloom       = vec3(0.0);
	float totalWeight = 0.0;
	
	for (float i = -range; i <= range; i += interval) {
		for (float j = -range; j <= range; j += interval) {
			float weight  = 1.0 - length(vec2(i, j)) / maxLength;
			      weight *= weight;
			      weight  = cubesmooth(weight); // Apply a faux-gaussian falloff
			
			vec2 offset = vec2(i, j) * pixelSize;
			
			bloom       += pow(texture2DLod(colortex3, coord + offset, Lod).rgb, vec3(2.2)) * weight;
			totalWeight += weight;
		}
	}
	
	return bloom / totalWeight;
}

vec3 ComputeBloom() {
	vec3 bloom  = ComputeBloomTile(  4, vec2(0.0                         ,                          0.0));
	     bloom += ComputeBloomTile(  8, vec2(0.0                         , 0.25     + pixelSize.y * 2.0));
	     bloom += ComputeBloomTile( 16, vec2(0.125    + pixelSize.x * 2.0, 0.25     + pixelSize.y * 2.0));
	     bloom += ComputeBloomTile( 32, vec2(0.1875   + pixelSize.x * 4.0, 0.25     + pixelSize.y * 2.0));
	     bloom += ComputeBloomTile( 64, vec2(0.125    + pixelSize.x * 2.0, 0.3125   + pixelSize.y * 4.0));
	     bloom += ComputeBloomTile(128, vec2(0.140625 + pixelSize.x * 4.0, 0.3125   + pixelSize.y * 4.0));
	     bloom += ComputeBloomTile(256, vec2(0.125    + pixelSize.x * 2.0, 0.328125 + pixelSize.y * 6.0));
	
	return max(bloom, vec3(0.0));
}

/* DRAWBUFFERS:1 */
#include "/lib/Exit.glsl"

void main() {
	gl_FragData[0] = vec4(pow(ComputeBloom(), vec3(1.0 / 2.2)), 1.0);
	
	exit();
}

#endif
/***********************************************************************/
