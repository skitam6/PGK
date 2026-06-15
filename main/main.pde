import peasy.*;

PeasyCam cam;

boolean isWireframe = false;
boolean isOrtho = false;
boolean isDebug = false;
boolean isTR = true;

boolean isLightsOn = true;
int lightPreset = 0;
int matPreset = 0;

int shadingMode = 0;
PShader flatShader;
boolean isCustomShaderActive = false;

PImage groundTex;
PShape importedModel;

float turretAngle = 0;
float arm1Angle = radians(-30);
float arm2Angle = radians(-60);
float gripperSpread = 10;
float wheelSpin = 0;
float idleTime = 0;
float animBeacon = 0;

float roverX = 0;
float roverZ = 0;
float roverHeading = 0;
float roverSpeed = 0;
final float MAX_SPEED = 4.0;
final float ACCEL = 0.15;
final float TURN_SPEED = 0.03;
final float FRICTION = 0.06;
final float ROVER_RADIUS = 75;
final float ROVER_OFFSET = 75;

boolean keyPressedW = false;
boolean keyPressedS = false;
boolean keyPressedA = false;
boolean keyPressedD = false;

int cameraMode = 0;

int NUM_OBSTACLES = 10;
float[] obsX, obsZ, obsR, obsH;
int[] obsType;

int NUM_COLLECTIBLES = 6;
float[] colX, colZ;
boolean[] colCollected;
int collectedCount = 0;
boolean missionComplete = false;
final float COLLECT_RADIUS = 60;

final int MAX_PROBES = 20;
float[] probeX = new float[MAX_PROBES];
float[] probeZ = new float[MAX_PROBES];
float[] probeY = new float[MAX_PROBES];
float[] probeDirX = new float[MAX_PROBES];
float[] probeDirZ = new float[MAX_PROBES];
boolean[] probeActive = new boolean[MAX_PROBES];
float[] probeLife = new float[MAX_PROBES];
final float PROBE_SPEED = 8;
final float PROBE_RADIUS = 8;
final float PROBE_LIFE = 120;

final int MAX_EXPLOSIONS = 10;
float[] expX = new float[MAX_EXPLOSIONS];
float[] expY = new float[MAX_EXPLOSIONS];
float[] expZ = new float[MAX_EXPLOSIONS];
float[] expLife = new float[MAX_EXPLOSIONS];
boolean[] expActive = new boolean[MAX_EXPLOSIONS];

void setup() {
  size(1500, 900, P3D);
  
  groundTex = loadImage("ground.jpg");
  importedModel = loadShape("model.obj");
  
  flatShader = loadShader("shaders/flat_frag.glsl", "shaders/flat_vert.glsl");

  cam = new PeasyCam(this, 0, -60, 0, 600);
  cam.setRotations(-0.5, PI, 0);

  initObstacles();
  initCollectibles();
  for (int i = 0; i < MAX_PROBES; i++) probeActive[i] = false;
  for (int i = 0; i < MAX_EXPLOSIONS; i++) expActive[i] = false;
}

void initObstacles() {
  obsX = new float[NUM_OBSTACLES];
  obsZ = new float[NUM_OBSTACLES];
  obsR = new float[NUM_OBSTACLES];
  obsH = new float[NUM_OBSTACLES];
  obsType = new int[NUM_OBSTACLES];
  
  float[][] pos = { {500, 300}, {-500, 300}, {700, -400}, {-700, -400}, {0, 800}, {900, 100}, {-900, 100}, {200, -900}, {-300, 200}, {300, 200} };
  int[] types = {0, 1, 2, 0, 1, 2, 0, 1, 3, 4};
  float[] radii = {40, 35, 70, 40, 35, 70, 40, 35, 45, 80};
  float[] heights = {80, 140, 100, 80, 140, 100, 80, 140, 100, 100};
  
  for (int i = 0; i < NUM_OBSTACLES; i++) {
    obsX[i] = pos[i][0]; obsZ[i] = pos[i][1]; obsType[i] = types[i];
    obsR[i] = radii[i]; obsH[i] = heights[i];
  }
}

void initCollectibles() {
  colX = new float[NUM_COLLECTIBLES];
  colZ = new float[NUM_COLLECTIBLES];
  colCollected = new boolean[NUM_COLLECTIBLES];
  float[][] pos = { {300, 0}, {-300, 600}, {600, -200}, {-600, -600}, {0, -800}, {850, 700} };
  
  for (int i = 0; i < NUM_COLLECTIBLES; i++) {
    colX[i] = pos[i][0]; colZ[i] = pos[i][1]; colCollected[i] = false;
  }
  collectedCount = 0;
  missionComplete = false;
}

void draw() {
  background(40);
  
  if (isWireframe) {
    noFill(); stroke(0, 255, 0);
  } else {
    noStroke();
  }

  sphereDetail(30);
  applyLighting();

  if (isOrtho) ortho(-width/2, width/2, -height/2, height/2, -10000, 10000);
  else perspective(PI/3.0, (float)width/height, 1, 10000);

  idleTime += 0.05;
  wheelSpin += roverSpeed * 0.4;
  animBeacon += 0.05;

  updateRover();
  updateProbes();
  updateExplosions();
  checkCollectibles();
  updateCamera();
  
  if (!isWireframe && shadingMode == 1) {
    shader(flatShader);
    isCustomShaderActive = true;
  } else {
    resetShader();
    isCustomShaderActive = false;
  }

  // Rysowanie łazika (pod wpływem shadera)
  pushMatrix();
  translate(roverX, 0, roverZ);
  rotateY(roverHeading);
  drawRover();
  popMatrix();
  
  // ---> USUNĘLIŚMY STĄD resetShader(); i wyłączenie flagi! <---
  // Dzięki temu poniższe elementy będą rysowane Twoim Flat Shaderem:

  drawEnvironment();
  drawObstacles();
  drawCollectibles();
  drawProbes();
  drawExplosions();

  // ---> PRZENIEŚLIŚMY WYŁĄCZANIE TUTAJ (Przed HUD) <---
  resetShader();
  isCustomShaderActive = false;

  cam.beginHUD();
  drawHUD();
  cam.endHUD();
}

void updateRover() {
  float accel = 0;
  if (keyPressedW) accel += ACCEL;
  if (keyPressedS) accel -= ACCEL;

  roverSpeed += accel;
  if (accel == 0) {
    if (roverSpeed > 0) roverSpeed = max(0, roverSpeed - FRICTION);
    else if (roverSpeed < 0) roverSpeed = min(0, roverSpeed + FRICTION);
  }
  roverSpeed = constrain(roverSpeed, -MAX_SPEED, MAX_SPEED);
  
  float turnDir = (roverSpeed >= 0) ? 1 : -1;
  if (keyPressedA) roverHeading -= TURN_SPEED * turnDir;
  if (keyPressedD) roverHeading += TURN_SPEED * turnDir;

  float nx = roverX + sin(roverHeading) * roverSpeed;
  float nz = roverZ + cos(roverHeading) * roverSpeed;

  for (int i = 0; i < NUM_OBSTACLES; i++) {
    float frontX = nx + sin(roverHeading) * ROVER_OFFSET;
    float frontZ = nz + cos(roverHeading) * ROVER_OFFSET;
    
    float backX = nx - sin(roverHeading) * ROVER_OFFSET;
    float backZ = nz - cos(roverHeading) * ROVER_OFFSET;
    
    float minDist = ROVER_RADIUS + obsR[i];
    
    float dFrontX = frontX - obsX[i];
    float dFrontZ = frontZ - obsZ[i];
    float distFront = sqrt(dFrontX*dFrontX + dFrontZ*dFrontZ);
    
    if (distFront < minDist && distFront > 0.0001) {
      float push = minDist - distFront;
      nx += (dFrontX / distFront) * push;
      nz += (dFrontZ / distFront) * push;
      roverSpeed *= 0.2; 
    }
    
    backX = nx - sin(roverHeading) * ROVER_OFFSET;
    backZ = nz - cos(roverHeading) * ROVER_OFFSET;
    
    float dBackX = backX - obsX[i];
    float dBackZ = backZ - obsZ[i];
    float distBack = sqrt(dBackX*dBackX + dBackZ*dBackZ);
    
    if (distBack < minDist && distBack > 0.0001) {
      float push = minDist - distBack;
      nx += (dBackX / distBack) * push;
      nz += (dBackZ / distBack) * push;
      roverSpeed *= 0.2; 
    }
  }

  roverX = constrain(nx, -4800, 4800);
  roverZ = constrain(nz, -4800, 4800);
}

void fireProbe() {
  for (int i = 0; i < MAX_PROBES; i++) {
    if (!probeActive[i]) {
      probeActive[i] = true;
      probeLife[i] = PROBE_LIFE;
      float spawnDist = 150;
      float dirAngle = roverHeading + turretAngle;
      
      probeX[i] = roverX + sin(dirAngle) * spawnDist;
      probeZ[i] = roverZ + cos(dirAngle) * spawnDist;
      probeY[i] = -120;
      probeDirX[i] = sin(dirAngle);
      probeDirZ[i] = cos(dirAngle);
      return;
    }
  }
}

void updateProbes() {
  for (int i = 0; i < MAX_PROBES; i++) {
    if (!probeActive[i]) continue;
    
    probeX[i] += probeDirX[i] * PROBE_SPEED;
    probeZ[i] += probeDirZ[i] * PROBE_SPEED;
    probeLife[i]--;

    boolean hit = false;
    for (int o = 0; o < NUM_OBSTACLES; o++) {
      float dx = probeX[i] - obsX[o];
      float dz = probeZ[i] - obsZ[o];
      if (sqrt(dx*dx + dz*dz) < obsR[o] + PROBE_RADIUS) {
        hit = true; break;
      }
    }

    if (hit || probeLife[i] <= 0 || abs(probeX[i]) > 5000 || abs(probeZ[i]) > 5000) {
      if (hit) spawnExplosion(probeX[i], probeY[i], probeZ[i]);
      probeActive[i] = false;
    }
  }
}

void drawProbes() {
  for (int i = 0; i < MAX_PROBES; i++) {
    if (!probeActive[i]) continue;
    pushMatrix();
    translate(probeX[i], probeY[i], probeZ[i]);
    setMaterial(0, 255, 255, 2);
    sphere(PROBE_RADIUS);
    popMatrix();
  }
}

void spawnExplosion(float x, float y, float z) {
  for (int i = 0; i < MAX_EXPLOSIONS; i++) {
    if (!expActive[i]) {
      expActive[i] = true;
      expX[i] = x; expY[i] = y; expZ[i] = z;
      expLife[i] = 30;
      return;
    }
  }
}

void updateExplosions() {
  for (int i = 0; i < MAX_EXPLOSIONS; i++) {
    if (!expActive[i]) continue;
    expLife[i]--;
    if (expLife[i] <= 0) expActive[i] = false;
  }
}

void drawExplosions() {
  for (int i = 0; i < MAX_EXPLOSIONS; i++) {
    if (!expActive[i]) continue;
    pushMatrix();
    translate(expX[i], expY[i], expZ[i]);
    float t = expLife[i] / 30.0;
    float r = PROBE_RADIUS + (1 - t) * 60;
    setMaterial(255, (int)(150 * t), 0, 2);
    sphere(r);
    popMatrix();
  }
}

void checkCollectibles() {
  float frontX = roverX + sin(roverHeading) * ROVER_OFFSET;
  float frontZ = roverZ + cos(roverHeading) * ROVER_OFFSET;
  float backX = roverX - sin(roverHeading) * ROVER_OFFSET;
  float backZ = roverZ - cos(roverHeading) * ROVER_OFFSET;

  for (int i = 0; i < NUM_COLLECTIBLES; i++) {
    if (colCollected[i]) continue;
    
    float dFrontX = frontX - colX[i];
    float dFrontZ = frontZ - colZ[i];
    float distFront = sqrt(dFrontX*dFrontX + dFrontZ*dFrontZ);
    
    float dBackX = backX - colX[i];
    float dBackZ = backZ - colZ[i];
    float distBack = sqrt(dBackX*dBackX + dBackZ*dBackZ);
    
    if (distFront < ROVER_RADIUS + COLLECT_RADIUS || distBack < ROVER_RADIUS + COLLECT_RADIUS) {
      colCollected[i] = true;
      collectedCount++;
      if (collectedCount >= NUM_COLLECTIBLES) {
        missionComplete = true;
      }
    }
  }
}

void drawCollectibles() {
  for (int i = 0; i < NUM_COLLECTIBLES; i++) {
    if (colCollected[i]) continue;
    pushMatrix();
    translate(colX[i], -80 + sin(animBeacon * 2 + i) * 15, colZ[i]);
    rotateY(animBeacon + i);
    setMaterial(255, 255, 0, 2);
    box(40);
    popMatrix();
  }
}

void drawObstacles() {
  for (int i = 0; i < NUM_OBSTACLES; i++) {
    pushMatrix();
    translate(obsX[i], 0, obsZ[i]);

    if (obsType[i] == 0) { // pachoł
      setMaterial(255, 100, 0, matPreset);
      pushMatrix(); 
      translate(0, -obsH[i] / 2, 0); 
      box(obsR[i] * 1.4, obsH[i] * 0.8, obsR[i] * 1.4); 
      popMatrix();
    } else if (obsType[i] == 1) { // pylon
      setMaterial(150, 150, 160, matPreset);
      pushMatrix(); 
      translate(0, -obsH[i] / 2, 0); 
      box(obsR[i], obsH[i], obsR[i]); 
      popMatrix();
    } else if (obsType[i] == 2) { // box
      setMaterial(120, 80, 40, matPreset);
      pushMatrix(); 
      translate(0, -obsH[i] / 2, 0); 
      box(obsR[i] * 1.8, obsH[i], obsR[i] * 1.8); 
      popMatrix();
    } else if (obsType[i] == 3) { 
      pushMatrix();
      translate(0, -30, 0);
      rotateY(animBeacon / 2);
      setMaterial(100, 200, 100, matPreset);
      box(60); translate(0, -60, 0); box(40);
      popMatrix();
    } else if (obsType[i] == 4) {
      if (importedModel != null && !isWireframe) {
        pushMatrix();
        rotateX(PI); scale(50);
        shape(importedModel);
        popMatrix();
      }
    }

    if (isDebug) {
      pushMatrix(); 
      stroke(255, 0, 255); 
      noFill(); 
      translate(0, -obsH[i] / 2, 0); 
      sphere(obsR[i]); 
      popMatrix();
    }
    popMatrix();
  }
}

void updateCamera() {
  if (cameraMode == 1) {
    cam.setActive(false);
    float behindDist = 550;
    float heightOff = 280;
    float eyeX = roverX - sin(roverHeading) * behindDist;
    float eyeZ = roverZ - cos(roverHeading) * behindDist;
    float eyeY = -heightOff;
    float lookX = roverX + sin(roverHeading) * 200;
    float lookZ = roverZ + cos(roverHeading) * 200;
    float lookY = -80;
    camera(eyeX, eyeY, eyeZ, lookX, lookY, lookZ, 0, 1, 0);
  } else {
    cam.setActive(true);
  }
}
