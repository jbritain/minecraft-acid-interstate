void doRotationEffect(inout vec3 position, in float rotAmount, in float offset, in float startX, in float endX, in float X){

  if (shouldEnableBetweenX(startX, endX, X) == 1){
    position = position.xyz * rotateX(sin(((position.x + offset) / 100) * rotAmount));
  }
}

// we want to rotate around some Y axis
// we can only rotate the origin, so we transform such that the origin is on the Y axis, moving the point away from it
// then we rotate around the Y axis
// and then bring it back
void doCurveYEffect(inout vec3 position, in float rotAmount, in float XOffset, in float ZOffset, in float startX, in float endX, in float X) {
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    position.xyz = translate(position.xyz, vec3(XOffset, 0, ZOffset));
    position.xyz = rotate(position.xyz, vec3(0, sign(rotAmount), 0), rotAmount * 0.005 * position.x);
    position.xyz = translate(position.xyz, vec3(-XOffset, 0, -ZOffset));
  }
}

// same but on the Z axis
void doCurveZEffect(inout vec3 position, in float rotAmount, in float XOffset, in float YOffset, in float startX, in float endX, in float X) {
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    position.xyz = translate(position.xyz, vec3(XOffset, YOffset, 0));
    position.xyz = rotate(position.xyz, vec3(0, 0, sign(rotAmount)), rotAmount * 0.01 * max(position.x, 0));
    position.xyz = translate(position.xyz, vec3(-XOffset, -YOffset, 0));
  }
}

// same again but on the X axis
void doSpiralEffect(inout vec3 position, in float rotAmount, in float YOffset, in float ZOffset, in float startX, in float endX, in float X) {
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    //position.xyz = translate(position.xyz, vec3(0, YOffset, ZOffset));
    //position.xyz = rotate(position.xyz, vec3(sign(rotAmount), 0, 0), rotAmount * 0.01 * position.x);
    //position.xyz = translate(position.xyz, vec3(0, -YOffset, -ZOffset));

    position.xyz += vec3(0, YOffset, ZOffset);
    position.xyz = position.xyz * rotateX(rotAmount * 0.01 * position.x);
    position.xyz -= vec3(0, YOffset, ZOffset);
  }
}

void doSquashYEffect(inout vec3 position, in float amount, in float startX, in float endX, in float X, in float centre){
  if (shouldEnableBetweenX(startX, endX, X) == 1 && position.x > 0){
    position.y = (position.y + centre) * (sqrt(position.x) * amount + 1) - centre;
  }
}

void doSquashZEffect(inout vec3 position, in float amount, in float startX, in float endX, in float X, in float centre){
  if (shouldEnableBetweenX(startX, endX, X) == 1 && position.x > 0){
    position.z = (position.z + centre) * (sqrt(position.x) * amount + 1) - centre;
  }
}

void doSquashXEffect(inout vec3 position, in float amount, in float startX, in float endX, in float X, in float centre){
  if (shouldEnableBetweenX(startX, endX, X) == 1 && position.x > 0){
    position.x = (position.x + centre) * (pow(position.x, 1/8) * amount + 1) - centre;
  }
}

void doSinAlongX(inout vec3 position, in float amount, in float stretch, in float startX, in float endX, in float X){
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    if (stretch == 0){
      position.y += amount * 0.1 * sin(position.x) * max(0, log(abs(position.z)));
    } else {
      position.y += amount * 0.1 * sin(position.x + stretch) * max(0, log(abs(position.z)));
    }
    
  }
}

void doWaveAlongX(inout vec3 position, in float amount, in float startX, in float endX, in float x){
  float pi = acos(-1.0);
  if (shouldEnableBetweenX(startX, endX, x) == 1){
    position.y += amount * sin(2 * pi * (position.x / 256));
  }
}