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
#include <Preferences.h>

const char* LOCAL_BROKER = "10.42.0.1";  
const int LOCAL_PORT = 1883;
const char* LOCAL_TOPIC = "esp/control";
const char* LOCAL_SSID = "Flicknest";
String connectedSSID;
#define BULB_PIN 18

#define SUB_TOPIC "esp32/pub"  // Subscribing to the publisher topic
#define SUB_TOPIC2 "firebase/device-control"
#define SUB_TOPIC3 "esp/control"

// BLE Provisioning
const char *pop = "abcd1234";          
const char *service_name = "PROV_FLICKNEST_BULB";  
const char *service_key = NULL;
bool reset_provisioned = false;
bool wifi_connected = false;

String symbol_name = "UPDOWN";

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

// Preferences for checking WiFi credentials
Preferences preferences;

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
      int currentState = digitalRead(BULB_PIN);    
      digitalWrite(BULB_PIN, !currentState); // this changes the out pin according to the hand band input 
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
      digitalWrite(BULB_PIN, state ? HIGH : LOW);// this changes the out pin according to the mobile input 
    } else {
      Serial.println("updown not detected. No action.");
    }
  }
  else {
    Serial.println("Received message from unknown topic.");
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

// Check if WiFi credentials are stored
bool hasWiFiCredentials() {
  preferences.begin("wifi", true); // read-only
  String ssid = preferences.getString("ssid", "");
  preferences.end();
  
  return ssid.length() > 0;
}

// Clear stored WiFi credentials
void clearWiFiCredentials() {
  preferences.begin("wifi", false);
  preferences.clear();
  preferences.end();
  Serial.println("WiFi credentials cleared");
}

void setup() {
  Serial.begin(115200);
  pinMode(BULB_PIN, OUTPUT);

  WiFi.onEvent(SysProvEvent);

  // Check if device has stored WiFi credentials
  bool hasCredentials = hasWiFiCredentials();
  Serial.print("Stored WiFi credentials found: ");
  Serial.println(hasCredentials ? "Yes" : "No");

  if (hasCredentials) {
    Serial.println("Attempting to connect with stored credentials...");
    
    // Start WiFi with stored credentials
    WiFi.mode(WIFI_STA);
    WiFi.begin();
    
    // Wait for connection with timeout
    unsigned long startTime = millis();
    const unsigned long timeout = 15000; // 15 seconds timeout
    
    while (!wifi_connected && (millis() - startTime) < timeout) {
      delay(500);
      Serial.print(".");
    }
    
    if (wifi_connected) {
      Serial.println("\nConnected with stored credentials!");
    } else {
      Serial.println("\nFailed to connect with stored credentials. Starting provisioning...");
      // Clear stored credentials and start provisioning
      clearWiFiCredentials();
      hasCredentials = false;
    }
  }
  
  // Only start provisioning if no credentials exist or if stored credentials failed
  if (!hasCredentials || !wifi_connected) {
    Serial.println("Starting BLE provisioning...");
    
    // Sample uuid that user can pass during provisioning using BLE
    uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02};
    WiFiProv.beginProvision(
      NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key, uuid, reset_provisioned
    );
    
    log_d("ble qr");
    WiFiProv.printQR(service_name, pop, "ble");
    
    // Wait for provisioning to complete
    while (!wifi_connected) {
      delay(1000);
    }
  }
  
  connectedSSID = WiFi.SSID();
  Serial.print("Connected to SSID: ");
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

void loop() {
  // Handle WiFi reconnection if disconnected
  if (!wifi_connected) {
    Serial.println("WiFi disconnected, attempting to reconnect...");
    WiFi.reconnect();
    delay(5000);
    return;
  }
  
  if (connectedSSID == LOCAL_SSID) {
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
}