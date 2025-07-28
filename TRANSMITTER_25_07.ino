 #include <LoRa.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_ADXL345_U.h>
#include <Adafruit_MAX31865.h>
#include <HardwareSerial.h>
#include <DFRobotDFPlayerMini.h>

// --- Pin Definitions ---
// LoRa
#define LORA_SS    15
#define LORA_RST   14
#define LORA_DIO0  26

// MQ Sensors
#define MQ2_PIN 34
#define MQ7_PIN 35

// DFPlayer Serial2
HardwareSerial mySerial(2);
DFRobotDFPlayerMini player;

// MAX31865 (PT100) using SPI
#define MAX_CS   5
#define MAX_MISO 19
#define MAX_MOSI 23
#define MAX_CLK  18

Adafruit_MAX31865 thermo = Adafruit_MAX31865(MAX_CS);

// ADXL345
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);

// Wire config for PT100
#define WIRE_CONFIG MAX31865_2WIRE

// --- Thresholds ---
const int MQ2_THRESHOLD = 300;
const int MQ7_THRESHOLD = 1000;
const float TEMP_THRESHOLD_HIGH = 60.0;
const float TEMP_THRESHOLD_LOW  = 10.0;
const float ACCEL_THRESHOLD = 15.0; // m/s² for sudden movement

int counter = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  // --- DFPlayer Init ---
  mySerial.begin(9600, SERIAL_8N1, 16, 17);
  delay(1000);
  if (!player.begin(mySerial)) {
    Serial.println("DFPlayer Mini not detected!");
    while (true);
  }
  player.volume(25);
  Serial.println("DFPlayer initialized.");

  // --- MAX31865 Init ---
  SPI.begin(MAX_CLK, MAX_MISO, MAX_MOSI, MAX_CS);
  thermo.begin(WIRE_CONFIG);
  Serial.println("PT100 Sensor initialized.");

  // --- ADXL345 Init ---
  if (!accel.begin()) {
    Serial.println("ADXL345 not detected!");
    while (true);
  }
  accel.setRange(ADXL345_RANGE_16_G);
  Serial.println("ADXL345 initialized.");

  // --- LoRa Init ---
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  while (!LoRa.begin(433E6)) {
    Serial.println("Starting LoRa failed...");
    delay(500);
  }
  LoRa.setSyncWord(0xA5);
  Serial.println("LoRa Initialized.");
}

void loop() {
  int mq2Value = analogRead(MQ2_PIN);
  int mq7Value = analogRead(MQ7_PIN);

  sensors_event_t event;
  accel.getEvent(&event);

  float accX = event.acceleration.x;
  float accY = event.acceleration.y;
  float accZ = event.acceleration.z;

  float accelMag = sqrt(accX * accX + accY * accY + accZ * accZ);

  uint16_t rtd;
  float temperature = 0;

  // --- Read PT100 Temperature ---
  rtd = thermo.readRTD();
  temperature = thermo.temperature(100, 430);  // Rref = 430Ω for PT100

  // --- Alerts ---
  if (mq2Value > MQ2_THRESHOLD) {
    player.play(1);
    delay(1000);
  }
  if (mq7Value > MQ7_THRESHOLD) {
    player.play(2);
    delay(1000);
  }
  if (temperature > TEMP_THRESHOLD_HIGH) {
    player.play(3);
    delay(1000);
  } else if (temperature < TEMP_THRESHOLD_LOW) {
    player.play(4);
    delay(1000);
  }
  if (accelMag > ACCEL_THRESHOLD) {
    player.play(5);
    delay(1000);
  }

  // --- Serial Output ---
  Serial.println("----- SENSOR DATA -----");
  Serial.println(counter);
  Serial.print("MQ2: "); Serial.println(mq2Value);
  Serial.print("MQ7: "); Serial.println(mq7Value);
  Serial.print("PT100 Temp (°C): "); Serial.println(temperature, 2);
  // Serial.print("Accel X: "); Serial.print(accX); Serial.print(" Y: "); Serial.print(accY); Serial.print(" Z: "); Serial.println(accZ);
  Serial.print("Accel Magnitude: "); Serial.println(accelMag);
  Serial.println("------------------------\n");

  // --- LoRa Packet (No Status Strings) ---
  LoRa.beginPacket();
  LoRa.print("{");
  LoRa.print("\"packet\":"); LoRa.print(counter); LoRa.print(",");
  LoRa.print("\"mq2\":"); LoRa.print(mq2Value); LoRa.print(",");
  LoRa.print("\"mq7\":"); LoRa.print(mq7Value); LoRa.print(",");
  LoRa.print("\"temp\":"); LoRa.print(temperature, 2); LoRa.print(",");
  LoRa.print("\"accel\":{");
  // LoRa.print("\"x\":"); LoRa.print(accX, 2); LoRa.print(",");
  // LoRa.print("\"y\":"); LoRa.print(accY, 2); LoRa.print(",");
  // LoRa.print("\"z\":"); LoRa.print(accZ, 2); LoRa.print(",");
  LoRa.print("\"mag\":"); LoRa.print(accelMag, 2);
  LoRa.print("}");
  LoRa.print("}");
  LoRa.endPacket();

  counter++;
  delay(15000);
}
