void applyLighting() {
  if (!isLightsOn) {
    ambientLight(10, 10, 10);
    return;
  }
  
  // KROK 3: Naprawa globalnego speculara!
  // W Processingu domyślny lightSpecular wynosi 0, co uniemożliwiało rysowanie błysków
  // na powierzchniach. Ta jedna linijka sprawia, że światło zacznie rzucać białe odblaski.
  lightSpecular(255, 255, 255);

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
        resetShader(); // BYPASS
        
        boolean tempState = isCustomShaderActive;
        isCustomShaderActive = false;
        
        setMaterial((int)intensity, 0, 0, 2);
        noStroke();
        sphere(5);
        
        isCustomShaderActive = tempState;
        if (isCustomShaderActive && shadingMode == 1) {
          shader(flatShader);
        }
      } else {
        stroke(255, 0, 0);
        noFill();
        sphere(5);
      }
      popMatrix();
    }
  }
}

void setMaterial(int r, int g, int b, int type) {
  if (isWireframe) return;
  fill(r, g, b);

  float ambR = 0, ambG = 0, ambB = 0;
  float specR = 0, specG = 0, specB = 0;
  float shine = 1;
  float emiR = 0, emiG = 0, emiB = 0;

  if (type == 0) { // MATOWY
    ambR = r/2.0; ambG = g/2.0; ambB = b/2.0;
    specR = 20; specG = 20; specB = 20;
    shine = 2;
  } else if (type == 1) { // BŁYSZCZĄCY METAL
    ambR = r/3.0; ambG = g/3.0; ambB = b/3.0;
    specR = 255; specG = 255; specB = 255;
    shine = 80;
  } else if (type == 2) { // EMISSIVE
    emiR = r; emiG = g; emiB = b;
  }

  if (isCustomShaderActive) {
    if (shadingMode == 1 && flatShader != null) {
      // KROK 2: Ręczne forsowanie danych (Manual Uniform Binding)
      // Usunęliśmy nieużywaną zmienną myDiffuse.
      // Pozostałe parametry przeliczamy na ułamki 0.0 - 1.0 i dodajemy `1.0` na końcu, 
      // aby poprawnie zbudować obiekt typu `vec4`, którego wymaga plik .glsl!
      flatShader.set("myAmbient", ambR/255.0, ambG/255.0, ambB/255.0, 1.0);
      flatShader.set("mySpecular", specR/255.0, specG/255.0, specB/255.0, 1.0);
      flatShader.set("myShininess", shine);
      flatShader.set("myEmissive", emiR/255.0, emiG/255.0, emiB/255.0, 1.0);
    }
  } else {
    ambient(ambR, ambG, ambB);
    specular(specR, specG, specB);
    shininess(shine);
    emissive(emiR, emiG, emiB);
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
      // --- BYPASS DLA TEKSTURY PODŁOGI ---
      // Wyłączamy shader na ułamek sekundy, aby nie gryzł się z teksturą!
      boolean tempState = isCustomShaderActive;
      if (isCustomShaderActive) {
        resetShader();
        isCustomShaderActive = false;
      }
      
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
      
      // --- PRZYWRACAMY SHADER DLA RESZTY SCENY (pachołki, modele) ---
      isCustomShaderActive = tempState;
      if (isCustomShaderActive && shadingMode == 1) {
        shader(flatShader);
      }
    }
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
  fill(0, 180); noStroke(); 
  rect(10, 10, 480, 410); 
  
  fill(255); textSize(14);
  text("STEROWANIE I STATUS:", 25, 35);
  
  text("[1] Tryb renderowania: " + (isWireframe ? "WIREFRAME" : "SOLID"), 25, 60);
  text("[2] Rzutowanie kamery: " + (isOrtho ? "ORTHO" : "PERSPECTIVE"), 25, 82);
  text("[3] Debug: " + (isDebug ? "ON" : "OFF"), 25, 104);
  
  fill(isTR ? 255 : color(255, 100, 100));
  text("[4] Transformacja chwytaka: " + (isTR ? "T*R" : "R*T"), 25, 126); 
  text("[F] Shading: " + (shadingMode == 0 ? "DOMYŚLNY" : "FLAT"), 25, 148); 
  text("[C] Kamera: " + (cameraMode == 0 ? "ORBITALNA" : "CHASE"), 25, 170);
  text("[L] System świateł: " + (isLightsOn ? "WŁĄCZONE" : "WYŁĄCZONE"), 25, 192);
  text("[P] Oświetlenie: " + (lightPreset == 0 ? "DZIEŃ" : "NOC"), 25, 214);
  text("[M] Materiał: " + (matPreset == 0 ? "MATOWY" : (matPreset == 1 ? "METALICZNY" : "EMISSIVE")), 25, 236);
  
  fill(200); 
  text("W/A/S/D : Poruszanie", 25, 264);
  text("Q / E : Obrót wieżyczki", 25, 286);
  text("I / K : Górne Ramię", 25, 308);
  text("J / L : Dolne Ramię", 25, 330);
  text("Z / X : Chwytak", 25, 352);
  text("SPACJA: Strzał", 25, 374);
  text("R : Reset", 25, 396);

  fill(0, 200); rect(width/2 - 150, 20, 300, 60, 10);
  fill(255, 255, 0); textSize(20); textAlign(CENTER);
  text("Zebrano znaczników: " + collectedCount + " / " + NUM_COLLECTIBLES, width/2, 58);
  textAlign(LEFT);

  if (missionComplete) {
    fill(0, 150); rect(0, 0, width, height);
    fill(0, 255, 0); textSize(60); textAlign(CENTER);
    text("MISJA UKOŃCZONA", width/2, height/2);
    textSize(20);
    text("Kliknij R aby zresetować", width/2, height/2 + 50);
    textAlign(LEFT);
  }
}

void keyPressed() {
  if (key == '1') isWireframe = !isWireframe;
  if (key == '2') isOrtho = !isOrtho;
  if (key == '3') isDebug = !isDebug;
  if (key == '4') isTR = !isTR;
  if (key == 'f' || key == 'F') shadingMode = (shadingMode + 1) % 2;
  if (key == 'c' || key == 'C') cameraMode = (cameraMode + 1) % 2;
  
  if (key == 'l' || key == 'L') isLightsOn = !isLightsOn;
  if (key == 'p' || key == 'P') lightPreset = (lightPreset + 1) % 2;
  if (key == 'm' || key == 'M') matPreset = (matPreset + 1) % 3;
  if (key == ' ') fireProbe(); 
  
  if (key == 'r' || key == 'R') { 
    cam.reset();
    cam.setRotations(-0.5, PI, 0);
    turretAngle = 0; arm1Angle = radians(-30); arm2Angle = radians(-60); gripperSpread = 10;
    roverX = 0; roverZ = 0; roverHeading = 0; roverSpeed = 0;
    collectedCount = 0; missionComplete = false;
    for(int i=0; i<NUM_COLLECTIBLES; i++) {
      colCollected[i] = false;
    }
  }
  
  if (key == 'w' || key == 'W') keyPressedW = true;
  if (key == 's' || key == 'S') keyPressedS = true;
  if (key == 'a' || key == 'A') keyPressedA = true;
  if (key == 'd' || key == 'D') keyPressedD = true;
  
  float step = 0.2;
  if (key == 'q' || key == 'Q') turretAngle -= step;
  if (key == 'e' || key == 'E') turretAngle += step;
  if (key == 'i' || key == 'I') arm1Angle -= step;
  if (key == 'k' || key == 'K') arm1Angle += step;
  if (key == 'j' || key == 'J') arm2Angle -= step;
  if (key == 'l' || key == 'L') arm2Angle += step;
  if (key == 'z' || key == 'Z') gripperSpread = max(2, gripperSpread - 2);
  if (key == 'x' || key == 'X') gripperSpread = min(20, gripperSpread + 2);
}

void keyReleased() {
  if (key == 'w' || key == 'W') keyPressedW = false;
  if (key == 's' || key == 'S') keyPressedS = false;
  if (key == 'a' || key == 'A') keyPressedA = false;
  if (key == 'd' || key == 'D') keyPressedD = false;
}
