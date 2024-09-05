
void doRotationEffect(inout vec3 position, in float rotAmount, in float stretch, in float startX, in float endX, in float X){

  float xDistance = position.x / 512.0;
  xDistance = xDistance / 2 + 0.5;

  rotAmount *= (xDistance * 2);

  if (shouldEnableBetweenX(startX, endX, X) == 1){
    // transform up two blocks so we are rotating around the blocks the track is placed on
    position.y += 1.5;
    position = position.xyz * rotateX(sin(((position.x * stretch) / 100)) * rotAmount); // the actual rotation
    position.y -= 1.5;
  }
}

// we want to rotate around some Y axis
// we can only rotate the origin, so we transform such that the origin is on the Y axis, moving the point away from it
// then we rotate around the Y axis
// and then bring it back
void doCurveYEffect(inout vec3 position, in float rotAmount, in float XOffset, in float ZOffset, in float startX, in float endX, in float X) {
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    position.xyz = translate(position.xyz, vec3(XOffset, 0, ZOffset));
    position.xyz = rotate(position.xyz, vec3(0, sign(rotAmount) * sign(position.x), 0), rotAmount * 0.005 * position.x);
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
    position.y += sin(((position.x * stretch) / 100)) * amount;
  }
}

void doWaveAlongX(inout vec3 position, in float amount, in float startX, in float endX, in float x){
  float pi = acos(-1.0);
  if (shouldEnableBetweenX(startX, endX, x) == 1){
    position.y += amount * (cos(2 * pi * (position.x / 32))-1);
  }
}

void doNewCurveYEffect(inout vec3 position, in float startAngle, in float curveAngle, in float startX, in float endX, in float X){
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    position = rotate(position, vec3(0, -sign(startAngle), 0), -(startAngle / (2 * acos(0))));
    position = rotate(position, vec3(0, sign(curveAngle) * sign(position.x), 0), (curveAngle / (2 * acos(0))) * (position.x / 256.0));
  }
}

void doScaleYEffect(inout vec3 position, in float amount, in float startX, in float endX, in float X){
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    float oldY = position.y;
    position.y *= ((amount * (position.x / 512)) + 1);

    if (sign(oldY) != sign(position.y)){
      position.y = 0;
    }
  }
}

void doWeirdSpiralEffect(inout vec3 position, in float radius, in float rotation, in float apply, in float startX, in float endX, in float X){
  if (shouldEnableBetweenX(startX, endX, X) == 1){
    vec3 newPosition;
    newPosition = rotate(position, vec3(-sign(position.z), 0, 0), position.z / -radius);
    newPosition.y -= radius;
    newPosition = rotate(newPosition, vec3(sign(rotation), 0, 0), (pow(abs(newPosition.x), 1.1) * rotation * sign(abs(newPosition.x))) / 512);
    newPosition.y += radius;
    
    position = mix(position, newPosition, apply);
  }
}