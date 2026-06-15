void applyLighting() {
  if (!isLightsOn) {
    ambientLight(10, 10, 10);
    return;
  }

  if (lightPreset == 0) {
    ambientLight(150, 150, 150);
    directionalLight(255, 255, 240, -1, 1, -1);
  } else {
    ambientLight(30, 30, 40);
    float intensity = 150 + sin(animBeacon * 0.3) * 100;
    float antennaTipY = -210;

    pointLight(intensity, 0, 0, 300, antennaTipY, 200);
    if (isDebug) {
      pushMatrix();
      translate(300, antennaTipY, 200);
      if (!isWireframe) {
        setMaterial((int)intensity, 0, 0, 2);
        noStroke();
      } else {
        stroke(255, 0, 0);
        noFill();
      }
      sphere(5);
      popMatrix();
    }
  }
}

void setMaterial(int r, int g, int b, int type) {
  if (isWireframe) return;
  fill(r, g, b);

  if (type == 0) {
    ambient(r/2.0, g/2.0, b/2.0);
    specular(20);
    shininess(2);
    emissive(0);
  } else if (type == 1) {
    ambient(r/3.0, g/3.0, b/3.0);
    specular(255);
    shininess(80);
    emissive(0);
  } else if (type == 2) {
    ambient(0);
    specular(0);
    shininess(1);
    emissive(r, g, b);
  }
}

void drawEnvironment() {
  pushStyle();

  if (!isWireframe) {
    pushMatrix();
    translate(0, 1, 0);
    rotateX(HALF_PI);

    int tileSize = 50;

    if (groundTex != null) {
      setMaterial(255, 255, 255, 0);
      beginShape(QUADS);
      texture(groundTex);
      for (int x = -5000; x < 5000; x += tileSize) {
        for (int y = -5000; y < 5000; y += tileSize) {
          vertex(x, y, 0, 0);
          vertex(x + tileSize, y, groundTex.width, 0);
          vertex(x + tileSize, y + tileSize, groundTex.width, groundTex.height);
          vertex(x, y + tileSize, 0, groundTex.height);
        }
      }
      endShape();
    } else {
      setMaterial(70, 70, 70, 0);
      beginShape(QUADS);
      for (int x = -5000; x < 5000; x += tileSize) {
        for (int y = -5000; y < 5000; y += tileSize) {
          vertex(x, y, 0);
          vertex(x + tileSize, y, 0);
          vertex(x + tileSize, y + tileSize, 0);
          vertex(x, y + tileSize, 0);
        }
      }
      endShape();
    }
    popMatrix();
  }

  pushMatrix();
  translate(-300, -30, 200);
  rotateY(animBeacon / 2);
  setMaterial(100, 200, 100, matPreset);
  box(60);
  popMatrix();

  if (importedModel != null && !isWireframe) {
    pushMatrix();
    translate(300, 0, 200);
    rotateX(PI);
    scale(50);
    shape(importedModel);
    popMatrix();
  }
  if (isDebug) {
    stroke(150);
    for (int i = -5000; i <= 5000; i += 50) {
      line(i, 0, -5000, i, 0, 5000);
      line(-5000, 0, i, 5000, 0, i);
    }
    strokeWeight(2);
    stroke(255, 0, 0); line(0, 0, 0, 2000, 0, 0);
    stroke(0, 255, 0); line(0, 0, 0, 0, -2000, 0);
    stroke(0, 0, 255); line(0, 0, 0, 0, 0, 2000);
    strokeWeight(1);
  }
  popStyle();
}

void drawHUD() {
  fill(0, 150); noStroke(); rect(10, 10, 320, 495);

  fill(255); textSize(14);
  text("SHADING: " + shadingName(), 20, 30);
  text("PRESET ŚWIATŁA: " + (lightPreset == 0 ? "DZIEŃ" : "NOC") + "  [" + (isLightsOn ? "ON" : "OFF") + "]", 20, 50);
  text("KAMERA: " + (cameraMode == 0 ? "ORBIT" : "Z POJAZDU"), 20, 70);
  text("MISJA: " + collectedCount + " / " + NUM_COLLECTIBLES, 20, 90);

  if (missionComplete) {
    fill(0, 255, 0);
    textSize(20);
    text("Misja ukończona !", 20, 120);
    fill(255);
    textSize(14);
  }

  fill(255);
  text("--- USTAWIENIA ---", 20, 150);
  text("[F] Shading: FLAT / GOURAUD / PHONG", 20, 170);
  text("[1] Render: " + (isWireframe ? "WIREFRAME" : "SOLID"), 20, 190);
  text("[2] Projekcja: " + (isOrtho ? "ORTHO" : "PERSPECTIVE"), 20, 210);
  text("[3] Debug: " + (isDebug ? "ON" : "OFF"), 20, 230);
  text("[4] Transform chwytaka: " + (isTR ? "T*R" : "R*T"), 20, 250);
  text("[O] Światła: " + (isLightsOn ? "WŁĄCZONE" : "WYŁĄCZONE"), 20, 270);
  text("[P] Preset Oświetlenia (DZIEŃ/NOC)", 20, 290);
  text("[M] Materiał Łazika: " + (matPreset == 0 ? "MATOWY" : (matPreset == 1 ? "METALICZNY" : "EMISSIVE")), 20, 310);

  fill(200);
  text("--- STEROWANIE ---", 20, 335);
  text("W/S : Jazda przód/tył", 20, 355);
  text("A/D : Skręt", 20, 375);
  text("Q/E : Obrót wieżyczki", 20, 395);
  text("I/K : Ramię górne", 20, 415);
  text("J/L : Ramię dolne", 20, 435);
  text("Z/X : Chwytak", 20, 455);
  text("SPACE : Strzał sondy", 20, 475);
  text("C : Zmiana kamery | R : Reset", 20, 495);
}

String shadingName() {
  if (isWireframe) return "WIREFRAME";
  if (shadingMode == 0) return "FLAT";
  if (shadingMode == 1) return "GOURAUD";
  return "PHONG";
}

void keyPressed() {
  if (key == '1') isWireframe = !isWireframe;
  if (key == '2') isOrtho = !isOrtho;
  if (key == '3') isDebug = !isDebug;
  if (key == '4') isTR = !isTR;
  if (key == 'o' || key == 'O') isLightsOn = !isLightsOn;
  if (key == 'p' || key == 'P') lightPreset = (lightPreset + 1) % 2;
  if (key == 'm' || key == 'M') matPreset = (matPreset + 1) % 3;
  if (key == 'f' || key == 'F') shadingMode = (shadingMode + 1) % 3;
  if (key == 'c' || key == 'C') cameraMode = (cameraMode + 1) % 2;

  if (key == 'r' || key == 'R') {
    cam.reset();
    turretAngle = 0;
    arm1Angle = radians(-30);
    arm2Angle = radians(-60);
    gripperSpread = 10;
    roverX = 0;
    roverZ = 0;
    roverHeading = 0;
    roverSpeed = 0;
    initObstacles();
    initCollectibles();
  }

  // Movement keys (continuous, handled via keyReleased too)
  if (key == 'w' || key == 'W') keyPressedW = true;
  if (key == 's' || key == 'S') keyPressedS = true;
  if (key == 'a' || key == 'A') keyPressedA = true;
  if (key == 'd' || key == 'D') keyPressedD = true;

  // Turret rotation
  float step = 0.05;
  if (key == 'q' || key == 'Q') turretAngle -= step;
  if (key == 'e' || key == 'E') turretAngle += step;

  // Arm joints
  if (key == 'i' || key == 'I') arm1Angle -= step;
  if (key == 'k' || key == 'K') arm1Angle += step;
  if (key == 'j' || key == 'J') arm2Angle -= step;
  if (key == 'l' || key == 'L') arm2Angle += step;

  // SPACE: fire probe
  if (key == ' ') fireProbe();

  // Gripper spread
  if (key == 'z' || key == 'Z') gripperSpread = max(2, gripperSpread - 2);
  if (key == 'x' || key == 'X') gripperSpread = min(20, gripperSpread + 2);
}

void keyReleased() {
  if (key == 'w' || key == 'W') keyPressedW = false;
  if (key == 's' || key == 'S') keyPressedS = false;
  if (key == 'a' || key == 'A') keyPressedA = false;
  if (key == 'd' || key == 'D') keyPressedD = false;
}
