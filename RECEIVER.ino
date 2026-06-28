#include <SPI.h>
#include <LoRa.h>
#include <math.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>

// ================= WIFI =================
#define WIFI_SSID "your wifi"
#define WIFI_PASSWORD "password"

// ================= FIREBASE =================
#define API_KEY "your firebase api key"
#define DATABASE_URL "your database url"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ================= TIME =================
const char* ntpServer = "time.google.com";
const long gmtOffset_sec = 19800;
const int daylightOffset_sec = 0;

// ================= LORA =================
#define LORA_SS   15
#define LORA_RST  14
#define LORA_DIO0 26

int lastPacketNo = -1;
int totalReceived = 0;
int totalMissed = 0;

// ================= FLOOR =================
float lastAltitude = 0;
bool firstRead = true;

// ================= FALL =================
unsigned long lastLow = 0;
unsigned long lastFallTime = 0;

// ================= NO MOVEMENT =================
float prevMag = 0;
unsigned long lastMovementTime = 0;

// ================= HELPER =================
String getValue(String data, String key) {

  int start = data.indexOf(key);

  if (start == -1)
    return "";

  start += key.length();

  int end = data.indexOf(',', start);

  if (end == -1)
    end = data.length();

  return data.substring(start, end);
}

// ================= DIRECTION =================
String getDirection(int ax, int ay, int az) {

  int threshold = 8000;

  if (az > threshold) return "UP ⬆️";
  if (az < -threshold) return "DOWN ⬇️";

  if (ax > threshold) return "RIGHT ➡️";
  if (ax < -threshold) return "LEFT ⬅️";

  if (ay > threshold) return "FORWARD ⬆️";
  if (ay < -threshold) return "BACKWARD ⬇️";

  return "TILT / MOVING";
}

// ================= FLOOR =================
String getFloorChange(float currentAlt) {

  if (firstRead) {
    lastAltitude = currentAlt;
    firstRead = false;
    return "INIT";
  }

  float diff = currentAlt - lastAltitude;

  if (diff > 3) {
    lastAltitude = currentAlt;
    return "UP ⬆️ FLOOR";
  }

  if (diff < -3) {
    lastAltitude = currentAlt;
    return "DOWN ⬇️ FLOOR";
  }

  return "SAME FLOOR";
}

// ================= FALL =================
String detectFall(float mag) {

  if (mag < 3000) {
    lastLow = millis();
  }

  if (mag > 20000 &&
      (millis() - lastLow < 1000) &&
      (millis() - lastFallTime > 5000)) {

    lastFallTime = millis();

    return "🚨 FALL DETECTED";
  }

  return "NORMAL";
}

// ================= NO MOVEMENT =================
String detectNoMovement(float mag) {

  float diff = abs(mag - prevMag);

  prevMag = mag;

  // Movement detected
  if (diff > 500) {

    lastMovementTime = millis();

    return "MOVING";
  }

  // No movement for 8 sec
  if (millis() - lastMovementTime > 8000) {

    return "🚨 NO MOVEMENT (COLLAPSE)";
  }

  return "STILL";
}

void setup() {

  Serial.begin(115200);

  delay(2000);

  // ================= WIFI =================
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {

    Serial.print(".");

    delay(500);
  }

  Serial.println(" Connected!");

  // ================= TIME =================
configTime(
  gmtOffset_sec,
  daylightOffset_sec,
  ntpServer
);

Serial.print("Syncing time");

time_t now = time(nullptr);

while (now < 100000) {
  Serial.print(".");
  delay(500);
  now = time(nullptr);
}

Serial.println("\nTime synced!");

  // ================= FIREBASE =================
  config.api_key = API_KEY;

  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")) {
  Serial.println("Firebase signup OK");
} else {
  Serial.println(config.signer.signupError.message.c_str());
}

  Firebase.begin(&config, &auth);

  Firebase.reconnectWiFi(true);

  // ================= LORA =================
  Serial.println("RECEIVER STARTING...");

  SPI.begin(18, 19, 23, LORA_SS);

  LoRa.setPins(
    LORA_SS,
    LORA_RST,
    LORA_DIO0
  );

  if (!LoRa.begin(433E6)) {

    Serial.println("LoRa init FAILED!");

    while (1);
  }

  Serial.println("Waiting for packets...\n");
}

void loop() {

  int packetSize = LoRa.parsePacket();

  if (packetSize) {

    String incoming = "";

    while (LoRa.available()) {

      incoming += (char)LoRa.read();
    }

    // ================= PACKET NUMBER =================
    int currentPacketNo = -1;

    if (incoming.startsWith("#")) {

      int commaIndex = incoming.indexOf(',');

      currentPacketNo =
        incoming.substring(1, commaIndex).toInt();
    }

    // ================= MISSED PACKETS =================
    if (lastPacketNo != -1 &&
        currentPacketNo != -1) {

      int missed =
        (currentPacketNo - lastPacketNo) - 1;

      if (missed > 0) {

        totalMissed += missed;

        Serial.println(
          "⚠ Missed " +
          String(missed) +
          " packet(s)!"
        );
      }
    }

    if (currentPacketNo != -1)
      lastPacketNo = currentPacketNo;

    totalReceived++;

    // ================= PARSE DATA =================
    float t2 =
      getValue(incoming, "T2:").toFloat();

    float at =
      getValue(incoming, "AT:").toFloat();

    float altitude =
      getValue(incoming, "A:").toFloat();

    int ax =
      getValue(incoming, "AX:").toInt();

    int ay =
      getValue(incoming, "AY:").toInt();

    int az =
      getValue(incoming, "AZ:").toInt();

    int co =
      getValue(incoming, "CO:").toInt();

    // ================= CALCULATE =================
    float magnitude =
      sqrt(ax * ax + ay * ay + az * az);

    String direction =
      getDirection(ax, ay, az);

    String floorStatus =
      getFloorChange(altitude);

    String fallStatus =
      detectFall(magnitude);

    String movementStatus =
      detectNoMovement(magnitude);

    // ================= DISPLAY =================
    Serial.println("\n===== FIREFIGHTER DATA =====");

    Serial.println(
      "Packet   : " +
      String(currentPacketNo)
    );

    Serial.println(
      "Direction: " +
      direction
    );

    Serial.println(
      "Floor    : " +
      floorStatus
    );

    Serial.println(
      "Fall     : " +
      fallStatus
    );

    Serial.println(
      "Movement : " +
      movementStatus
    );

    Serial.print("Body Temp: ");
    Serial.print(t2);
    Serial.println(" °C");

    Serial.print("Amb Temp : ");
    Serial.print(at);
    Serial.println(" °C");

    Serial.print("CO Level : ");
    Serial.print(co);
    Serial.println(" ppm");

    Serial.println(
      "\nSignal   : RSSI " +
      String(LoRa.packetRssi()) +
      " dBm | SNR " +
      String(LoRa.packetSnr()) +
      " dB"
    );

    Serial.println(
      "Packets  : Received " +
      String(totalReceived) +
      " | Missed " +
      String(totalMissed)
    );

    Serial.println("============================\n");

    // ================= TIME KEY =================
    struct tm timeinfo;

    getLocalTime(&timeinfo);

    char timeStr[25];

    strftime(
      timeStr,
      sizeof(timeStr),
      "%Y-%m-%d_%H-%M-%S",
      &timeinfo
    );

    String timestampKey = String(timeStr);

    // ================= FIREBASE JSON =================
    FirebaseJson json;

    json.set("packet", currentPacketNo);

    json.set("temp_body", t2);
    json.set("temp_ambient", at);

    json.set("co", co);

    json.set("direction", direction);
    json.set("floor", floorStatus);
    json.set("fall", fallStatus);
    json.set("movement", movementStatus);

    // ================= USER =================
    String userID = "device_001";

    // ================= a_latest =================
    Firebase.RTDB.setJSON(
      &fbdo,
      ("/firefighters/" + userID + "/latest").c_str(),
      &json
    );

    // ================= b_history =================
    String historyPath =
      "/firefighters/" +
      userID +
      "/history/" +
      timestampKey;

    Firebase.RTDB.setJSON(
      &fbdo,
      historyPath.c_str(),
      &json
    );

    Serial.println("🔥 Firebase Updated");
  }
}

