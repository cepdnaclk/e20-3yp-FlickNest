#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "secrets.h"  // Contains AWS_CERT_CA, AWS_CERT_CRT, AWS_CERT_PRIVATE, AWS_IOT_ENDPOINT, THINGNAME
#include "WiFiProv.h"

#define LED_PIN 2
#define SUB_TOPIC "esp32/pub"
#define SUB_TOPIC2 "firebase/device-control"

// Provisioning
const char *pop = "abcd1234";
const char *service_name = "PROV_FLICKNEST_FINGERPRINT";
const char *service_key = NULL;
bool reset_provisioned = true;
bool wifi_connected = false;

// AWS IoT
WiFiClientSecure net;
PubSubClient client(net);

bool previousCircleState = false;  // Track previous "circle" state

void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("\nConnected IP address: ");
      Serial.println(IPAddress(sys_event->event_info.got_ip.ip_info.ip.addr));
      wifi_connected = true;
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("\nWi-Fi Disconnected.");
      break;
    case ARDUINO_EVENT_PROV_START:
      Serial.println("\nProvisioning started via BLE");
      break;
    case ARDUINO_EVENT_PROV_CRED_RECV:
      Serial.println("\nReceived Wi-Fi credentials");
      Serial.print("\tSSID: ");
      Serial.println((const char *)sys_event->event_info.prov_cred_recv.ssid);
      Serial.print("\tPassword: ");
      Serial.println((const char *)sys_event->event_info.prov_cred_recv.password);
      break;
    case ARDUINO_EVENT_PROV_CRED_FAIL:
      Serial.println("\nProvisioning failed!");
      if (sys_event->event_info.prov_fail_reason == NETWORK_PROV_WIFI_STA_AUTH_ERROR)
        Serial.println("Wi-Fi password incorrect.");
      else
        Serial.println("AP not found. Try erasing flash or moving closer.");
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
    digitalWrite(LED_PIN, HIGH);
    delay(delayMs);
    digitalWrite(LED_PIN, LOW);
    delay(delayMs);
  }
}

void connectAWS() {
  if (!wifi_connected) {
    Serial.println("WiFi not connected. Cannot connect to AWS.");
    return;
  }

  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);

  Serial.print("Connecting to AWS IoT");
  while (!client.connect(THINGNAME)) {
    Serial.print(".");
    delay(500);
  }

  if (!client.connected()) {
    Serial.println(" Failed to connect to AWS IoT.");
    return;
  }

  client.subscribe(SUB_TOPIC);
  client.subscribe(SUB_TOPIC2);
  Serial.println("\nSubscribed to MQTT topics!");
}

void messageReceived(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);

  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  if (error) {
    Serial.print("JSON Parse failed: ");
    Serial.println(error.f_str());
    return;
  }

  if (String(topic) == SUB_TOPIC) {
    bool circleState = doc["circle"];
    Serial.print("circle: ");
    Serial.println(circleState);

    // Blink LED only if circle state changes from false to true
    if (!previousCircleState && circleState) {
      blinkLed(3, 300);  // Blink 3 times with 300ms interval
    }
    previousCircleState = circleState;
  } else if (String(topic) == SUB_TOPIC2) {
    String name = doc["name"];
    bool state = doc["state"];
    Serial.printf("name: %s, state: %d\n", name.c_str(), state);
    if (name == "circle") {
      digitalWrite(LED_PIN, state ? HIGH : LOW);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);

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

  // Wait for Wi-Fi to connect before continuing
  while (!wifi_connected) {
    delay(500);
  }

  connectAWS();
  client.setCallback(messageReceived);
}

void loop() {
  client.loop();  // Keep MQTT connection alive
}
