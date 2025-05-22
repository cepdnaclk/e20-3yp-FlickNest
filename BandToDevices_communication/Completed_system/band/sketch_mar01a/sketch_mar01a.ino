#include <Adafruit_Sensor.h>
#include <Adafruit_MPU6050.h>
#include <ArduinoJson.h>
#include "secrets.h"
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <WiFiProv.h>
#include <WiFi.h>
#include <symbol_mapper_cloned2_inferencing.h>
#include "WiFiProv.h"
#include "WiFi.h"

#define FREQUENCY_HZ 60
#define INTERVAL_MS (1000 / (FREQUENCY_HZ + 1))

#define AWS_PUB "esp32/pub"
#define AWS_SUB "esp32/sub"

String current_state = "";
String last_state = "";

const char *pop = "abcd1234";
const char *service_name = "PROV_FLICKNEST_BANDzz";
bool reset_provisioned = false;
bool wifi_connected = false;

float features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
size_t feature_ix = 0;
unsigned long last_interval_ms = 0;
Adafruit_MPU6050 mpu;

WiFiClientSecure net;
PubSubClient client(net);

void SysProvEvent(arduino_event_t *e) {
  switch (e->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      wifi_connected = true;
      break;
    case ARDUINO_EVENT_PROV_START:
      Serial.println("Prov start");
      break;
    case ARDUINO_EVENT_PROV_CRED_RECV:
      Serial.println("Cred recv");
      break;
    case ARDUINO_EVENT_PROV_CRED_FAIL:
      Serial.println("Prov fail");
      break;
    case ARDUINO_EVENT_PROV_CRED_SUCCESS:
      Serial.println("Prov OK");
      break;
    case ARDUINO_EVENT_PROV_END:
      Serial.println("Prov end");
      break;
  }
}

void connectAWS() {
  if (!wifi_connected) return;

  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);
  int attempts = 0;
  while (!client.connect(THINGNAME) && attempts++ < 10) delay(1000);

  if (client.connected()) client.subscribe(AWS_SUB);client.subscribe("firebase/device-control");
  Serial.println("Connected to aws and subscribed ");
}

void publishMessage(JsonDocument &doc) {
  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  client.publish(AWS_PUB, jsonBuffer);
}

void detectGesture() {
  sensors_event_t a, g, temp;
  if (millis() > last_interval_ms + INTERVAL_MS) {
    last_interval_ms = millis();
    mpu.getEvent(&a, &g, &temp);
    features[feature_ix++] = a.acceleration.x;
    features[feature_ix++] = a.acceleration.y;
    features[feature_ix++] = a.acceleration.z;

    if (feature_ix == EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE) {
      signal_t signal;
      ei_impulse_result_t result;
      if (numpy::signal_from_buffer(features, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal) == 0 &&
          run_classifier(&signal, &result, false) == 0) {
        JsonDocument doc;
        #if EI_CLASSIFIER_HAS_ANOMALY == 1
        if (result.anomaly >= 0.0f) {
          current_state = "anomaly";
        } else {
          float max_val = 0.0;
          const char* max_label = "";

          for (size_t ix = 0; ix < EI_CLASSIFIER_LABEL_COUNT; ix++) {
            if (result.classification[ix].value > 0.6 && result.classification[ix].value > max_val) {
              max_val = result.classification[ix].value;
              max_label = result.classification[ix].label;
            }
          }

          if (strlen(max_label) > 0) {
            current_state = String(max_label);
            doc[current_state] = true; 
          }
        }
      #endif

      // Only print if state changed
      if (current_state != "" && current_state != last_state) {
        Serial.print("Symbol detected: ");
        Serial.println(current_state);
        last_state = current_state;
      }
        publishMessage(doc);
      }
      feature_ix = 0;
    }
  }
}

void setup() {

  Serial.begin(115200);
  WiFi.begin();
  Serial.println("HElloooo");
  WiFi.onEvent(SysProvEvent);

  uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02};
  WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE,
                          NETWORK_PROV_SECURITY_1, pop, service_name, NULL, uuid, reset_provisioned);
  WiFiProv.printQR(service_name, pop, "ble");

  while (!wifi_connected) delay(1000);
  Serial.println("Connected to wifi");
  connectAWS();

  if (!mpu.begin()) while (1) delay(20);
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
}

void loop() {
  if(!client.connected()){
    connectAWS();
  }
  static unsigned long lastGestureCheck = 0;
  if (millis() - lastGestureCheck > 50) {
    lastGestureCheck = millis();
    detectGesture();
  }
  client.loop();
  delay(10);
}
