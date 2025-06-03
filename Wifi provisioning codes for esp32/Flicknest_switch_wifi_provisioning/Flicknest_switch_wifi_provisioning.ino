#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "secrets.h"  // Define AWS_CERT_CA, AWS_CERT_CRT, AWS_CERT_PRIVATE, AWS_IOT_ENDPOINT, THINGNAME
#include "WiFiProv.h"

#define SWITCH_PIN 22
#define SUB_TOPIC "esp32/pub"
#define SUB_TOPIC2 "firebase/device-control"

// BLE provisioning details
const char *pop = "abcd1234";
const char *service_name = "PROV_FLICKNEST_SWITCH";
const char *service_key = NULL;
bool reset_provisioned = true;
bool wifi_connected = false;

// AWS IoT
WiFiClientSecure net;
PubSubClient client(net);

// Track previous state of "circle"
bool previousCircleState = false;

void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("\nConnected IP address: ");
      Serial.println(IPAddress(sys_event->event_info.got_ip.ip_info.ip.addr));
      wifi_connected = true;
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("\nWi-Fi Disconnected.");
      wifi_connected = false;
      break;
    case ARDUINO_EVENT_PROV_START:
      Serial.println("\nProvisioning started via BLE");
      break;
    case ARDUINO_EVENT_PROV_CRED_RECV:
      Serial.println("\nReceived Wi-Fi credentials");
      break;
    case ARDUINO_EVENT_PROV_CRED_FAIL:
      Serial.println("\nProvisioning failed!");
      break;
    case ARDUINO_EVENT_PROV_CRED_SUCCESS:
      Serial.println("\nProvisioning successful!");
      break;
    case ARDUINO_EVENT_PROV_END:
      Serial.println("\nProvisioning ended.");
      break;
  }
}

void blinkLed(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(SWITCH_PIN, HIGH);
    delay(delayMs);
    digitalWrite(SWITCH_PIN, LOW);
    delay(delayMs);
  }
}

void connectAWS() {
  Serial.println("Connecting to AWS IoT...");

  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);
  client.setCallback(messageReceived);

  while (!client.connected()) {
    Serial.print(".");
    if (client.connect(THINGNAME)) {
      Serial.println("\nConnected to AWS IoT!");
      client.subscribe(SUB_TOPIC);
      client.subscribe(SUB_TOPIC2);
    } else {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      Serial.println(" trying again in 2s");
      delay(2000);
    }
  }
}

void messageReceived(char *topic, byte *payload, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);

  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  if (error) {
    Serial.print("JSON Parse failed: ");
    Serial.println(error.f_str());
    return;
  }

  if (String(topic) == SUB_TOPIC) {
    if (doc.containsKey("circle")) {
      bool circleState = doc["circle"];
      Serial.printf("circle: %d (prev: %d)\n", circleState, previousCircleState);
      if (!previousCircleState && circleState) {
        blinkLed(3, 200);
      }
      previousCircleState = circleState;
    }
  } else if (String(topic) == SUB_TOPIC2) {
    if (doc.containsKey("name") && doc.containsKey("state")) {
      String name = doc["name"];
      bool state = doc["state"];
      if (name == "circle") {
        digitalWrite(SWITCH_PIN, state ? HIGH : LOW);
        Serial.printf("Set SWITCH to: %d\n", state);
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(SWITCH_PIN, OUTPUT);

  WiFi.onEvent(SysProvEvent);

  Serial.println("Starting BLE provisioning...");
  uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02};

  WiFiProv.beginProvision(
    NETWORK_PROV_SCHEME_BLE,
    NETWORK_PROV_SCHEME_HANDLER_FREE_BLE,
    NETWORK_PROV_SECURITY_1,
    pop,
    service_name,
    service_key,
    uuid,
    reset_provisioned
  );

  WiFiProv.printQR(service_name, pop, "ble");

  while (!wifi_connected) {
    delay(500);
  }

  connectAWS();
}

void loop() {
  if (!client.connected()) {
    connectAWS();
  }
  client.loop();
}
