#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "secrets.h"  // Your WiFi + AWS credentials
#include "WiFiProv.h"
#include "WiFi.h"
#include "sdkconfig.h"

#define LED_PIN 2 // Change if your LED is on another pin (2 is built-in LED on most ESP32)

#define SUB_TOPIC "esp32/pub"  // Subscribing to the publisher topic
#define SUB_TOPIC2 "firebase/device-control"

// BLE Provisioning
const char *pop = "abcd1234";          
const char *service_name = "PROV_FLICKNEST_FINGERPRINT";  
const char *service_key = NULL;
bool reset_provisioned = false;
bool wifi_connected = false;

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
      wifi_connected =true;
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
    case ARDUINO_EVENT_PROV_END:          Serial.println("\nProvisioning Ends"); ; break;
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
  while (!client.connect(THINGNAME)) {
    Serial.print(".");
    delay(500);
  }

  if (!client.connected()) {
    Serial.println("AWS IoT Connection Failed");
    return;
  }
  
  client.subscribe(SUB_TOPIC);
  client.subscribe(SUB_TOPIC2);
  Serial.println("Subscribed to topic!");
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
    bool symbol = doc["circle"];
    Serial.print("circle: ");
    Serial.println(symbol);

    if (symbol) {
      int currentState = digitalRead(LED_PIN);    
      digitalWrite(LED_PIN, !currentState); // this changes the out pin according to the hand band input 
    } else {
      Serial.print("Not the correct symbol for me");
    }
  } 
  else if (String(topic) == SUB_TOPIC2) {
    // Example: {"name": "circle", "state": true}
    String name = doc["name"].as<String>();
    bool state = doc["state"].as<bool>();

    Serial.print("name: ");
    Serial.println(name);
    Serial.print("state: ");
    Serial.println(state);

    if (name == "circle") {
      digitalWrite(LED_PIN, state ? HIGH : LOW);// this changes the out pin according to the mobile input 
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
  pinMode(LED_PIN, OUTPUT);

  WiFi.begin();  
  WiFi.onEvent(SysProvEvent);
  Serial.println("Begin Provisioning using BLE");
  // Sample uuid that user can pass during provisioning using BLE
  uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02};
  WiFiProv.beginProvision(
    NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key, uuid, reset_provisioned
  );
  log_d("ble qr");
  WiFiProv.printQR(service_name, pop, "ble");

  while(!wifi_connected){
    delay(1000);
  }

  connectAWS();
  client.setCallback(messageReceived);  // Set the message receive function
}

void loop() {
  client.loop();  // Keep listening to MQTT
}
