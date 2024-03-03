#if !defined MASKS_FSH
#define MASKS_FSH

struct Mask {
	float materialIDs;
	float matIDs;
	
	vec4 bits;
	
	float translucent;
	float emissive;
	float hand;
	
	float transparent;
	float water;
};

#define EmptyMask Mask(0.0, 0.0, vec4(0.0), 0.0, 0.0, 0.0, 0.0, 0.0)

float EncodeMaterialIDs(float materialIDs, vec4 bits) {
	materialIDs += dot(vec4(greaterThan(bits, vec4(0.5))), vec4(128.0, 64.0, 32.0, 16.0));
	
	materialIDs += 0.1;
	materialIDs /= 255.0;
	
	return materialIDs;
}

void DecodeMaterialIDs(io float matID, out vec4 bits) {
	matID *= 255.0;
	
	bits = mod(vec4(matID), vec4(256.0, 128.0, 64.0, 32.0));
	
	bits = vec4(greaterThanEqual(bits, vec4(128.0, 64.0, 32.0, 16.0)));
	
	matID -= dot(bits, vec4(128.0, 64.0, 32.0, 16.0));
}

float GetMaterialMask(float mask, float materialID) {
	return float(abs(materialID - mask) < 0.1);
}

Mask CalculateMasks(float materialIDs) {
	Mask mask;
	
	mask.materialIDs = materialIDs;
	mask.matIDs      = materialIDs;
	
	DecodeMaterialIDs(mask.matIDs, mask.bits);
	
	mask.translucent = GetMaterialMask(2, mask.matIDs);
	mask.emissive    = GetMaterialMask(3, mask.matIDs);
	mask.hand        = GetMaterialMask(5, mask.matIDs);
	
	mask.transparent = mask.bits.x;
	mask.water       = mask.bits.y;
	
	return mask;
}

#endif
