// Receives "T:<0..1023>\n" over Bluetooth and drives BLDC ESC on D9.

#include <SoftwareSerial.h>
#include <Servo.h>

const uint8_t BT_RX = 10;   // Uno listens here (from BT TXD)
const uint8_t BT_TX = 11;   // Uno sends here (to BT RXD)
SoftwareSerial BT(BT_RX, BT_TX);

const uint8_t PIN_ESC  = 9;   // ESC PWM (servo pulse)
const uint8_t PIN_KILL = 4;   // safety kill switch

Servo esc;

/* ---------- ESC pulse config (µs) ---------- */
int PULSE_MIN = 1000;   // ESC absolute minimum
int PULSE_MAX = 2000;   // ESC absolute maximum
int PULSE_NEU = 1000;   // neutral/idle (1500 when ESC expects mid-stick idle)

/* --------- Mapping & smoothing ------------- */
const int JOY_MIN = 30;     // joystick deadzone start (0..1023)
const int JOY_MAX = 1023;   // joystick max
const int RAMP_US_PER_LOOP = 8;     // slew rate limit (µs per loop)
const unsigned long LOOP_DT_MS = 10;

/* ---------------- Failsafe ----------------- */
const unsigned long FS_TIMEOUT_MS = 300;   // no packet -> neutral after 0.3 s

/* ----------------- State ------------------- */
int currentPulse = PULSE_NEU;
unsigned long lastPktMs = 0;

/* --------------- Helpers ------------------- */
int clampi(int v, int lo, int hi) { return v<lo?lo:(v>hi?hi:v); }

int mapJoyToPulse(int joy) {
  if (joy < JOY_MIN) return PULSE_NEU;          
  long p = map(joy, JOY_MIN, JOY_MAX, PULSE_NEU, PULSE_MAX);
  return clampi((int)p, PULSE_NEU, PULSE_MAX);
}

int slew(int cur, int tgt, int step){
  if (tgt > cur) return min(cur + step, tgt);
  if (tgt < cur) return max(cur - step, tgt);
  return cur;
}

/* ----- parse packets "T:<num>\n" from BT ---- */
bool readThrottlePacket(int &valueOut){
  static String buf;
  while (BT.available()) {
    char c = (char)BT.read();
    if (c == '\n' || c == '\r') {
      if (buf.startsWith("T:")) {
        int v = buf.substring(2).toInt();
        buf = "";
        if (v >= 0 && v <= 1023) { valueOut = v; return true; }
      }
      buf = "";
    } else {
      if (buf.length() < 16) buf += c;    // protect against runaway
    }
  }
  return false;
}

void setup() {
  pinMode(PIN_KILL, INPUT_PULLUP);
  BT.begin(9600);
  Serial.begin(115200);
  delay(200);

  esc.attach(PIN_ESC, 1000, 2000);
  esc.writeMicroseconds(PULSE_NEU);
  currentPulse = PULSE_NEU;

  // Arm ESC by holding neutral for ~2 s
  Serial.println("Arming ESC...");
  for (int i=0;i<100;i++){ esc.writeMicroseconds(PULSE_NEU); delay(20); }
  lastPktMs = millis();
  Serial.println("Ready.");
}

void loop() {
  int targetPulse = PULSE_NEU;

  // Read joystick packet if available
  int joy;
  if (readThrottlePacket(joy)) {
    lastPktMs = millis();
    targetPulse = mapJoyToPulse(joy);
  }

  // Kill switch → neutral
  if (digitalRead(PIN_KILL) == LOW) targetPulse = PULSE_NEU;

  // Failsafe timeout → neutral
  if (millis() - lastPktMs > FS_TIMEOUT_MS) targetPulse = PULSE_NEU;

  // Smooth ramp to target
  currentPulse = slew(currentPulse, targetPulse, RAMP_US_PER_LOOP);
  esc.writeMicroseconds(currentPulse);

  // Debug every 200 ms
  static unsigned long tdbg=0;
  if (millis() - tdbg > 200) {
    tdbg = millis();
    Serial.print("pulse="); Serial.print(currentPulse);
    Serial.print("  pkt_age(ms)="); Serial.print(millis()-lastPktMs);
    Serial.print("  kill="); Serial.println(digitalRead(PIN_KILL)==LOW);
  }

  delay(LOOP_DT_MS);
}
