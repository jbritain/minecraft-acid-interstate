bvec2 and(bvec2 a, bvec2 b) {
	return bvec2(a.x && b.x, a.y && b.y);
}

bvec3 and(bvec3 a, bvec3 b) {
	return bvec3(a.x && b.x, a.y && b.y, a.z && b.z);
}

bvec4 and(bvec4 a, bvec4 b) {
	return bvec4(a.x && b.x, a.y && b.y, a.z && b.z, a.w && b.w);
}


bvec2 or(bvec2 a, bvec2 b) {
	return bvec2(a.x || b.x, a.y || b.y);
}

bvec3 or(bvec3 a, bvec3 b) {
	return bvec3(a.x || b.x, a.y || b.y, a.z || b.z);
}

bvec4 or(bvec4 a, bvec4 b) {
	return bvec4(a.x || b.x, a.y || b.y, a.z || b.z, a.w || b.w);
}
