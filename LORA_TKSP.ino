#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <LoRa.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "ananya";
const char* password = "ananya18";

// ThingSpeak API
const char* server = "http://api.thingspeak.com/update";
String apiKey = "8Z0BCBSCASG2VIDB";

// OLED settings
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// LoRa pins
#define LORA_SS    15
#define LORA_RST   14
#define LORA_DIO0  26

void setup() {
  Serial.begin(115200);

  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");

  // OLED init
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED failed");
    while (true);
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("LoRa + WiFi Ready");
  display.display();

  // LoRa init
  SPI.begin(18, 19, 23, LORA_SS);
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  if (!LoRa.begin(433E6)) {
    Serial.println("LoRa failed!");
    while (true);
  }
  LoRa.setSyncWord(0xA5);
  Serial.println("LoRa initialized");
}

void loop() {
  int packetSize = LoRa.parsePacket();
  if (packetSize) {
    String received = "";
    while (LoRa.available()) {
      received += (char)LoRa.read();
    }

    Serial.println("Received JSON:");
    Serial.println(received);

    // Parse JSON
    StaticJsonDocument<384> doc;
    DeserializationError error = deserializeJson(doc, received);

    if (error) {
      Serial.print("JSON error: ");
      Serial.println(error.c_str());
      return;
    }

    int packet = doc["packet"];
    int mq2 = doc["mq2"];
    int mq7 = doc["mq7"];
    float temp = doc["temp"];
    float accMag = doc["accel"]["mag"];

    // OLED Display
    display.clearDisplay();
    display.setCursor(0, 0);
    display.printf("Pkt: %d\n", packet);
    display.printf("MQ2: %d\n", mq2);
    display.printf("MQ7: %d\n", mq7);
    display.printf("Temp: %.1f C\n", temp);
    display.printf("Acc: %.1f m/s2\n", accMag);
    display.display();

    // ThingSpeak Send
    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      String url = String(server) + "?api_key=" + apiKey +
                   "&field1=" + String(mq2) +
                   "&field2=" + String(mq7) +
                   "&field3=" + String(temp) +
                   "&field4=" + String(accMag);
      http.begin(url);
      int httpCode = http.GET();

      if (httpCode > 0) {
        Serial.println("Data sent to ThingSpeak");
      } else {
        Serial.println("Failed to send to ThingSpeak");
      }

      http.end();
    }

    delay(10000); // Wait before next read
  }
}
