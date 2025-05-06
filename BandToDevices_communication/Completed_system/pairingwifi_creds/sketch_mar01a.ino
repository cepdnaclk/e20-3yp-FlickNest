#include <symbol_mapper_inferencing.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_MPU6050.h>
#include <ArduinoJson.h>
#include "secrets.h"
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <WiFi.h>

#include "sdkconfig.h"
#if CONFIG_ESP_WIFI_REMOTE_ENABLED
#error "WiFiProv is only supported in SoCs with native Wi-Fi support"
#endif

#include "WiFiProv.h"
#include "WiFi.h"


#define AWS_PUB "esp32/pub"
#define AWS_SUB "esp32/sub"

// WiFi Provisioning
#define USE_SOFT_AP
const char *pop = "abcd1234";          
const char *service_name = "PROV_123";  
const char *service_key = NULL;
bool reset_provisioned = false;
bool wifi_connected = false;

// MPU6050
float features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
size_t feature_ix = 0;
unsigned long last_interval_ms = 0;
String lastDev1State = "", lastDev2State = "";
Adafruit_MPU6050 mpu;

// WiFi and AWS
WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);
unsigned long lastWiFiAttempt = 0;
const unsigned long wifiRetryInterval = 500; 

void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("\nConnected IP address : ");
      Serial.println(IPAddress(sys_event->event_info.got_ip.ip_info.ip.addr));
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED: Serial.println("\nDisconnected"); break;
    case ARDUINO_EVENT_PROV_START:            Serial.println("\nProvisioning started\nGive Credentials of your access point using smartphone app"); break;
    case ARDUINO_EVENT_PROV_CRED_RECV:
    {
      Serial.println("\nReceived Wi-Fi credentials");
      Serial.print("\tSSID : ");
      Serial.println((const char *)sys_event->event_info.prov_cred_recv.ssid);
      Serial.print("\tPassword : ");
      Serial.println((char const *)sys_event->event_info.prov_cred_recv.password);
      break;
    }
    case ARDUINO_EVENT_PROV_CRED_FAIL:
    {
      Serial.println("\nProvisioning failed!\nPlease reset to factory and retry provisioning\n");
      if (sys_event->event_info.prov_fail_reason == NETWORK_PROV_WIFI_STA_AUTH_ERROR) {
        Serial.println("\nWi-Fi AP password incorrect");
      } else {
        Serial.println("\nWi-Fi AP not found....Add API \" nvs_flash_erase() \" before beginProvision()");
      }
      break;
    }
    case ARDUINO_EVENT_PROV_CRED_SUCCESS: Serial.println("\nProvisioning Successful"); break;
    case ARDUINO_EVENT_PROV_END:          Serial.println("\nProvisioning Ends"); wifi_connected =true; break;
    default:                              break;
  }
}

void connectAWS() {
  if (!wifi_connected) {
    Serial.println("WiFi not connected");
    return;
  }

  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);
  Serial.println("Connecting to AWS IoT...");

  int attempts = 0;
  while (!client.connect(THINGNAME) && attempts < 10) {
    Serial.print(".");
    delay(1000);
    attempts++;
  }

  if (client.connected()) {
    client.subscribe(AWS_SUB);
    Serial.println("\nAWS IoT Connected!");
  } else {
    Serial.println("\nAWS IoT Connection Failed");
  }
}

void publishMessage(JsonDocument &doc) {
  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  Serial.print("Publishing: ");
  Serial.println(jsonBuffer);
  client.publish(AWS_PUB, jsonBuffer);
}

void detectGesture() {
  sensors_event_t a, g, temp;
  if (millis() > last_interval_ms + (1000 / 60)) {
    last_interval_ms = millis();
    mpu.getEvent(&a, &g, &temp);
    features[feature_ix++] = a.acceleration.x;
    features[feature_ix++] = a.acceleration.y;
    features[feature_ix++] = a.acceleration.z;

    if (feature_ix == EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE) {
      signal_t signal;
      ei_impulse_result_t result;
      if (numpy::signal_from_buffer(features, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal) == 0) {
        if (run_classifier(&signal, &result, false) == 0) {
          JsonDocument doc;
          for (size_t i = 0; i < EI_CLASSIFIER_LABEL_COUNT; i++) {
            String label = result.classification[i].label;
            bool value = result.classification[i].value > 0.7;
            doc[label] = value;
          }
          publishMessage(doc);
        }
      }
      feature_ix = 0;
    }
  }
}

void setup() {
  Serial.begin(115200);

  WiFi.begin();  
  WiFi.onEvent(SysProvEvent);

  Serial.println("Begin Provisioning using Soft AP");
  WiFiProv.beginProvision(NETWORK_PROV_SCHEME_SOFTAP, NETWORK_PROV_SCHEME_HANDLER_NONE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key);
  log_d("wifi qr");
  WiFiProv.printQR(service_name, pop, "softap");

  while(!wifi_connected){
    delay(1000);
  }
  connectAWS();
  if (!mpu.begin()) {
    Serial.println("Failed to initialize MPU6050");
    while (1) delay(20);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
}

void loop() {
  static unsigned long lastGestureCheck = 0;
  if (millis() - lastGestureCheck > 50) {
    lastGestureCheck = millis();
    detectGesture();
  }
  
  client.loop();
  delay(10);
}