/*
  Example Quadruped Gait Prototype — forward "tripod" motion (FL+RR then FR+RL)

  LEG JOINTS (per leg)
  - Coxa  : hip swing (forward/back)
  - Femur : hip lift (up/down)
  - Tibia : knee (extend/flex)

  This was a prototype code, no controls, only meant to gait motion the quadruped forward
*/

#include <Servo.h>

const uint8_t COXA_PIN [4] = {22, 25, 28, 31};
const uint8_t FEMUR_PIN[4] = {23, 26, 29, 32};
const uint8_t TIBIA_PIN[4] = {24, 27, 30, 33};

// Arm: 5 micro-servos
const uint8_t ARM_PIN[5] = {34, 35, 36, 37, 38};

// ---------------- Neutral angles & limits ----------------
// Defined my mechanical neutral (standing) angles for each joint in degrees.
// Calibrated with all legs reasonably centered and tweaked until it looks symmetrical visually.

int COXA_NEUTRAL [4] = {100, 100, 50, 45};  // hip swing center
int FEMUR_NEUTRAL[4] = {156, 122, 100, 85};  // hip lift center
int TIBIA_NEUTRAL[4] = {90, 90, 90, 90};  // knee center

// Travel magnitudes for gait (how much to swing & lift)
const int COXA_SWING_FWD  = 18;  // forward swing from neutral
const int COXA_SWING_BACK = 18;  // backward swing from neutral
const int FEMUR_LIFT      = 18;  // how high to lift during swing
const int TIBIA_LIFT      = 12;  // knee tuck during swing

// Motion smoothing (bigger = faster)
const int STEP_MS      = 12;   // delay per micro-step
const int STEP_DEG     = 2;    // degrees per micro-step

// Stance timing
const int HOLD_AT_END_MS = 80; // pause at end of each half step

// ---------------- Servo objects ----------------
Servo coxa[4], femur[4], tibia[4];
Servo arm[5];

int clampDeg(int v){ return v < 0 ? 0 : (v > 180 ? 180 : v); }

// set a single joint with clamped angle
void writeJoint(Servo &s, int deg){
  s.write(clampDeg(deg));
}

// set all three joints of one leg
void setLegAngles(uint8_t leg, int aCoxa, int aFemur, int aTibia){
  writeJoint(coxa[leg],  aCoxa);
  writeJoint(femur[leg], aFemur);
  writeJoint(tibia[leg], aTibia);
}

// smooth move of one joint toward target
void moveJointToward(Servo &s, int &current, int target){
  if (current < target) current = min(current + STEP_DEG, target);
  else if (current > target) current = max(current - STEP_DEG, target);
  s.write(clampDeg(current));
}

// smooth move of an entire leg to target triplet
void moveLegTo(uint8_t leg, int coxaTarget, int femurTarget, int tibiaTarget){
  int c = coxa[leg].read();
  int f = femur[leg].read();
  int t = tibia[leg].read();
  bool done = false;
  while (!done){
    int beforeC=c, beforeF=f, beforeT=t;
    moveJointToward(coxa[leg],  c, coxaTarget);
    moveJointToward(femur[leg], f, femurTarget);
    moveJointToward(tibia[leg], t, tibiaTarget);
    delay(STEP_MS);
    done = (c==beforeC && f==beforeF && t==beforeT); // reached targets
  }
}

// Neutral standing pose
void standNeutral(){
  for (int i=0;i<4;i++) setLegAngles(i, COXA_NEUTRAL[i], FEMUR_NEUTRAL[i], TIBIA_NEUTRAL[i]);
}

// Arm default pose
void armNeutral(){
  for (int i=0;i<5;i++) arm[i].write(90);
}

// ---------------- Gait primitives ----------------
// For a simple forward gait:
// Groups (tripod style): A = FL(0) + RR(3), B = FR(1) + RL(2)

void swingLegForward(uint8_t leg){
  // Lift, swing forward, drop
  moveLegTo(leg,
            COXA_NEUTRAL[leg],                   // prep
            FEMUR_NEUTRAL[leg] - FEMUR_LIFT,
            TIBIA_NEUTRAL[leg]  - TIBIA_LIFT);

  moveLegTo(leg,
            COXA_NEUTRAL[leg] + COXA_SWING_FWD,  // swing
            FEMUR_NEUTRAL[leg] - FEMUR_LIFT,
            TIBIA_NEUTRAL[leg]  - TIBIA_LIFT);

  moveLegTo(leg,
            COXA_NEUTRAL[leg] + COXA_SWING_FWD,  // set down
            FEMUR_NEUTRAL[leg],
            TIBIA_NEUTRAL[leg]);
}

void pushLegBackward(uint8_t leg){
  // Stance: keep foot on ground, drive coxa backward
  moveLegTo(leg,
            COXA_NEUTRAL[leg] - COXA_SWING_BACK,
            FEMUR_NEUTRAL[leg],
            TIBIA_NEUTRAL[leg]);
}

// synchronize two legs with interleaved stepping
void swingPairForward(uint8_t leg1, uint8_t leg2){
  // Lift both
  moveLegTo(leg1, COXA_NEUTRAL[leg1], FEMUR_NEUTRAL[leg1]-FEMUR_LIFT, TIBIA_NEUTRAL[leg1]-TIBIA_LIFT);
  moveLegTo(leg2, COXA_NEUTRAL[leg2], FEMUR_NEUTRAL[leg2]-FEMUR_LIFT, TIBIA_NEUTRAL[leg2]-TIBIA_LIFT);

  // Swing both forward
  moveLegTo(leg1, COXA_NEUTRAL[leg1]+COXA_SWING_FWD, FEMUR_NEUTRAL[leg1]-FEMUR_LIFT, TIBIA_NEUTRAL[leg1]-TIBIA_LIFT);
  moveLegTo(leg2, COXA_NEUTRAL[leg2]+COXA_SWING_FWD, FEMUR_NEUTRAL[leg2]-FEMUR_LIFT, TIBIA_NEUTRAL[leg2]-TIBIA_LIFT);

  // Drop both
  moveLegTo(leg1, COXA_NEUTRAL[leg1]+COXA_SWING_FWD, FEMUR_NEUTRAL[leg1], TIBIA_NEUTRAL[leg1]);
  moveLegTo(leg2, COXA_NEUTRAL[leg2]+COXA_SWING_FWD, FEMUR_NEUTRAL[leg2], TIBIA_NEUTRAL[leg2]);
}

void pushPairBackward(uint8_t leg1, uint8_t leg2){
  moveLegTo(leg1, COXA_NEUTRAL[leg1]-COXA_SWING_BACK, FEMUR_NEUTRAL[leg1], TIBIA_NEUTRAL[leg1]);
  moveLegTo(leg2, COXA_NEUTRAL[leg2]-COXA_SWING_BACK, FEMUR_NEUTRAL[leg2], TIBIA_NEUTRAL[leg2]);
}

// One full forward step: A swings while B pushes, then swap
void stepForward(){
  // Group A = FL(0) + RR(3) swing forward; Group B = FR(1) + RL(2) push back
  swingPairForward(0, 3);
  pushPairBackward (1, 2);
  delay(HOLD_AT_END_MS);

  // Now set A as stance (back) and swing B forward
  pushPairBackward (0, 3);
  swingPairForward(1, 2);
  delay(HOLD_AT_END_MS);
}

// ---------------- Setup & Loop ----------------
void attachAll(){
  for (int i=0;i<4;i++){
    coxa[i].attach(COXA_PIN[i]);
    femur[i].attach(FEMUR_PIN[i]);
    tibia[i].attach(TIBIA_PIN[i]);
  }
  for (int i=0;i<5;i++) arm[i].attach(ARM_PIN[i]);
}

void setup(){
  attachAll();
  delay(300);
  standNeutral();
  armNeutral();
  delay(600);
}

void loop(){
  stepForward();   // simple continuous forward gait
}
