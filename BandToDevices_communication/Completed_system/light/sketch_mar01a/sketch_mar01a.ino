#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "secrets.h"  // Your WiFi + AWS credentials

#define LED_PIN 2 // Change if your LED is on another pin (2 is built-in LED on most ESP32)

WiFiClientSecure net;
PubSubClient client(net);

#define SUB_TOPIC "esp32/pub"  // Subscribing to the publisher topic

void connectAWS() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("Connecting to WiFi...");

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nConnected to WiFi");

  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);

  Serial.println("Connecting to AWS IoT...");
  while (!client.connect(THINGNAME)) {
    Serial.print(".");
    delay(500);
  }

  if (!client.connected()) {
    Serial.println("AWS IoT Connection Failed");
    return;
  }
  
  client.subscribe(SUB_TOPIC);
  Serial.println("Subscribed to topic!");
}

// when a message is received from MQTT
void messageReceived(char* topic, byte* payload, unsigned int length) {
  Serial.println("Message arrived!");

  // Parse incoming payload as JSON
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  if (error) {
    Serial.print("deserializeJson() failed: ");
    Serial.println(error.f_str());
    return;
  }

  bool idleState = doc["circle"];  // Read the 'circle' value
  
  if (idleState) {
    Serial.println("circle detected. Blinking LED!");
    blinkLED();
  } else {
    Serial.println("circle not detected. No action.");
  }
}

void blinkLED() {
  digitalWrite(LED_PIN, HIGH);
  delay(200);
  digitalWrite(LED_PIN, LOW);
  delay(200);
  digitalWrite(LED_PIN, HIGH);
  delay(200);
  digitalWrite(LED_PIN, LOW);
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  connectAWS();
  client.setCallback(messageReceived);  // Set the message receive function
}

void loop() {
  client.loop();  // Keep listening to MQTT
}
