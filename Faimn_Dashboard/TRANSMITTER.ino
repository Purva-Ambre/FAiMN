#include "Arduino.h"
#include "LoRaWan_APP.h"
#include <SPI.h>
#include <Adafruit_MAX31865.h>
#include <Adafruit_BMP3XX.h>
#include <DFRobotDFPlayerMini.h>

// ================= LORA =================
#define RF_FREQUENCY 433000000
#define TX_OUTPUT_POWER 5

// ================= HSPI =================
SPIClass hspi(HSPI);
#define SCK 36
#define MISO 37
#define MOSI 35

// ================= CO SENSOR =================
#define CO_RX 48
#define CO_TX 47
HardwareSerial coSerial(1);
int co_ppm = -1;

// ================= TIMING =================
unsigned long startTime = 0;
bool systemStartedPlayed = false;
bool calibrationDone = false;

// ================= MP3 =================
#define DF_RX 33
#define DF_TX 34
HardwareSerial dfSerial(2);
DFRobotDFPlayerMini dfplayer;
bool dfReady = false;

// ================= CS =================
#define CS_MAX1 1
#define CS_MAX2 2
#define CS_BMP  4
#define CS_MPU  5

// ================= MAX =================
#define RNOMINAL 100.0
#define RREF     430.0
Adafruit_MAX31865 maxAmbient(CS_MAX1, &hspi);
Adafruit_MAX31865 maxBody(CS_MAX2, &hspi);

// ================= BMP =================
Adafruit_BMP3XX bmp;

// ================= VARIABLES =================
char txpacket[150];
int packetNo = 0;
bool lora_idle = true;

float tAmbient = 0, tBody = 0;
float bmpTemp = 0, pressure = 0, altitude = 0;

int16_t ax = 0, ay = 0, az = 0;

// ================= ALERT TIMERS =================
unsigned long lastAmbientWarn = 0, lastAmbientDanger = 0;
unsigned long lastBodyWarn = 0, lastBodyDanger = 0;
unsigned long lastCOWarn = 0, lastCODanger = 0;

static RadioEvents_t RadioEvents;

// ================= FUNCTIONS =================
void OnTxDone(void) { lora_idle = true; }
void OnTxTimeout(void) { lora_idle = true; }

void playTrack(int track) {
  if (dfReady) {
    dfplayer.play(track);
    delay(200);
  }
}

// ===== MPU =====
int16_t read16(byte reg) {
  digitalWrite(CS_MPU, LOW);
  hspi.transfer(reg | 0x80);
  int16_t high = hspi.transfer(0x00);
  int16_t low  = hspi.transfer(0x00);
  digitalWrite(CS_MPU, HIGH);
  return (high << 8) | low;
}

void writeMPU(byte reg, byte data) {
  digitalWrite(CS_MPU, LOW);
  hspi.transfer(reg);
  hspi.transfer(data);
  digitalWrite(CS_MPU, HIGH);
}

// ===== CO (FIXED BUFFER HANDLING) =====
bool readCO() {
  while (coSerial.available() >= 9) {
    uint8_t buf[9];
    coSerial.readBytes(buf, 9);

    if (buf[0] == 0xFF && buf[1] == 0x04) {
      uint8_t checksum = 0;
      for (int i = 1; i <= 7; i++) checksum += buf[i];
      checksum = (~checksum) + 1;

      if (checksum == buf[8]) {
        co_ppm = buf[4] * 256 + buf[5];
        return true;
      }
    }
  }
  return false;
}

// ================= SETUP =================
void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println("🔥 SYSTEM START");

  startTime = millis();

  coSerial.begin(9600, SERIAL_8N1, CO_RX, CO_TX);

  dfSerial.begin(9600, SERIAL_8N1, DF_RX, DF_TX);
  if (dfplayer.begin(dfSerial)) {
    dfReady = true;
    dfplayer.volume(25);
    Serial.println("MP3 READY");
  }

  hspi.begin(SCK, MISO, MOSI);

  pinMode(CS_MAX1, OUTPUT);
  pinMode(CS_MAX2, OUTPUT);
  pinMode(CS_BMP, OUTPUT);
  pinMode(CS_MPU, OUTPUT);

  digitalWrite(CS_MAX1, HIGH);
  digitalWrite(CS_MAX2, HIGH);
  digitalWrite(CS_BMP, HIGH);
  digitalWrite(CS_MPU, HIGH);

  maxAmbient.begin(MAX31865_2WIRE);
  maxBody.begin(MAX31865_2WIRE);

  bmp.begin_SPI(CS_BMP, &hspi);
  writeMPU(0x6B, 0x00);

  Mcu.begin(HELTEC_BOARD, SLOW_CLK_TPYE);

  RadioEvents.TxDone = OnTxDone;
  RadioEvents.TxTimeout = OnTxTimeout;

  Radio.Init(&RadioEvents);
  Radio.SetChannel(RF_FREQUENCY);

  Radio.SetTxConfig(MODEM_LORA, TX_OUTPUT_POWER, 0, 0,
                    7, 1, 8, false,
                    true, 0, 0, false, 3000);

  Serial.println("SYSTEM INITIALIZING...\n");
}

// ================= LOOP =================
void loop() {
  Radio.IrqProcess();
  unsigned long now = millis();

  // ===== START EVENTS =====
  if (!systemStartedPlayed && now - startTime > 30000) {
    Serial.println("🔊 SYSTEM STARTED");
    playTrack(1);
    systemStartedPlayed = true;
  }

  if (!calibrationDone && now - startTime > 240000) {
    Serial.println("🔊 CALIBRATION COMPLETE");
    playTrack(10);
    calibrationDone = true;
  }

  // ===== READ SENSORS =====
  tAmbient = maxAmbient.temperature(RNOMINAL, RREF);
  tBody = maxBody.temperature(RNOMINAL, RREF);

  if (bmp.performReading()) {
    bmpTemp = bmp.temperature;
    pressure = bmp.pressure / 100.0;
    altitude = bmp.readAltitude(1013.25);
  }

  ax = read16(0x3B);
  ay = read16(0x3D);
  az = read16(0x3F);

  readCO();  // ALWAYS READ

  // ===== DEBUG =====
  Serial.println("\n---- DATA ----");
  Serial.print("Body Temp: "); Serial.println(tBody);
  Serial.print("Ambient Temp: "); Serial.println(tAmbient);
  Serial.print("Altitude: "); Serial.println(altitude);

  if (!calibrationDone) {
    Serial.print("CO (calibrating): ");
  } else {
    Serial.print("CO: ");
  }
  Serial.println(co_ppm);

  // ===== ALERTS =====
  if (tAmbient >= 35 && tAmbient < 50 && now - lastAmbientWarn > 30000) {
    playTrack(2);
    lastAmbientWarn = now;
  }
  else if (tAmbient >= 50 && now - lastAmbientDanger > 15000) {
    playTrack(3);
    lastAmbientDanger = now;
  }

  if (tBody >= 37 && tBody < 39 && now - lastBodyWarn > 30000) {
    playTrack(6);
    lastBodyWarn = now;
  }
  else if (tBody >= 39 && now - lastBodyDanger > 15000) {
    playTrack(7);
    lastBodyDanger = now;
  }

  if (calibrationDone) {
    if (co_ppm >= 30 && co_ppm < 99 && now - lastCOWarn > 30000) {
      playTrack(13);
      lastCOWarn = now;
    }
    else if (co_ppm >= 100 && now - lastCODanger > 15000) {
      playTrack(14);
      lastCODanger = now;
    }
  }

  // ===== LORA =====
  if (lora_idle) {
    packetNo++;

    sprintf(txpacket,
      "#%d,T2:%.2f,AT:%.2f,P:%.2f,A:%.2f,AX:%d,AY:%d,AZ:%d,CO:%d",
packetNo, tBody, tAmbient, pressure, altitude, ax, ay, az, co_ppm);

    Radio.Send((uint8_t *)txpacket, strlen(txpacket));
    lora_idle = false;

    delay(2000);
  }
}
