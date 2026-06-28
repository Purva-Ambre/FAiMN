#include <SPI.h>
#include <LoRa.h>
#include <Adafruit_MAX31865.h>
#include <Wire.h>
#include <Adafruit_ADXL345_U.h>
#include <DFRobotDFPlayerMini.h>
#include <math.h>

// ==== USER CONFIG / PINS ====
#define RNOMINAL 100.0
#define RREF     430.0

constexpr int MQ2_PIN = 35;
constexpr int MQ7_PIN = 34;
constexpr int DIP1_PIN = 32;
constexpr int DIP2_PIN = 33;

constexpr int LORA_SS  = 15;
constexpr int LORA_RST = 14;
constexpr int LORA_DIO0 = 26;

constexpr int MAX1_CS = 5;  // Body temp
constexpr int MAX2_CS = 4;  // Ambient temp

constexpr int DF_RX = 16;
constexpr int DF_TX = 17;

// ==== OBJECTS ====
Adafruit_MAX31865 maxMain(MAX1_CS);
Adafruit_MAX31865 maxAmbient(MAX2_CS);
Adafruit_ADXL345_Unified accel(12345);
DFRobotDFPlayerMini dfplayer;
HardwareSerial dfSerial(2);

// ==== STATE ====
int packetCounter = 0;
bool accelPresent = false;
bool dfPresent = false;

// Timers per alert type
unsigned long lastMQ2Warn = 0, lastMQ2Alert = 0;
unsigned long lastMQ7Warn = 0, lastMQ7Alert = 0;
unsigned long lastAmbientColdWarn = 0, lastAmbientColdAlert = 0, lastAmbientHotWarn = 0, lastAmbientHotAlert = 0;
unsigned long lastBodyColdWarn = 0, lastBodyColdAlert = 0, lastBodyHotWarn = 0, lastBodyHotAlert = 0;
unsigned long lastAccelTry = 0, lastDFTry = 0;
unsigned long lastMovement = 0;

// Baselines
int baseMQ2 = 0, baseMQ7 = 0;
float baseTempMain = NAN, baseTempAmbient = NAN;

// Constants
constexpr int baselineSamples = 200;
constexpr int sampleDelayMs = 200;
constexpr unsigned long retryInterval = 60000; // 1 min retry
constexpr int inactivityTimeLimit = 5000;

// ADXL thresholds
constexpr float HIGH_THRESHOLD = 15.0;
constexpr float LOW_THRESHOLD  = 3.0;

bool fallDetected = false;
bool inactivityDetected = false;

// ==== HELPER FUNCTIONS ====
void safePlay(uint16_t track) {
    if (dfPresent) {
        dfplayer.play(track);
        delay(100); // allow playback start
    }
}

void tryInitDFPlayer() {
    if (dfPresent) return;
    Serial.println("Trying DFPlayer init...");
    dfSerial.begin(9600, SERIAL_8N1, DF_RX, DF_TX);
    if (dfplayer.begin(dfSerial)) {
        dfPresent = true;
        dfplayer.volume(30);
        dfplayer.EQ(DFPLAYER_EQ_NORMAL);
        Serial.println("✅ DFPlayer ready.");
    } else {
        Serial.println("❌ DFPlayer not found. Retrying later.");
        lastDFTry = millis();
    }
}

void tryInitAccel() {
    if (accelPresent) return;
    Serial.println("Trying ADXL345 init...");
    if (accel.begin()) {
        accelPresent = true;
        Serial.println("✅ ADXL345 detected.");
    } else {
        Serial.println("❌ ADXL345 not detected. Retrying later.");
        lastAccelTry = millis();
    }
}

// ==== CALIBRATION ====
void calibrateBaseline() {
    long sum2 = 0, sum7 = 0;
    float sumMain = 0, sumAmbient = 0;
    int tempSamples = 0;

    Serial.println("Warming up sensors for 20 seconds...");
    delay(20000);

    Serial.println("Calibrating baselines...");
    for (int i = 0; i < baselineSamples; i++) {
        sum2 += analogRead(MQ2_PIN);
        sum7 += analogRead(MQ7_PIN);

        float tMain = maxMain.temperature(RNOMINAL, RREF);
        float tAmbient = maxAmbient.temperature(RNOMINAL, RREF);

        if (!isnan(tMain)) { sumMain += tMain; tempSamples++; }
        if (!isnan(tAmbient)) { sumAmbient += tAmbient; }

        delay(sampleDelayMs);
    }

    baseMQ2 = sum2 / baselineSamples;
    baseMQ7 = sum7 / baselineSamples;
    if (tempSamples > 0) baseTempMain = sumMain / tempSamples;
    baseTempAmbient = sumAmbient / baselineSamples;

    Serial.println("=== BASELINES ===");
    Serial.printf("MQ2: %d | MQ7: %d\n", baseMQ2, baseMQ7);
    Serial.printf("Body Temp: %.2f °C | Ambient Temp: %.2f °C\n", baseTempMain, baseTempAmbient);

    if (dfPresent) {
        dfplayer.play(10);  // calibration complete tone
        delay(2000);
        dfplayer.play(1);   // System started voice
    }
}

// ==== SETUP ====
void setup() {
    Serial.begin(115200);
    delay(100);

    pinMode(DIP1_PIN, INPUT_PULLUP);
    pinMode(DIP2_PIN, INPUT_PULLUP);

    maxMain.begin(MAX31865_2WIRE);
    maxAmbient.begin(MAX31865_2WIRE);

    tryInitAccel();
    tryInitDFPlayer();

    // LoRa setup
    SPI.begin(18, 19, 23, LORA_SS);
    LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
    Serial.println("Initializing LoRa...");
    if (!LoRa.begin(433E6)) {
        Serial.println("❌ LoRa init failed. Halting.");
        while (1);
    }
    Serial.println("✅ LoRa initialized.");

    calibrateBaseline();

    lastMovement = millis();
    lastAccelTry = millis();
    lastDFTry = millis();

    Serial.println("Setup complete.");
}

// ==== LOOP ====
void loop() {
    unsigned long now = millis();

    // Retry initializations
    if (!accelPresent && now - lastAccelTry >= retryInterval) tryInitAccel();
    if (!dfPresent && now - lastDFTry >= retryInterval) tryInitDFPlayer();

    // Unique ID from DIP switches
    int id = ((digitalRead(DIP1_PIN) == LOW) << 1) | (digitalRead(DIP2_PIN) == LOW);

    // ==== SENSOR READINGS ====
    float tempMain = maxMain.temperature(RNOMINAL, RREF);
    float tempAmbient = maxAmbient.temperature(RNOMINAL, RREF);
    int mq2 = analogRead(MQ2_PIN);
    int mq7 = analogRead(MQ7_PIN);

    int mq2Delta = mq2 - baseMQ2;
    int mq7Delta = mq7 - baseMQ7;
    float tempMainDelta = !isnan(tempMain) ? (tempMain - baseTempMain) : NAN;
    float tempAmbientDelta = !isnan(tempAmbient) ? (tempAmbient - baseTempAmbient) : NAN;

    // ==== ACCELEROMETER ====
    float magnitude = 0.0;
    if (accelPresent) {
        sensors_event_t e;
        accel.getEvent(&e);

        float rawMag = sqrt(e.acceleration.x * e.acceleration.x +
                            e.acceleration.y * e.acceleration.y +
                            e.acceleration.z * e.acceleration.z);

        magnitude = fabs(rawMag - 9.8);
        fallDetected = (rawMag > HIGH_THRESHOLD || rawMag < LOW_THRESHOLD);

        inactivityDetected = (magnitude < 0.5 && now - lastMovement > inactivityTimeLimit);
        if (!inactivityDetected) lastMovement = now;
    }

    // ==== LORA JSON ====
    String json = "{";
    json += "\"id\":" + String(id) + ",";
    json += "\"packet\":" + String(packetCounter) + ",";
    json += "\"mq2_delta\":" + String(mq2Delta) + ",";
    json += "\"mq7_delta\":" + String(mq7Delta) + ",";
    json += "\"temp_main\":" + String(tempMain, 2) + ",";
    json += "\"temp_ambient\":" + String(tempAmbient, 2) + ",";
    json += "\"accel\":" + String(magnitude, 2) + ",";
    json += "\"fall\":" + String(fallDetected) + ",";
    json += "\"inactivity\":" + String(inactivityDetected);
    json += "}";

    LoRa.beginPacket();
    LoRa.print(json);
    LoRa.endPacket();
    packetCounter++;

    // ==== DEBUG ====
    Serial.println("---- SENSOR DATA ----");
    Serial.printf("ID: %d | Packet: %d\n", id, packetCounter);
    Serial.printf("MQ2: %d (Δ%d) | MQ7: %d (Δ%d)\n", mq2, mq2Delta, mq7, mq7Delta);
    Serial.printf("Body Temp: %.2f (Δ%.2f) | Ambient Temp: %.2f (Δ%.2f)\n",
                  tempMain, tempMainDelta, tempAmbient, tempAmbientDelta);
    if (accelPresent) {
        Serial.printf("Accel: %.2f m/s²\n", magnitude);
        if (fallDetected) Serial.println("⚠ FALL DETECTED!");
        if (inactivityDetected) Serial.println("⚠ INACTIVITY DETECTED!");
    } else {
        Serial.println("Accel: not present");
    }
    Serial.printf("DFPlayer: %s\n", dfPresent ? "present" : "not present");
    Serial.println("----------------------");

    // ==== ALERT LOGIC ====
    // MQ2 GAS (Smoke)
    if (mq2Delta >= 200 && mq2Delta < 1000 && now - lastMQ2Warn >= 300000) {
        safePlay(11); Serial.println("-> MQ2 Gas Warning (Track 11)"); lastMQ2Warn = now;
    } else if (mq2Delta >= 1000 && now - lastMQ2Alert >= 60000) {
        safePlay(12); Serial.println("-> MQ2 Gas Alert (Track 12)"); lastMQ2Alert = now;
    }

    // MQ7 GAS (CO)
    if (mq7Delta >= 100 && mq7Delta < 500 && now - lastMQ7Warn >= 300000) {
        safePlay(13); Serial.println("-> MQ7 CO Warning (Track 13)"); lastMQ7Warn = now;
    } else if (mq7Delta >= 500 && now - lastMQ7Alert >= 60000) {
        safePlay(14); Serial.println("-> MQ7 CO Alert (Track 14)"); lastMQ7Alert = now;
    }

    // AMBIENT TEMPERATURE
    if (!isnan(tempAmbient)) {
        if (tempAmbient <= 10 && tempAmbient > 0 && now - lastAmbientColdWarn >= 300000) {
            safePlay(4); Serial.println("-> Ambient Cold Warning (Track 4)"); lastAmbientColdWarn = now;
        } else if (tempAmbient <= 0 && now - lastAmbientColdAlert >= 60000) {
            safePlay(5); Serial.println("-> Ambient TOO Cold Alert (Track 5)"); lastAmbientColdAlert = now;
        } else if (tempAmbient >= 25 && tempAmbient < 40 && now - lastAmbientHotWarn >= 300000) {
            safePlay(2); Serial.println("-> Ambient Hot Warning (Track 2)"); lastAmbientHotWarn = now;
        } else if (tempAmbient >= 40 && now - lastAmbientHotAlert >= 60000) {
            safePlay(3); Serial.println("-> Ambient TOO Hot Alert (Track 3)"); lastAmbientHotAlert = now;
        }
    }

    // BODY TEMPERATURE
    if (!isnan(tempMain)) {
        if (tempMain <= 10 && tempMain > 0 && now - lastBodyColdWarn >= 300000) {
            safePlay(8); Serial.println("-> Body Cold Warning (Track 8)"); lastBodyColdWarn = now;
        } else if (tempMain <= 0 && now - lastBodyColdAlert >= 60000) {
            safePlay(9); Serial.println("-> Body TOO Cold Alert (Track 9)"); lastBodyColdAlert = now;
        } else if (tempMain >= 25 && tempMain < 40 && now - lastBodyHotWarn >= 300000) {
            safePlay(6); Serial.println("-> Body Hot Warning (Track 6)"); lastBodyHotWarn = now;
        } else if (tempMain >= 40 && now - lastBodyHotAlert >= 60000) {
            safePlay(7); Serial.println("-> Body TOO Hot Alert (Track 7)"); lastBodyHotAlert = now;
        }
    }

    delay(6000);
}
