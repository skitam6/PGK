void drawRover() {
  float bodyW = 150, bodyH = 50, bodyD = 300;
  float wheelR = 30;
  float turretW = 70, turretH = 50, turretD = 150;
  float arm1L = 80, arm2L = 60, armW = 15;

  pushMatrix();
  translate(0, -wheelR, 0);
  
  pushMatrix();
  setMaterial(255, 200, 0, matPreset);
  translate(0, -bodyH/2, 0); 
  box(bodyW, bodyH, bodyD);
  popMatrix();

  drawWheel(-bodyW/2, 0, bodyD/3, wheelR);
  drawWheel(bodyW/2, 0, bodyD/3, wheelR);    
  drawWheel(-bodyW/2, 0, -bodyD/3, wheelR);  
  drawWheel(bodyW/2, 0, -bodyD/3, wheelR);   

  pushMatrix();
  translate(0, -bodyH, 0);     
  rotateY(turretAngle);

  setMaterial(0, 100, 255, matPreset); 
  translate(0, -turretH/2, 0); 
  box(turretW, turretH, turretD);
  
    pushMatrix();
    translate(0, -turretH/2, 0); 
    rotateZ(arm1Angle);          
    
    translate(0, -arm1L/2, 0);   
    box(armW, arm1L, armW);
    
      pushMatrix();
      translate(0, -arm1L/2, 0); 
      rotateZ(arm2Angle);        
      
      translate(0, -arm2L/2, 0);
      box(armW, arm2L, armW);
      
        drawGripper(arm2L, armW);
        
      popMatrix(); 
    popMatrix(); 
  popMatrix(); 
  popMatrix(); 
}

void drawWheel(float x, float y, float z, float r) {
  pushMatrix();
  translate(x, y, z);
  rotateX(-wheelSpin); 
  
  scale(0.5, 1.0, 1.0); 
  if (!isWireframe) {
    noStroke(); 
    setMaterial(30, 30, 30, 0);   
  }
  sphere(r);
  popMatrix();
}

void drawGripper(float arm2L, float armW) {
  pushMatrix();
  translate(0, -arm2L/2, 0);
  
  float lightY = -armW * 0.8; 
  
  if (isLightsOn && lightPreset == 1) {
    if (!isWireframe) {
      spotLight(255, 255, 255, 0, lightY, 0, 0, -1, 0, PI/3, 2);
    }
    
    if (isDebug) {
      pushMatrix();
      translate(0, lightY, 0); 
      if (!isWireframe) {
        resetShader(); // BYPASS
        
        boolean tempState = isCustomShaderActive;
        isCustomShaderActive = false;
        
        setMaterial(255, 255, 255, 2);
        sphere(4);
        
        // NAPRAWIONE PRZYWRÓCENIE SHADERA
        isCustomShaderActive = tempState;
        if (isCustomShaderActive && shadingMode == 1) {
          shader(flatShader);
        }
      } else {
        stroke(255); 
        noFill();
        sphere(4);
      }
      popMatrix();
    }
  }

  setMaterial(255, 120, 0, matPreset);
  box(armW * 3, armW, armW); 
  
  pushMatrix();
  translate(-gripperSpread, -armW*1.5, 0);
  box(armW/2, armW*2, armW);
  popMatrix();
  
  pushMatrix();
  if (isTR) {
    translate(gripperSpread, -armW*1.5, 0);
    rotateZ(0); setMaterial(255, 120, 0, matPreset);
  } else {
    rotateZ(QUARTER_PI);
    translate(gripperSpread, -armW*1.5, 0); setMaterial(255, 0, 0, matPreset);
  } 
  box(armW/2, armW*2, armW);
  popMatrix();
  
  popMatrix();
}
