import peasy.*;

PeasyCam cam;

// ---------- Render toggles ----------
boolean isWireframe = false;
boolean isOrtho = false;
boolean isDebug = false;
boolean isTR = true;

boolean isLightsOn = true;
int lightPreset = 0;     // 0 = dzień, 1 = noc
int matPreset = 0;       // 0 matowy, 1 metaliczny, 2 emissive

// ---------- Shading modes ----------
// 0 = FLAT, 1 = GOURAUD, 2 = PHONG
int shadingMode = 0;
PShader gouraudShader;
PShader phongShader;

PImage groundTex;
PShape importedModel;

// ---------- Rover articulation ----------
float turretAngle = 0;
float arm1Angle = radians(-30);
float arm2Angle = radians(-60);
float gripperSpread = 10;
float wheelSpin = 0;
float idleTime = 0;
float animBeacon = 0;

// ---------- Rover transform (world position) ----------
float roverX = 0;
float roverZ = 0;
float roverHeading = 0; // radians, rotation around Y
float roverSpeed = 0;
final float MAX_SPEED = 4.0;
final float ACCEL = 0.15;
final float TURN_SPEED = 0.03;
final float FRICTION = 0.06;
final float ROVER_RADIUS = 170; // approx bounding sphere

// ---------- Input state for movement ----------
boolean keyPressedW = false;
boolean keyPressedS = false;
boolean keyPressedA = false;
boolean keyPressedD = false;

// ---------- Camera modes ----------
// 0 = orbit (general), 1 = chase camera (z pojazdu)
int cameraMode = 0;

// ---------- Obstacles ----------
int NUM_OBSTACLES = 8;
float[] obsX, obsZ, obsR, obsH;
int[] obsType; // 0 = pachoł, 1 = pylon, 2 = skrzynia

// ---------- Collectibles (mission markers) ----------
int NUM_COLLECTIBLES = 6;
float[] colX, colZ;
boolean[] colCollected;
int collectedCount = 0;
boolean missionComplete = false;
final float COLLECT_RADIUS = 60;

// ---------- Probes (projectiles) ----------
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

// ---------- Explosions ----------
final int MAX_EXPLOSIONS = 10;
float[] expX = new float[MAX_EXPLOSIONS];
float[] expY = new float[MAX_EXPLOSIONS];
float[] expZ = new float[MAX_EXPLOSIONS];
float[] expLife = new float[MAX_EXPLOSIONS];
boolean[] expActive = new boolean[MAX_EXPLOSIONS];

void setup() {
  size(1500, 900, P3D);
  sphereDetail(30);

  groundTex = loadImage("ground.jpg");
  importedModel = loadShape("model.obj");

  gouraudShader = loadShader("gouraud.frag", "gouraud.vert");
  phongShader = loadShader("phong.frag", "phong.vert");

  cam = new PeasyCam(this, 0, -60, 0, 600);
  cam.setRotations(0, 0, 0);

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

  float[][] pos = {
    {500, 300}, {-500, 300}, {700, -400}, {-700, -400},
    {0, 800}, {900, 100}, {-900, 100}, {200, -900}
  };
  int[] types = {0, 1, 2, 0, 1, 2, 0, 1};
  float[] radii = {40, 35, 70, 40, 35, 70, 40, 35};
  float[] heights = {80, 140, 100, 80, 140, 100, 80, 140};

  for (int i = 0; i < NUM_OBSTACLES; i++) {
    obsX[i] = pos[i][0];
    obsZ[i] = pos[i][1];
    obsType[i] = types[i];
    obsR[i] = radii[i];
    obsH[i] = heights[i];
  }
}

void initCollectibles() {
  colX = new float[NUM_COLLECTIBLES];
  colZ = new float[NUM_COLLECTIBLES];
  colCollected = new boolean[NUM_COLLECTIBLES];

  float[][] pos = {
    {300, 0}, {-300, 600}, {600, -200}, {-600, -600},
    {0, -800}, {850, 700}
  };
  for (int i = 0; i < NUM_COLLECTIBLES; i++) {
    colX[i] = pos[i][0];
    colZ[i] = pos[i][1];
    colCollected[i] = false;
  }
  collectedCount = 0;
  missionComplete = false;
}

void draw() {
  background(40);

  if (isWireframe) {
    noFill();
    stroke(0, 255, 0);
  } else {
    noStroke();
  }

  // FLAT = default Processing shading (per-vertex/face normals -> flat-looking on boxes)
  // GOURAUD / PHONG = custom GLSL shaders, only when solid (shaders need fill geometry)
  if (!isWireframe) {
    if (shadingMode == 1) {
      shader(gouraudShader);
    } else if (shadingMode == 2) {
      shader(phongShader);
    } else {
      resetShader();
    }
  } else {
    resetShader();
  }

  applyLighting();

  if (isOrtho) {
    ortho(-width/2, width/2, -height/2, height/2, -10000, 10000);
  } else {
    perspective(PI/3.0, (float)width/height, 1, 10000);
  }

  idleTime += 0.05;
  wheelSpin += roverSpeed * 0.4;
  animBeacon += 0.05;

  updateRover();
  updateProbes();
  updateExplosions();
  checkCollectibles();
  updateCamera();

  pushMatrix();
  translate(roverX, 0, roverZ);
  rotateY(roverHeading);
  drawRover();
  popMatrix();

  drawEnvironment();
  drawObstacles();
  drawCollectibles();
  drawProbes();
  drawExplosions();

  cam.beginHUD();
  drawHUD();
  cam.endHUD();
}

// ---------------- Rover movement & collision ----------------

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

  // Collision check vs obstacles (sphere-sphere) with sliding/stop
  for (int i = 0; i < NUM_OBSTACLES; i++) {
    float dx = nx - obsX[i];
    float dz = nz - obsZ[i];
    float dist = sqrt(dx*dx + dz*dz);
    float minDist = ROVER_RADIUS + obsR[i];

    if (dist < minDist && dist > 0.0001) {
      // push back along normal -> sliding stop against the obstacle
      float push = minDist - dist;
      nx += (dx / dist) * push;
      nz += (dz / dist) * push;
      roverSpeed *= 0.2; // dampen speed on hit
    }
  }

  roverX = nx;
  roverZ = nz;

  // bound to ground plane
  roverX = constrain(roverX, -4800, 4800);
  roverZ = constrain(roverZ, -4800, 4800);
}

// ---------------- Probes ----------------

void fireProbe() {
  for (int i = 0; i < MAX_PROBES; i++) {
    if (!probeActive[i]) {
      probeActive[i] = true;
      probeLife[i] = PROBE_LIFE;
      float spawnDist = 150;
      float dirAngle = roverHeading + turretAngle;
      probeX[i] = roverX + sin(dirAngle) * spawnDist;
      probeZ[i] = roverZ + cos(dirAngle) * spawnDist;
      probeY[i] = -120; // turret height
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
      float dist = sqrt(dx*dx + dz*dz);
      if (dist < obsR[o] + PROBE_RADIUS) {
        hit = true;
        break;
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

// ---------------- Explosions ----------------

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

// ---------------- Collectibles ----------------

void checkCollectibles() {
  for (int i = 0; i < NUM_COLLECTIBLES; i++) {
    if (colCollected[i]) continue;
    float dx = roverX - colX[i];
    float dz = roverZ - colZ[i];
    float dist = sqrt(dx*dx + dz*dz);
    if (dist < ROVER_RADIUS + COLLECT_RADIUS) {
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

// ---------------- Obstacles ----------------

void drawObstacles() {
  for (int i = 0; i < NUM_OBSTACLES; i++) {
    pushMatrix();
    translate(obsX[i], 0, obsZ[i]);

    if (obsType[i] == 0) {
      // pachoł
      setMaterial(255, 100, 0, matPreset);
      pushMatrix();
      translate(0, -obsH[i] * 0.4, 0);
      box(obsR[i] * 1.4, obsH[i] * 0.8, obsR[i] * 1.4);
      popMatrix();
      pushMatrix();
      translate(0, -obsH[i] * 0.85, 0);
      setMaterial(255, 220, 0, matPreset);
      sphere(obsR[i] * 0.6);
      popMatrix();
    } else if (obsType[i] == 1) {
      // pylon
      setMaterial(150, 150, 160, matPreset);
      pushMatrix();
      translate(0, -obsH[i] / 2, 0);
      box(obsR[i], obsH[i], obsR[i]);
      popMatrix();
    } else {
      // skrzynia
      setMaterial(120, 80, 40, matPreset);
      pushMatrix();
      translate(0, -obsH[i] / 2, 0);
      box(obsR[i] * 1.8, obsH[i], obsR[i] * 1.8);
      popMatrix();
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

// ---------------- Camera ----------------

void updateCamera() {
  if (cameraMode == 1) {
    cam.setActive(false);

    float behindDist = 350;
    float heightOff = 180;
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
