// Sends throttle as ASCII packets: "T:<0..1023>\n" at ~20 Hz

#include <SoftwareSerial.h>

const uint8_t BT_RX = 8;   // Nano listens (from BT TXD)
const uint8_t BT_TX = 7;   // Nano sends (to BT RXD)
SoftwareSerial BT(BT_RX, BT_TX);

const uint8_t PIN_JOY  = A0;
const uint8_t PIN_DEAD = 2;     // deadman

const unsigned long TX_PERIOD_MS = 50;  // 20 Hz

int lp(int prev, int raw, float a=0.25f){ return (int)(a*raw + (1-a)*prev); }

void setup() {
  pinMode(PIN_DEAD, INPUT_PULLUP);
  BT.begin(9600);
  Serial.begin(115200);
  delay(200);
  Serial.println("TX ready");
}

void loop() {
  static unsigned long t0 = 0;
  static int filt = 0;

  if (millis() - t0 >= TX_PERIOD_MS) {
    t0 = millis();

    int raw = analogRead(PIN_JOY);   // 0..1023
    filt = lp(filt, raw);

    // Deadman pressed -> force zero throttle
    if (digitalRead(PIN_DEAD) == LOW) filt = 0;

    BT.print("T:");
    BT.println(filt);
    Serial.println(filt);
  }
}
