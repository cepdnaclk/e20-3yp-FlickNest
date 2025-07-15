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

// Door Lock System Libraries
#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7735.h>

const char* LOCAL_BROKER = "10.42.0.1";  
const int LOCAL_PORT = 1883;
const char* LOCAL_TOPIC = "esp/control";
const char* LOCAL_SSID = "flicknest";
String connectedSSID;

// Pin Definitions for ESP32 (Digital Pins)
#define LED_PIN 2           // GPIO2 - Built-in LED
#define RELAY_PIN 26        // GPIO26 - Relay for door lock
#define TFT_CS 5            // GPIO5 - TFT Chip Select
#define TFT_DC 4            // GPIO4 - TFT Data/Command  
#define TFT_RST 16          // GPIO16 - TFT Reset
#define TFT_BL 22           // GPIO22 - TFT Backlight (optional)
#define BUTTON_PIN 19       // GPIO19 - Enrollment Button
#define FINGERPRINT_RX 17   // Back to original
#define FINGERPRINT_TX 21   // Back to original
// GPIO23 = MOSI (SDA/Data) - automatic SPI
// GPIO18 = SCK (Clock) - automatic SPI

// Initialize Door Lock Objects
Adafruit_ST7735 tft = Adafruit_ST7735(TFT_CS, TFT_DC, TFT_RST);
HardwareSerial fingerprintSerial(2); // Use UART2 for ESP32
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerprintSerial);

#define SUB_TOPIC "esp32/pub"  // Subscribing to the publisher topic
#define SUB_TOPIC2 "firebase/device-control"
#define SUB_TOPIC3 "esp/control"

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

//local broker config 
WiFiClient localNet;
WiFiClientSecure awsNet;
PubSubClient mqttClient;

bool useLocal = false;

// Door Lock System States - Simplified
bool enrollmentInProgress = false;

// Long Press Button Variables
bool lastButtonState = HIGH;
bool currentButtonState = HIGH;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50;
unsigned long buttonPressStart = 0;
bool longPressActive = false;
bool longPressDetected = false;
const unsigned long LONG_PRESS_TIME = 3000; // 3 seconds

// Fingerprint Management
uint8_t maxFingerprints = 3;  // Maximum 3 fingerprints allowed
uint8_t currentEnrollSlot = 1; // Cycles through 1, 2, 3

// Display constants
#define DISPLAY_WIDTH 128
#define DISPLAY_HEIGHT 160

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
    // Example: {"CIRCLE": true}
    bool symbol = doc["CIRCLE"];
    Serial.print("circle: ");
    Serial.println(symbol);

    if (symbol) {
      // Toggle relay state when circle signal received
      int currentRelayState = digitalRead(RELAY_PIN);    
      digitalWrite(RELAY_PIN, !currentRelayState);
      digitalWrite(LED_PIN, !currentRelayState); // Also toggle LED
      
      if (!currentRelayState) { // If relay was OFF and now turning ON
        showAccessGranted();
        Serial.println("Door unlocked via hand gesture");
      } else {
        Serial.println("Door locked via hand gesture");
      }
    } else {
      Serial.println("Not the correct symbol for me");
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
      digitalWrite(RELAY_PIN, state ? HIGH : LOW);
      digitalWrite(LED_PIN, state ? HIGH : LOW);
      
      if (state) {
        showAccessGranted();
        Serial.println("Door unlocked via mobile/Firebase");
      } else {
        Serial.println("Door locked via mobile/Firebase");
      }
    } else {
      Serial.println("circle not detected. No action.");
    }
  }
  else {
    Serial.println("Received message from unknown topic.");
  }
}

void connectToBroker() {
  Serial.println("Connecting to MQTT Broker...");
  while (!mqttClient.connected()) {
    if (mqttClient.connect("ESP32Client_Lock")) {
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

void setup() {
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(TFT_BL, OUTPUT); // TFT Backlight
  
  // Initialize button pin with internal pull-up
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  
  // Initialize pin states
  digitalWrite(RELAY_PIN, LOW); // Start with door locked
  digitalWrite(LED_PIN, LOW);   // Start with LED off
  digitalWrite(TFT_BL, HIGH);   // Turn on TFT backlight
  
  // Read initial button state
  lastButtonState = digitalRead(BUTTON_PIN);
  currentButtonState = lastButtonState;
  
  // Initialize fingerprint sensor
  fingerprintSerial.begin(57600, SERIAL_8N1, FINGERPRINT_RX, FINGERPRINT_TX);
  finger.begin(57600);
  
  // Initialize display
  tft.initR(INITR_144GREENTAB);
  tft.setRotation(0);
  tft.fillScreen(ST7735_BLACK);
  
  // Show startup screen
  showStartupScreen();
  delay(2000);

  WiFi.begin();  
  WiFi.onEvent(SysProvEvent);
  Serial.println("Begin Provisioning using BLE");
  // Sample uuid that user can pass during provisioning using BLE
  uint8_t uuid[16] = {0xa1, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0};
  WiFiProv.beginProvision(
    NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key, uuid, reset_provisioned
  );
  log_d("ble qr");
  WiFiProv.printQR(service_name, pop, "ble");

  while(!wifi_connected){
    delay(1000);
  }

  connectedSSID = WiFi.SSID();
  Serial.print("connected to the ssid");
  Serial.println(connectedSSID);
  
  if(connectedSSID == LOCAL_SSID){
    useLocal =true;
    mqttClient.setClient(localNet);
    mqttClient.setServer(LOCAL_BROKER, LOCAL_PORT);
    mqttClient.setCallback(messageReceived);
    connectToBroker();
  }else{
    useLocal =false;
    connectAWS();
    client.setCallback(messageReceived);  // Set the message receive function
  }

  // Verify fingerprint sensor with debugging
  Serial.println("Testing fingerprint sensor...");
  Serial.print("Fingerprint sensor on pins RX=");
  Serial.print(FINGERPRINT_RX);
  Serial.print(", TX=");
  Serial.println(FINGERPRINT_TX);
  
  delay(2000); // Give sensor more time to initialize
  
  if (finger.verifyPassword()) {
    Serial.println("✅ Fingerprint sensor found and working!");
    finger.getParameters();
    Serial.print("Sensor capacity: ");
    Serial.println(finger.capacity);
    Serial.print("Security level: ");
    Serial.println(finger.security_level);
    Serial.print("Currently enrolled: ");
    Serial.print(getEnrolledCount());
    Serial.print("/");
    Serial.println(maxFingerprints);
  } else {
    Serial.println("❌ Fingerprint sensor not found!");
    Serial.println("Trying different baud rates...");
    
    // Try different baud rates
    int baudRates[] = {9600, 19200, 38400, 57600, 115200};
    bool found = false;
    
    for (int i = 0; i < 5; i++) {
      Serial.print("Trying baud rate: ");
      Serial.println(baudRates[i]);
      fingerprintSerial.end();
      delay(100);
      fingerprintSerial.begin(baudRates[i], SERIAL_8N1, FINGERPRINT_RX, FINGERPRINT_TX);
      finger.begin(baudRates[i]);
      delay(1000);
      
      if (finger.verifyPassword()) {
        Serial.print("✅ Sensor found at baud rate: ");
        Serial.println(baudRates[i]);
        found = true;
        break;
      }
    }
    
    if (!found) {
      Serial.println("❌ ERROR: Fingerprint sensor not responding!");
      Serial.println("Check: 5V power, solid connections, correct wiring");
      showErrorScreen("Sensor Error");
      // Continue anyway to allow MQTT functionality
    }
  }
  
  // Start in normal scanning mode - NO ENROLLMENT
  Serial.println("🚀 System ready - Starting normal scanning mode");
  Serial.println("💡 Hold button for 3 seconds to enroll a new fingerprint");
  showReadyScreen();
}

void loop() {
  // Handle MQTT communication
  if(connectedSSID == LOCAL_SSID){
    mqttClient.loop();
  }else{
    client.loop();  // Keep listening to MQTT
  }

  // Handle long press button detection
  handleLongPressButton();

  // Check for enrollment request from long press
  if (longPressDetected && !enrollmentInProgress) {
    longPressDetected = false; // Clear the flag immediately
    enrollmentInProgress = true; // Prevent multiple enrollments
    
    Serial.println("🔴 LONG PRESS DETECTED - Starting enrollment...");
    handleSingleEnrollment();
    
    enrollmentInProgress = false; // Allow future enrollments
    Serial.println("🟢 Enrollment complete - Returning to normal mode");
  }

  // Normal fingerprint scanning (ONLY when not enrolling and not in long press)
  if (!enrollmentInProgress && !longPressActive) {
    normalModeLoop();
  }
  
  delay(10); // Small delay like in working test code
}

// ===== LONG PRESS BUTTON HANDLING =====

void handleLongPressButton() {
  // Read current button state
  bool reading = digitalRead(BUTTON_PIN);
  
  // Check if button state changed
  if (reading != lastButtonState) {
    // Reset debounce timer
    lastDebounceTime = millis();
  }
  
  // Check if enough time has passed for debounce
  if ((millis() - lastDebounceTime) > debounceDelay) {
    // If button state has actually changed
    if (reading != currentButtonState) {
      currentButtonState = reading;
      
      if (currentButtonState == LOW) {
        // Button pressed - start long press timer
        buttonPressStart = millis();
        longPressActive = true;
        Serial.println("🔘 Button pressed - Hold for 3 seconds to enroll");
        showLongPressScreen(0); // Show initial long press screen
        
      } else {
        // Button released
        if (longPressActive) {
          unsigned long pressDuration = millis() - buttonPressStart;
          if (pressDuration >= LONG_PRESS_TIME) {
            Serial.println("✅ Long press completed - Triggering enrollment!");
            longPressDetected = true;
          } else {
            Serial.print("⚠️ Button released too early (");
            Serial.print(pressDuration);
            Serial.println("ms) - Need 3 seconds");
          }
          longPressActive = false;
          showReadyScreen(); // Return to ready screen
        }
      }
    }
  }
  
  // Update long press progress display
  if (longPressActive && currentButtonState == LOW) {
    unsigned long pressDuration = millis() - buttonPressStart;
    if (pressDuration >= LONG_PRESS_TIME) {
      // Long press completed but button still held
      showLongPressScreen(100); // Show 100% complete
    } else {
      // Show progress
      int progress = (pressDuration * 100) / LONG_PRESS_TIME;
      showLongPressScreen(progress);
    }
  }
  
  // Save current reading for next loop
  lastButtonState = reading;
}

void handleSingleEnrollment() {
  // Get the next available slot (1, 2, or 3)
  uint8_t enrollSlot = getNextEnrollmentSlot();
  
  Serial.print("📝 Enrolling ONE fingerprint in slot: ");
  Serial.println(enrollSlot);
  
  // Show enrollment screen
  showEnrollScreen(enrollSlot);
  delay(500); // Brief pause to show screen
  
  // Enroll ONE fingerprint
  bool success = enrollSingleFingerprint(enrollSlot);
  
  if (success) {
    Serial.print("✅ SUCCESS: Fingerprint enrolled in slot ");
    Serial.println(enrollSlot);
    showEnrollSuccess(enrollSlot);
    delay(2000); // Show success screen
  } else {
    Serial.println("❌ FAILED: Fingerprint enrollment failed");
    showEnrollFailed();
    delay(2000); // Show failure screen
  }
  
  // IMPORTANT: Return to normal scanning mode immediately
  showReadyScreen();
  Serial.println("🔄 Back to normal fingerprint scanning mode");
}

uint8_t getNextEnrollmentSlot() {
  // Check how many fingerprints are enrolled
  int enrolledCount = getEnrolledCount();
  
  Serial.print("Currently enrolled fingerprints: ");
  Serial.println(enrolledCount);
  
  if (enrolledCount < maxFingerprints) {
    // Find next available slot (1, 2, or 3)
    for (uint8_t slot = 1; slot <= maxFingerprints; slot++) {
      if (finger.loadModel(slot) != FINGERPRINT_OK) {
        return slot;
      }
    }
  }
  
  // All slots full, cycle through them
  uint8_t slotToUse = currentEnrollSlot;
  currentEnrollSlot++;
  if (currentEnrollSlot > maxFingerprints) {
    currentEnrollSlot = 1; // Reset to slot 1
  }
  
  Serial.print("All slots full, overwriting slot: ");
  Serial.println(slotToUse);
  
  return slotToUse;
}

void normalModeLoop() {
  // Only scan when not enrolling and not in long press mode
  if (!enrollmentInProgress && !longPressActive) {
    showScanningScreen();
    int fingerprintID = getFingerprintID();
    
    if (fingerprintID > 0) {
      Serial.print("✅ Fingerprint match found: ID ");
      Serial.println(fingerprintID);
      showAccessGranted();
      unlockDoor();
      delay(2000); // Show success screen for 2 seconds
      showReadyScreen(); // Return to ready screen
    } else if (fingerprintID == -2) {
      Serial.println("❌ Fingerprint not recognized");
      showAccessDenied();
      delay(2000);
      showReadyScreen(); // Return to ready screen
    }
  }
}

// Display Functions
void showStartupScreen() {
  tft.fillScreen(ST7735_BLACK);
  drawBorder();
  
  tft.setTextColor(ST7735_CYAN);
  tft.setTextSize(2);
  tft.setCursor(15, 30);
  tft.println("SECURE");
  tft.setCursor(25, 50);
  tft.println("DOOR");
  tft.setCursor(20, 70);
  tft.println("SYSTEM");
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(1);
  tft.setCursor(25, 100);
  tft.println("Initializing...");
  
  drawLockIcon(50, 120, ST7735_YELLOW);
}

void showReadyScreen() {
  tft.fillScreen(ST7735_BLACK);
  drawBorder();
  
  tft.setTextColor(ST7735_GREEN);
  tft.setTextSize(2);
  tft.setCursor(30, 20);
  tft.println("READY");
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(1);
  tft.setCursor(15, 50);
  tft.println("Scanning for");
  tft.setCursor(20, 65);
  tft.println("fingerprints...");
  
  tft.setCursor(5, 85);
  tft.println("Hold button 3 sec");
  tft.setCursor(10, 100);
  tft.println("to enroll new ID");
  
  // Show enrolled count
  tft.setCursor(20, 120);
  tft.print("Enrolled: ");
  tft.print(getEnrolledCount());
  tft.print("/");
  tft.println(maxFingerprints);
  
  drawFingerprintIcon(45, 130, ST7735_CYAN);
}

void showScanningScreen() {
  static unsigned long lastUpdate = 0;
  static int dotCount = 0;
  
  if (millis() - lastUpdate > 500) {
    tft.fillScreen(ST7735_BLACK);
    drawBorder();
    
    tft.setTextColor(ST7735_YELLOW);
    tft.setTextSize(2);
    tft.setCursor(10, 30);
    tft.println("SCANNING");
    
    tft.setTextColor(ST7735_WHITE);
    tft.setTextSize(1);
    tft.setCursor(20, 60);
    tft.print("Detecting");
    for (int i = 0; i < dotCount; i++) {
      tft.print(".");
    }
    
    drawFingerprintIcon(40, 90, ST7735_YELLOW);
    
    dotCount = (dotCount + 1) % 4;
    lastUpdate = millis();
  }
}

void showAccessGranted() {
  tft.fillScreen(ST7735_GREEN);
  drawBorder();
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(2);
  tft.setCursor(20, 30);
  tft.println("ACCESS");
  tft.setCursor(15, 50);
  tft.println("GRANTED");
  
  tft.setTextSize(1);
  tft.setCursor(15, 80);
  tft.println("Door Unlocked");
  
  drawCheckMark(50, 100, ST7735_WHITE);
}

void showAccessDenied() {
  tft.fillScreen(ST7735_RED);
  drawBorder();
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(2);
  tft.setCursor(20, 30);
  tft.println("ACCESS");
  tft.setCursor(25, 50);
  tft.println("DENIED");
  
  tft.setTextSize(1);
  tft.setCursor(10, 80);
  tft.println("Unauthorized");
  
  drawXMark(50, 100, ST7735_WHITE);
}

void showEnrollScreen(uint8_t slot) {
  tft.fillScreen(ST7735_BLUE);
  drawBorder();
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(2);
  tft.setCursor(15, 20);
  tft.println("ENROLL");
  tft.setCursor(25, 40);
  tft.println("MODE");
  
  tft.setTextSize(1);
  tft.setCursor(10, 70);
  tft.print("Slot: ");
  tft.print(slot);
  tft.print("/");
  tft.println(maxFingerprints);
  
  tft.setCursor(10, 85);
  tft.println("Place finger");
  
  // Show if overwriting
  if (finger.loadModel(slot) == FINGERPRINT_OK) {
    tft.setCursor(10, 100);
    tft.println("Overwriting...");
  }
  
  drawPlusIcon(50, 115, ST7735_CYAN);
}

void showEnrollSuccess(uint8_t id) {
  tft.fillScreen(ST7735_GREEN);
  drawBorder();
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(2);
  tft.setCursor(10, 30);
  tft.println("ENROLLED");
  
  tft.setTextSize(1);
  tft.setCursor(25, 60);
  tft.print("ID: ");
  tft.println(id);
  tft.setCursor(20, 75);
  tft.println("Success!");
  
  drawCheckMark(50, 100, ST7735_WHITE);
}

void showEnrollFailed() {
  tft.fillScreen(ST7735_RED);
  drawBorder();
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(2);
  tft.setCursor(15, 30);
  tft.println("ENROLL");
  tft.setCursor(25, 50);
  tft.println("FAILED");
  
  tft.setTextSize(1);
  tft.setCursor(25, 80);
  tft.println("Try Again");
  
  drawXMark(50, 100, ST7735_WHITE);
}

void showErrorScreen(String message) {
  tft.fillScreen(ST7735_RED);
  drawBorder();
  
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(2);
  tft.setCursor(25, 30);
  tft.println("ERROR");
  
  tft.setTextSize(1);
  tft.setCursor(10, 60);
  tft.println(message);
  
  drawXMark(50, 90, ST7735_WHITE);
}

// Icon Drawing Functions
void drawBorder() {
  tft.drawRect(0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT, ST7735_WHITE);
  tft.drawRect(1, 1, DISPLAY_WIDTH-2, DISPLAY_HEIGHT-2, ST7735_WHITE);
}

void drawLockIcon(int x, int y, uint16_t color) {
  tft.fillRoundRect(x, y+8, 20, 15, 2, color);
  tft.drawRoundRect(x+4, y, 12, 12, 6, color);
  tft.drawRoundRect(x+5, y+1, 10, 10, 5, color);
  tft.fillCircle(x+10, y+13, 2, ST7735_BLACK);
  tft.fillRect(x+9, y+15, 2, 3, ST7735_BLACK);
}

void drawFingerprintIcon(int x, int y, uint16_t color) {
  for (int i = 0; i < 3; i++) {
    tft.drawCircle(x+10, y+10, 8+i*3, color);
  }
  tft.drawLine(x+10, y+2, x+10, y+18, color);
  tft.drawLine(x+2, y+10, x+18, y+10, color);
}

void drawCheckMark(int x, int y, uint16_t color) {
  tft.drawLine(x+5, y+10, x+8, y+13, color);
  tft.drawLine(x+8, y+13, x+15, y+6, color);
  tft.drawLine(x+5, y+11, x+8, y+14, color);
  tft.drawLine(x+8, y+14, x+15, y+7, color);
}

void drawXMark(int x, int y, uint16_t color) {
  tft.drawLine(x+5, y+5, x+15, y+15, color);
  tft.drawLine(x+15, y+5, x+5, y+15, color);
  tft.drawLine(x+5, y+6, x+14, y+15, color);
  tft.drawLine(x+14, y+5, x+5, y+14, color);
}

void drawPlusIcon(int x, int y, uint16_t color) {
  tft.drawLine(x+10, y+5, x+10, y+15, color);
  tft.drawLine(x+5, y+10, x+15, y+10, color);
  tft.drawLine(x+10, y+6, x+10, y+14, color);
  tft.drawLine(x+6, y+10, x+14, y+10, color);
}

// Core Door Lock Functions
int getFingerprintID() {
  uint8_t p = finger.getImage();
  
  if (p == FINGERPRINT_NOFINGER) {
    // No finger detected - this is normal, don't print
    return -1;
  }
  if (p == FINGERPRINT_PACKETRECIEVEERR) {
    // Only print errors occasionally to avoid spam
    static unsigned long lastErrorPrint = 0;
    if (millis() - lastErrorPrint > 2000) {
      Serial.println("Communication error");
      lastErrorPrint = millis();
    }
    return -1;
  }
  if (p == FINGERPRINT_IMAGEFAIL) {
    // Imaging error - don't spam the serial
    return -1;
  }
  if (p != FINGERPRINT_OK) {
    static unsigned long lastErrorPrint = 0;
    if (millis() - lastErrorPrint > 2000) {
      Serial.print("Unknown error: ");
      Serial.println(p);
      lastErrorPrint = millis();
    }
    return -1;
  }
  
  // Convert image to template
  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) {
    return -1;
  }
  
  // Search for match
  p = finger.fingerFastSearch();
  if (p == FINGERPRINT_PACKETRECIEVEERR) {
    return -1;
  }
  if (p == FINGERPRINT_NOTFOUND) {
    return -2; // No match found
  }
  if (p != FINGERPRINT_OK) {
    return -1;
  }
  
  // Found a match!
  Serial.print("✅ Found ID #"); 
  Serial.print(finger.fingerID);
  Serial.print(" with confidence of "); 
  Serial.println(finger.confidence);
  
  return finger.fingerID;
}

void unlockDoor() {
  digitalWrite(RELAY_PIN, HIGH);
  digitalWrite(LED_PIN, HIGH);
  Serial.println("Door unlocked via fingerprint");
  delay(5000);  // Keep door unlocked for 5 seconds
  digitalWrite(RELAY_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
  Serial.println("Door automatically locked");
}

int getEnrolledCount() {
  int count = 0;
  for (uint8_t id = 1; id <= maxFingerprints; id++) {
    if (finger.loadModel(id) == FINGERPRINT_OK) {
      count++;
    }
  }
  return count;
}

bool enrollSingleFingerprint(uint8_t id) {
  Serial.print("📝 Starting enrollment for ID: ");
  Serial.println(id);
  
  // Step 1: Get first fingerprint image
  tft.fillScreen(ST7735_BLUE);
  drawBorder();
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(1);
  tft.setCursor(10, 30);
  tft.println("Place finger on");
  tft.setCursor(10, 40);
  tft.println("scanner firmly");
  tft.setCursor(10, 55);
  tft.println("and hold...");
  
  Serial.println("👆 Waiting for finger placement...");
  
  int p = -1;
  int attempts = 0;
  while (p != FINGERPRINT_OK && attempts < 50) { // Max 50 attempts (about 10 seconds)
    p = finger.getImage();
    
    if (p == FINGERPRINT_OK) {
      Serial.println("✅ First image captured successfully");
      break;
    } else if (p == FINGERPRINT_NOFINGER) {
      // No finger detected, keep waiting
      delay(200);
      attempts++;
    } else if (p == FINGERPRINT_PACKETRECIEVEERR) {
      Serial.println("❌ Communication error");
      return false;
    } else if (p == FINGERPRINT_IMAGEFAIL) {
      Serial.println("⚠️ Image quality poor, please try again");
      delay(500);
      attempts++;
    } else {
      Serial.print("❌ Unknown error: ");
      Serial.println(p);
      return false;
    }
  }
  
  if (p != FINGERPRINT_OK) {
    Serial.println("❌ Timeout waiting for finger");
    return false;
  }
  
  // Convert first image
  p = finger.image2Tz(1);
  if (p != FINGERPRINT_OK) {
    Serial.print("❌ image2Tz(1) failed: ");
    Serial.println(p);
    return false;
  }
  
  Serial.println("🔄 Remove finger and place again...");
  
  // Step 2: Ask for finger removal
  tft.fillScreen(ST7735_ORANGE);
  drawBorder();
  tft.setTextColor(ST7735_WHITE);
  tft.setCursor(10, 40);
  tft.println("Remove finger");
  tft.setCursor(10, 55);
  tft.println("completely");
  
  delay(2000);
  
  // Wait for finger removal
  p = 0;
  attempts = 0;
  while (p != FINGERPRINT_NOFINGER && attempts < 20) {
    p = finger.getImage();
    delay(200);
    attempts++;
  }
  
  // Step 3: Get second fingerprint image
  tft.fillScreen(ST7735_BLUE);
  drawBorder();
  tft.setTextColor(ST7735_WHITE);
  tft.setCursor(10, 30);
  tft.println("Place SAME finger");
  tft.setCursor(10, 45);
  tft.println("again firmly");
  tft.setCursor(10, 60);
  tft.println("and hold...");
  
  Serial.println("👆 Waiting for same finger again...");
  
  p = -1;
  attempts = 0;
  while (p != FINGERPRINT_OK && attempts < 50) {
    p = finger.getImage();
    
    if (p == FINGERPRINT_OK) {
      Serial.println("✅ Second image captured successfully");
      break;
    } else if (p == FINGERPRINT_NOFINGER) {
      delay(200);
      attempts++;
    } else if (p == FINGERPRINT_IMAGEFAIL) {
      Serial.println("⚠️ Second image quality poor, trying again");
      delay(500);
      attempts++;
    } else {
      Serial.print("❌ Second image error: ");
      Serial.println(p);
      return false;
    }
  }
  
  if (p != FINGERPRINT_OK) {
    Serial.println("❌ Timeout waiting for second finger placement");
    return false;
  }
  
  // Convert second image
  p = finger.image2Tz(2);
  if (p != FINGERPRINT_OK) {
    Serial.print("❌ image2Tz(2) failed: ");
    Serial.println(p);
    return false;
  }
  
  // Create and store model
  Serial.println("🔨 Creating fingerprint model...");
  p = finger.createModel();
  if (p == FINGERPRINT_OK) {
    Serial.println("✅ Fingerprint model created successfully");
  } else if (p == FINGERPRINT_PACKETRECIEVEERR) {
    Serial.println("❌ Communication error during model creation");
    return false;
  } else if (p == FINGERPRINT_ENROLLMISMATCH) {
    Serial.println("❌ Fingerprints did not match - try again");
    return false;
  } else {
    Serial.print("❌ Model creation error: ");
    Serial.println(p);
    return false;
  }
  
  // Store the model
  Serial.println("💾 Storing fingerprint...");
  p = finger.storeModel(id);
  if (p == FINGERPRINT_OK) {
    Serial.println("✅ Fingerprint stored successfully!");
    return true;
  } else {
    Serial.print("❌ Storage failed: ");
    Serial.println(p);
    return false;
  }
}