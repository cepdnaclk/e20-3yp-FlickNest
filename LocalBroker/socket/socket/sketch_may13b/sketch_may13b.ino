#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "secrets.h"  // Your WiFi + AWS credentials
#include "WiFiProv.h"
#include "WiFi.h"
#include "sdkconfig.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFiClient.h>
#include "esp_wifi.h"

const char* LOCAL_BROKER = "10.42.0.1";  
const int LOCAL_PORT = 1883;
const char* LOCAL_TOPIC = "esp/control";
const char* LOCAL_SSID = "Flicknest";
String connectedSSID;
#define SWITCH_PIN 2

#define SUB_TOPIC "esp32/pub"  // Subscribing to the publisher topic
#define SUB_TOPIC2 "firebase/device-control"
#define SUB_TOPIC3 "esp/control"

// BLE Provisioning
const char *pop = "abcd1234";          
const char *service_name = "PROV_FLICKNEST_SOCKET";  
const char *service_key = NULL;
bool reset_provisioned = false;
bool wifi_connected = false;

String symbol_name = "WAVE";

// WiFi and AWS
WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);
unsigned long lastWiFiAttempt = 0;
const unsigned long wifiRetryInterval = 500; 

//local broker config 
WiFiClient localNet;
WiFiClientSecure awsNet;
PubSubClient mqttClient;

bool useLocal = false;


bool isProvisioned() {
  wifi_config_t conf;
  esp_err_t err = esp_wifi_get_config(WIFI_IF_STA, &conf);
  if (err == ESP_OK && strlen((const char*)conf.sta.ssid) > 0) {
    return true;
  }
  return false;
}

void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("\nConnected IP address : ");
      Serial.println(IPAddress(sys_event->event_info.got_ip.ip_info.ip.addr));
      wifi_connected = true;
      break;
      
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED: 
      Serial.println("\nDisconnected"); 
      wifi_connected = false;
      break;
      
    case ARDUINO_EVENT_PROV_START:            
      {  // Add braces to create scope for variable declarations
        Serial.println("\nProvisioning started");
        Serial.println("Performing WiFi scan...");
        
        // Force WiFi scan when provisioning starts
        WiFi.mode(WIFI_STA);
        int n = WiFi.scanNetworks();
        Serial.printf("Found %d networks:\n", n);
        
        for (int i = 0; i < n; ++i) {
          Serial.printf("%d: %s (%d dBm) %s\n", 
                       i + 1, 
                       WiFi.SSID(i).c_str(), 
                       WiFi.RSSI(i),
                       (WiFi.encryptionType(i) == WIFI_AUTH_OPEN) ? "[OPEN]" : "[SECURED]");
        }
      }  // Close the scope
      break;
      
    case ARDUINO_EVENT_PROV_CRED_RECV: 
      {  // Add braces for this case too
        Serial.println("\nReceived Wi-Fi credentials");
        Serial.print("\tSSID : ");
        Serial.println((const char *)sys_event->event_info.prov_cred_recv.ssid);
        Serial.print("\tPassword : ");
        Serial.println((char const *)sys_event->event_info.prov_cred_recv.password);
        
        // Check if it's an open network
        if (strlen((char const *)sys_event->event_info.prov_cred_recv.password) == 0) {
          Serial.println("\tOpen network detected");
        }
      }
      break;
    
    case ARDUINO_EVENT_PROV_CRED_FAIL: 
      {  // Add braces for this case
        Serial.println("\nProvisioning failed!");
        if (sys_event->event_info.prov_fail_reason == NETWORK_PROV_WIFI_STA_AUTH_ERROR) {
          Serial.println("Wi-Fi AP password incorrect");
        } else {
          Serial.println("Wi-Fi AP not found");
        }
      }
      break;
    
    case ARDUINO_EVENT_PROV_CRED_SUCCESS: 
      Serial.println("\nProvisioning Successful"); 
      break;
      
    case ARDUINO_EVENT_PROV_END:          
      Serial.println("\nProvisioning Ends"); 
      break;
      
    default:                              
      break;
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
  client.subscribe(SUB_TOPIC3);
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
    bool symbol = doc[symbol_name];
    Serial.print("UPDOWN: ");
    Serial.println(symbol);

    if (symbol) {
      int currentState = digitalRead(SWITCH_PIN);    
      digitalWrite(SWITCH_PIN, !currentState); // this changes the out pin according to the hand band input 
    } else {
      Serial.print("Not the correct symbol for me");
    }
  } 
  else if ((String(topic) == SUB_TOPIC2) |(String(topic) == SUB_TOPIC3)) {
    String name = doc["name"].as<String>();
    bool state = doc["state"].as<bool>();
    
    Serial.print("name: ");
    Serial.println(name);
    Serial.print("state: ");
    Serial.println(state);

    if (name.equalsIgnoreCase(symbol_name)) {
      digitalWrite(SWITCH_PIN, state ? HIGH : LOW);// this changes the out pin according to the mobile input 
    } else {
      Serial.println("updown not detected. No action.");
    }
  }
  else {
    Serial.println("Received message from unknown topic.");
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(SWITCH_PIN, OUTPUT); 
  WiFi.onEvent(SysProvEvent);

  if (!isProvisioned()) {
    Serial.println("Starting BLE Provisioning...");
    
    // BLE UUID sample
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

    log_d("BLE QR");
    WiFiProv.printQR(service_name, pop, "ble");

    while (!wifi_connected) {
      delay(500);
    }

  } else {
    Serial.println("WiFi already provisioned. Connecting to saved credentials...");
    WiFi.begin();

    while (WiFi.status() != WL_CONNECTED) {
      Serial.print(".");
      delay(500);
    }

    wifi_connected = true;
    Serial.println("\nConnected to Wi-Fi");
  }

  connectedSSID = WiFi.SSID();
  Serial.print("Connected to the SSID: ");
  Serial.println(connectedSSID);

  if (connectedSSID == LOCAL_SSID) {
    useLocal = true;
    mqttClient.setClient(localNet);
    mqttClient.setServer(LOCAL_BROKER, LOCAL_PORT);
    mqttClient.setCallback(messageReceived);
    connectToBroker();
  } else {
    useLocal = false;
    connectAWS();
    client.setCallback(messageReceived);  // Set the message receive function
  }
}
  
void connectToBroker() {
  Serial.println("Connecting to MQTT Broker...");
  while (!mqttClient.connected()) {
    if (mqttClient.connect("ESP32Client")) {
      Serial.println("Connected to MQTT broker");

      // Subscribe to ONLY esp/control
      mqttClient.subscribe(LOCAL_TOPIC);
      Serial.println("Subscribed to: esp/control");
    } else {
      Serial.print(".");
      delay(500);
    }
  }
}


void loop() {
  if(connectedSSID == LOCAL_SSID){
    mqttClient.loop();
  }else{
    client.loop();  // Keep listening to MQTT
  }
  
}