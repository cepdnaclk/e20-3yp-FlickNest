#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include "secrets.h"  // Your WiFi + AWS credentials

// Hardcoded WiFi credentials
const char* WIFI_SSID = "flicknest";        
const char* WIFI_PASSWORD = ""; 

const char* LOCAL_BROKER = "10.42.0.1";  
const int LOCAL_PORT = 1883;
const char* LOCAL_TOPIC = "esp/control";
const char* LOCAL_SSID = "flicknest";
String connectedSSID;

#define LED_PIN LED_BUILTIN // Built-in LED on NodeMCU (GPIO2/D4)

#define SUB_TOPIC "esp32/pub"  // Subscribing to the publisher topic
#define SUB_TOPIC2 "firebase/device-control"
#define SUB_TOPIC3 "esp/control"

// WiFi and AWS
BearSSL::WiFiClientSecure net;
PubSubClient client(net);
unsigned long lastWiFiAttempt = 0;
const unsigned long wifiRetryInterval = 500; 

//local broker config 
WiFiClient localNet;
PubSubClient mqttClient;

bool useLocal = false;
bool wifi_connected = false;

void connectToWiFi() {
  Serial.println("Connecting to WiFi...");
  WiFi.mode(WIFI_STA);
  
  // Connect to WiFi - check if password is empty for open network
  if (strlen(WIFI_PASSWORD) == 0) {
    WiFi.begin(WIFI_SSID);
    Serial.println("Connecting to open network...");
  } else {
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.println("Connecting to secured network...");
  }
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(1000);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    wifi_connected = true;
    Serial.println();
    Serial.print("Connected to WiFi! IP address: ");
    Serial.println(WiFi.localIP());
    connectedSSID = WiFi.SSID();
    Serial.print("Connected to SSID: ");
    Serial.println(connectedSSID);
  } else {
    Serial.println();
    Serial.println("Failed to connect to WiFi");
    wifi_connected = false;
  }
}

void connectAWS() {
  if (!wifi_connected) {
    Serial.println("WiFi not connected");
    return;
  }

  // ESP8266 certificate handling with BearSSL
  net.setTrustAnchors(new BearSSL::X509List(AWS_CERT_CA));
  net.setClientRSACert(new BearSSL::X509List(AWS_CERT_CRT), new BearSSL::PrivateKey(AWS_CERT_PRIVATE));

  client.setServer(AWS_IOT_ENDPOINT, 8883);

  Serial.println("Connecting to AWS IoT...");
  int attempts = 0;
  while (!client.connect(THINGNAME) && attempts < 10) {
    Serial.print(".");
    delay(1000);
    attempts++;
  }

  if (!client.connected()) {
    Serial.println("AWS IoT Connection Failed");
    return;
  }
  
  client.subscribe(SUB_TOPIC);
  client.subscribe(SUB_TOPIC2);
  client.subscribe(SUB_TOPIC3);
  Serial.println("Connected to AWS IoT and subscribed to topics!");
}

void connectToBroker() {
  Serial.println("Connecting to local MQTT Broker...");
  while (!mqttClient.connected()) {
    if (mqttClient.connect("NodeMCU_Client_Lock")) {
      Serial.println("Connected to local MQTT broker");

      // Subscribe to ONLY esp/control
      mqttClient.subscribe(LOCAL_TOPIC);
      Serial.println("Subscribed to: esp/control");
    } else {
      Serial.print("Failed to connect, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" retrying in 5 seconds");
      delay(5000);
    }
  }
}

// when a message is received from MQTT
void messageReceived(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);

  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  if (error) {
    Serial.print("deserializeJson() failed: ");
    Serial.println(error.f_str());
    return;
  }

  // Compare the topic string
  if (String(topic) == SUB_TOPIC) {
    // Example: {"circle": true}
    bool symbol = doc["CIRCLE"];
    Serial.print("circle: ");
    Serial.println(symbol);

    if (symbol) {
      int currentState = digitalRead(LED_PIN);    
      digitalWrite(LED_PIN, !currentState); // this changes the out pin according to the hand band input 
    } else {
      Serial.print("Not the correct symbol for me");
    }
  } 
  else if ((String(topic) == SUB_TOPIC2) || (String(topic) == SUB_TOPIC3)) {
    String name = doc["name"].as<String>();
    bool state = doc["state"].as<bool>();
    
    Serial.print("name: ");
    Serial.println(name);
    Serial.print("state: ");
    Serial.println(state);

    if (name == "circle") {
      digitalWrite(LED_PIN, state ? LOW : HIGH); // Note: Built-in LED is inverted on NodeMCU
    } else {
      Serial.println("circle not detected. No action.");
    }
  }
  else {
    Serial.println("Received message from unknown topic.");
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println();
  Serial.println("Starting NodeMCU 12E...");
  
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH); // Turn off LED initially (inverted logic)

  // Connect to WiFi
  connectToWiFi();
  
  if (!wifi_connected) {
    Serial.println("Cannot proceed without WiFi connection");
    return;
  }
  
  // Check which broker to use based on connected SSID
  if (connectedSSID == LOCAL_SSID) {
    Serial.println("Using local MQTT broker");
    useLocal = true;
    mqttClient.setClient(localNet);
    mqttClient.setServer(LOCAL_BROKER, LOCAL_PORT);
    mqttClient.setCallback(messageReceived);
    connectToBroker();
  } else {
    Serial.println("Using AWS IoT");
    useLocal = false;
    connectAWS();
    client.setCallback(messageReceived);  // Set the message receive function
  }
}

void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    wifi_connected = false;
    Serial.println("WiFi disconnected. Attempting to reconnect...");
    connectToWiFi();
    delay(5000);
    return;
  }

  if (useLocal) {
    if (!mqttClient.connected()) {
      connectToBroker();
    }
    mqttClient.loop();
  } else {
    if (!client.connected()) {
      connectAWS();
    }
    client.loop();  // Keep listening to MQTT
  }
  
  delay(10); // Small delay to prevent watchdog reset
}