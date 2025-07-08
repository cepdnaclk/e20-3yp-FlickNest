#include <Adafruit_Sensor.h>
#include <Adafruit_MPU6050.h>
#include <ArduinoJson.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <WiFiProv.h>
#include <nvs_flash.h>
#include <Preferences.h>
#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>

// Include the separated ML module
#include "GestureRecognition.h"

//////////////////////////////////////
// ====== SYSTEM CONFIGURATION ======
//////////////////////////////////////

// TIMER INTERRUPT CONFIGURATION
const unsigned long TIMER_INTERRUPT_INTERVAL = 120; // Timer interrupt interval in seconds (2 minutes)

// Timer interrupt variables
hw_timer_t *timer = NULL;
volatile bool validationRequired = false;
volatile bool mainFunctionBlocked = false;
volatile unsigned long interruptCount = 0;
bool timerStarted = false; // Track if timer has been started
bool initialAuthCompleted = false; // Track if initial authentication after WiFi is done

// Gesture mode transition tracking
bool inTransitionToGestureMode = false;
unsigned long transitionStartTime = 0;
const unsigned long TRANSITION_DURATION = 3000; // 3 seconds transition indication

// Access control variables
unsigned long lastAccess = 0;
const unsigned long TIMEOUT_INTERVAL = 10000; // 10 seconds

// Hardware pin definitions
int relayState = 0;
int relay = 5;        // GPIO5 (D10) for relay control
int wakeupPin = 2;    // GPIO2 (D1) for WAKEUP signal
int touchPin = 1;     // GPIO1 (D0) for 3.3VT (touch induction)

// Button configuration for WiFi provisioning
const int buttonPin = D10;  // Button connected to D10 with internal pullup
int buttonState = 0;        // Current button state
int lastButtonState = 0;    // Previous button state
bool provisioningRequested = false;

// Fingerprint sensor configuration
const uint8_t ORIENTATIONS_PER_FINGER = 3; // Must match enrollment
const uint8_t MIN_CONFIDENCE = 35;          // Lower threshold for better recognition

// Create a hardware serial object for XIAO ESP32S3
// Using UART1 with GPIO43 (TX) and GPIO44 (RX)
HardwareSerial mySerial(1);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&mySerial);

//====== LED CONFIGURATION ======
const int RED_PIN = D2;     // GPIO2
const int GREEN_PIN = D3;   // GPIO3 for Green LED
const int BLUE_PIN = D4;    // GPIO4
const int PWM_FREQ = 5000;
const int PWM_RESOLUTION = 8;

// MQTT Broker Configuration
const char* mqtt_server = "10.42.0.1";  // Your Raspberry Pi IP
const int mqtt_port = 1883;
const char* mqtt_topic = "test/topic";   // Single topic for publishing
const char* mqtt_client_id = "ESP32S3Client";

// WiFi and provisioning
const char *pop = "abcd1234";
const char *service_name = "PROV_FLICKNEST_BAND";
bool wifi_connected = false;
bool provisioning_complete = false;

// Hardware objects
Adafruit_MPU6050 mpu;
Preferences preferences;
WiFiClient espClient;
PubSubClient client(espClient);

// ====== GESTURE RECOGNITION MODULE ======
GestureRecognizer* gestureRecognizer = nullptr;

//////////////////////////////////////
// ====== BUTTON HANDLING ======
//////////////////////////////////////

void checkButtonPress() {
    // Read the current button state
    buttonState = digitalRead(buttonPin);
    
    // Check if button state has changed
    if (buttonState != lastButtonState) {
        // Button was pressed (LOW because of pullup)
        if (buttonState == LOW) {
            Serial.println("🔘 Button PRESSED - WiFi Provisioning Requested");
            provisioningRequested = true;
        } else {
            Serial.println("🔘 Button RELEASED");
        }
        
        // Update last button state
        lastButtonState = buttonState;
        
        // Small delay to debounce
        delay(50);
    }
}

//////////////////////////////////////
// ====== LED CONTROL FUNCTIONS ======
//////////////////////////////////////

void initializeLED() {
    // Configure pin as output first
    pinMode(GREEN_PIN, OUTPUT);
    pinMode(RED_PIN, OUTPUT);
    pinMode(BLUE_PIN, OUTPUT);
    
    // Initialize PWM
    ledcAttach(GREEN_PIN, PWM_FREQ, PWM_RESOLUTION);
    ledcAttach(RED_PIN, PWM_FREQ, PWM_RESOLUTION);
    ledcAttach(BLUE_PIN, PWM_FREQ, PWM_RESOLUTION);
    
    // Ensure LEDs are off initially
    ledcWrite(GREEN_PIN, 0);
    ledcWrite(RED_PIN, 0);
    ledcWrite(BLUE_PIN, 0);
    
    Serial.println("✅ LED system initialized");
}

void setColor(int green, int blue) {
    ledcWrite(GREEN_PIN, green);
    ledcWrite(BLUE_PIN, blue);
}

void setColorRGB(int red, int green, int blue) {
    ledcWrite(RED_PIN, red);
    ledcWrite(GREEN_PIN, green);
    ledcWrite(BLUE_PIN, blue);
}

void blinkColor(int red, int green, int blue) {
    for (int i = 0; i < 3; i++) {
        ledcWrite(RED_PIN, red);
        ledcWrite(GREEN_PIN, green);
        ledcWrite(BLUE_PIN, blue);
        delay(100);
        
        ledcWrite(RED_PIN, 0);
        ledcWrite(GREEN_PIN, 0);
        ledcWrite(BLUE_PIN, 0);
        delay(100);
    }
}

void fadeColor(int pin) {
    // Fade in
    for (int brightness = 0; brightness <= 255; brightness += 5) {
        ledcWrite(pin, brightness);
        delay(30);
    }
    
    // Fade out
    for (int brightness = 255; brightness >= 0; brightness -= 5) {
        ledcWrite(pin, brightness);
        delay(30);
    }
    
    // Turn off all
    setColor(0, 0);
    delay(200);
}

//////////////////////////////////////
// ====== GESTURE MODE TRANSITION ======
//////////////////////////////////////

void startTransitionToGestureMode() {
    inTransitionToGestureMode = true;
    transitionStartTime = millis();
    Serial.println("🔄 Transitioning to gesture detection mode...");
    Serial.println("💡 LED: CYAN - System preparing for gesture input");
}

void handleTransitionState() {
    if (inTransitionToGestureMode) {
        // Show cyan color during transition (green + blue = cyan)
        static unsigned long lastBlink = 0;
        if (millis() - lastBlink > 500) {
            static bool blinkState = false;
            if (blinkState) {
                setColor(255, 255); // Cyan color (green + blue)
            } else {
                setColor(0, 0); // Off
            }
            blinkState = !blinkState;
            lastBlink = millis();
        }
        
        // Check if transition period is over
        if (millis() - transitionStartTime > TRANSITION_DURATION) {
            inTransitionToGestureMode = false;
            setColor(0, 0); // Turn off LED - ready for gesture detection
            Serial.println("✅ Gesture detection mode ACTIVE - Ready for symbols!");
            Serial.println("💡 LED: OFF - System ready for gesture input");
            Serial.println("🤌 You can now perform gestures...");
        }
    }
}

bool isReadyForGestureDetection() {
    return wifi_connected && initialAuthCompleted && !mainFunctionBlocked && !validationRequired && !inTransitionToGestureMode;
}

//////////////////////////////////////
// ====== WIFI & MQTT FUNCTIONS ======
//////////////////////////////////////

void SysProvEvent(arduino_event_t *e) {
    switch (e->event_id) {
        case ARDUINO_EVENT_WIFI_STA_GOT_IP:
            Serial.print("📶 Connected to WiFi! IP address: ");
            Serial.println(WiFi.localIP());
            wifi_connected = true;
            break;
            
        case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
            Serial.println("📶 WiFi disconnected");
            wifi_connected = false;
            // Stop timer and reset auth when WiFi disconnects
            if (timerStarted) {
                timerStop(timer);
                timerStarted = false;
                initialAuthCompleted = false;
                validationRequired = false;
                mainFunctionBlocked = false;
                Serial.println("⏰ Timer stopped due to WiFi disconnection");
            }
            break;
            
        case ARDUINO_EVENT_PROV_START:
            Serial.println("📱 Provisioning started");
            break;
            
        case ARDUINO_EVENT_PROV_CRED_RECV:
            Serial.println("📱 Received WiFi credentials");
            break;
            
        case ARDUINO_EVENT_PROV_CRED_FAIL:
            Serial.println("📱 Provisioning failed!");
            break;
            
        case ARDUINO_EVENT_PROV_CRED_SUCCESS:
            Serial.println("📱 Provisioning successful");
            break;
            
        case ARDUINO_EVENT_PROV_END:
            Serial.println("📱 Provisioning ended");
            provisioning_complete = true;
            break;
    }
}

bool tryConnectSavedWiFi() {
    Serial.println("🔍 Checking for saved WiFi credentials...");
    
    if (WiFi.SSID().length() > 0) {
        Serial.println("📡 Found saved WiFi credentials, attempting connection...");
        Serial.println("SSID: " + WiFi.SSID());
        
        WiFi.begin();
        
        // Wait for connection with timeout
        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 20) {
            delay(1000);
            Serial.print(".");
            attempts++;
        }
        
        if (WiFi.status() == WL_CONNECTED) {
            Serial.println();
            Serial.println("✅ Connected to saved WiFi!");
            Serial.println("📶 IP address: " + WiFi.localIP().toString());
            wifi_connected = true;
            return true;
        } else {
            Serial.println();
            Serial.println("❌ Failed to connect to saved WiFi");
            return false;
        }
    } else {
        Serial.println("ℹ️ No saved WiFi credentials found");
        return false;
    }
}

void startWiFiProvisioning() {
    Serial.println("🔄 Starting WiFi provisioning...");
    
    // Disconnect from current WiFi if connected
    if (wifi_connected) {
        WiFi.disconnect();
        wifi_connected = false;
        delay(1000);
    }
    
    // Set up provisioning
    WiFi.onEvent(SysProvEvent);
    
    Serial.println("🔵 Starting BLE provisioning...");
    Serial.println("📱 Use ESP32 WiFi provisioning app to connect");
    setColor(0, 255); // Blue color for provisioning mode
    
    uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 
                        0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02};
    
    WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, 
                            NETWORK_PROV_SCHEME_HANDLER_FREE_BLE,
                            NETWORK_PROV_SECURITY_1, 
                            pop, service_name, NULL, uuid, true);
    
    Serial.println("⏳ Waiting for WiFi provisioning...");
    unsigned long prov_start = millis();
    while (!wifi_connected && (millis() - prov_start < 120000)) { // 2 minute timeout
        delay(1000);
        Serial.print(".");
        if ((millis() - prov_start) % 30000 == 0) {
            Serial.println();
            Serial.println("💡 Still waiting... Make sure to:");
            Serial.println("   1. Use WiFi provisioning app on phone");
            Serial.println("   2. Connect phone to '" + String(service_name) + "'");
        }
    }
    
    if (wifi_connected) {
        Serial.println();
        Serial.println("✅ WiFi provisioning successful!");
        setColor(0, 0); // Turn off LED
        provisioningRequested = false;
    } else {
        Serial.println();
        Serial.println("❌ WiFi provisioning failed!");
        blinkColor(255, 0, 0); // Red blink for error
        setColor(0, 0); // Turn off LED
        provisioningRequested = false;
    }
}

void connectMQTT() {
    if (!wifi_connected) {
        Serial.println("📶 WiFi not connected, skipping MQTT connection");
        return;
    }
    
    Serial.println("📡 Connecting to local MQTT broker...");
    Serial.printf("📡 Connecting to %s:%d\n", mqtt_server, mqtt_port);
    
    client.setServer(mqtt_server, mqtt_port);
    client.setKeepAlive(60);  // Keep connection alive
    client.setSocketTimeout(5);  // 5 second timeout
    
    int attempts = 0;
    while (!client.connected() && attempts < 3) {  // Reduced attempts
        Serial.printf("📡 MQTT connection attempt %d/3\n", attempts + 1);
        
        if (client.connect(mqtt_client_id)) {
            Serial.println("✅ Connected to MQTT broker!");
            
            JsonDocument statusDoc;
            statusDoc["connected"] = true;
            statusDoc["system"] = "main_system";
            statusDoc["client_id"] = mqtt_client_id;
            statusDoc["ip"] = WiFi.localIP().toString();
            publishMessage(statusDoc);
            
            break;
        } else {
            Serial.print("❌ MQTT failed, rc=");
            Serial.print(client.state());
            Serial.println(" (rc meanings: -4=timeout, -3=lost, -2=refused, -1=bad protocol, 0=ok)");
            delay(1000);  // Shorter delay
            attempts++;
        }
    }
    
    if (!client.connected()) {
        Serial.println("❌ Failed to connect to MQTT broker - check if mosquitto is running on Pi");
    }
}

void publishMessage(JsonDocument &doc) {
    if (!client.connected()) {
        Serial.println("❌ MQTT not connected - cannot publish");
        return;
    }
    
    char jsonBuffer[512];
    serializeJson(doc, jsonBuffer);
    
    Serial.printf("📤 Publishing to %s: %s\n", mqtt_topic, jsonBuffer);
    
    if (client.publish(mqtt_topic, jsonBuffer)) {
        Serial.println("✅ Message published successfully");
    } else {
        Serial.println("❌ Failed to publish message");
        Serial.printf("MQTT state: %d\n", client.state());
    }
}

void handleWiFiReconnection() {
    static unsigned long last_wifi_check = 0;
    
    if (millis() - last_wifi_check > 30000) { // Check every 30 seconds
        if (!wifi_connected && WiFi.status() != WL_CONNECTED) {
            Serial.println("📶 WiFi disconnected, attempting to reconnect...");
            
            // Try to reconnect to saved WiFi
            if (tryConnectSavedWiFi()) {
                Serial.println("✅ Reconnected to WiFi");
            } else {
                Serial.println("❌ Failed to reconnect - press button to start provisioning");
            }
        }
        last_wifi_check = millis();
    }
}

//////////////////////////////////////
// ====== TIMER INTERRUPT SYSTEM ======
//////////////////////////////////////

/// Timer interrupt handler (MUST be IRAM_ATTR)
void IRAM_ATTR onTimerInterrupt() {
    interruptCount++;
    validationRequired = true;
    mainFunctionBlocked = true;
}

// Function to start timer after WiFi connection
void startTimerInterrupt() {
    if (!timerStarted && wifi_connected) {
        timer = timerBegin(1000000); // 1MHz frequency (1 microsecond resolution)
        timerAttachInterrupt(timer, &onTimerInterrupt);
        timerAlarm(timer, TIMER_INTERRUPT_INTERVAL * 1000000, true, 0); // Convert seconds to microseconds with auto-reload
        timerStarted = true;
        Serial.printf("✅ Timer interrupt started - %lu second recurring validation timer active\n", TIMER_INTERRUPT_INTERVAL);
    }
}

//////////////////////////////////////
// ====== FINGERPRINT FUNCTIONS ======
//////////////////////////////////////

// IMPROVED: Better error handling and non-blocking fingerprint reading
int getFingerprintID() {
    // Step 1: Get image (non-blocking check)
    uint8_t p = finger.getImage();
    
    if (p == FINGERPRINT_NOFINGER) {
        return -1; // No finger detected - return immediately
    }
    
    if (p == FINGERPRINT_PACKETRECIEVEERR) {
        Serial.println("⚠️ Communication error");
        return -2;
    }
    
    if (p == FINGERPRINT_IMAGEFAIL) {
        Serial.println("⚠️ Imaging error");
        return -3;
    }
    
    if (p != FINGERPRINT_OK) {
        return -4;
    }

    Serial.println("📸 Image captured");

    // Step 2: Convert to template
    p = finger.image2Tz();
    
    if (p == FINGERPRINT_IMAGEMESS) {
        Serial.println("⚠️  Image too messy - try again");
        return -5;
    }
    
    if (p == FINGERPRINT_PACKETRECIEVEERR) {
        Serial.println("⚠️ Communication error during template conversion");
        return -6;
    }
    
    if (p == FINGERPRINT_FEATUREFAIL) {
        Serial.println("❌ Could not find features - try different placement");
        return -7;
    }
    
    if (p == FINGERPRINT_INVALIDIMAGE) {
        Serial.println("❌ Invalid image");
        return -8;
    }
    
    if (p != FINGERPRINT_OK) {
        return -9;
    }

    Serial.println("✅ Template created");

    // Step 3: Search for match
    Serial.println("🔍 Searching database...");
    p = finger.fingerSearch();
    
    if (p == FINGERPRINT_PACKETRECIEVEERR) {
        Serial.println("⚠️ Communication error during search");
        return -10;
    }
    
    if (p == FINGERPRINT_NOTFOUND) {
        Serial.println("❌ ACCESS DENIED - Fingerprint not found");
        return -11;
    }
    
    if (p != FINGERPRINT_OK) {
        return -12;
    }

    // Check confidence level
    if (finger.confidence < MIN_CONFIDENCE) {
        Serial.println("⚠️  Low confidence: " + String(finger.confidence) + "% - try again");
        return -13;
    }

    // Success!
    Serial.println("✅ MATCH FOUND!");
    blinkColor(0,255,0);
    Serial.println("Sensor ID: " + String(finger.fingerID));
    Serial.println("Confidence: " + String(finger.confidence) + "%");
    
    return finger.fingerID;
}

uint8_t convertSensorIdToUserId(uint8_t sensorId) {
    // Convert sensor template ID back to user ID
    return ((sensorId - 1) / ORIENTATIONS_PER_FINGER) + 1;
}

void handleAccessGranted(uint8_t userId, uint8_t sensorId) {
    Serial.println("\n🎉 ACCESS GRANTED!");
    Serial.println("==================");
    Serial.println("👤 User ID: " + String(userId));
    Serial.println("📍 Matched Template: " + String(sensorId));
    Serial.println("🎯 Confidence: " + String(finger.confidence) + "%");
    
    // Determine which orientation was matched
    uint8_t orientation = ((sensorId - 1) % ORIENTATIONS_PER_FINGER) + 1;
    Serial.println("🔄 Orientation: " + String(orientation) + "/3");
    
    // Toggle relay state
    if(relayState == 0) {
        lastAccess = millis(); // Reset access time
        relayState = 1;
        digitalWrite(relay, HIGH); // Turn relay ON
        Serial.println("🔓 RELAY ON - Access Granted");
        
        delay(3000);
        
        // Auto-lock after delay
        digitalWrite(relay, LOW);
        relayState = 0;
        Serial.println("🔒 RELAY OFF - Auto-locked");
        
    } else {
        digitalWrite(relay, LOW);
        relayState = 0;
        Serial.println("🔒 RELAY OFF - Manual Lock");
        delay(2000);
    }
    
    Serial.println("==================");
    
    // Quick finger removal check (minimal blocking)
    Serial.println("✋ Remove finger to continue...");
    unsigned long removeStartTime = millis();
    while (finger.getImage() == FINGERPRINT_OK && (millis() - removeStartTime < 2000)) {
        delay(100);
    }
    
    // Start transition to gesture mode
    startTransitionToGestureMode();
    
    Serial.println("🔍 Preparing for gesture detection...");
    Serial.println("=======================================================");
}

// IMPROVED: More responsive validation handler
void handleFingerprintValidation() {
    // Show status message periodically
    static unsigned long lastStatusMsg = 0;
    if (millis() - lastStatusMsg > 2000) {
        if (validationRequired && !initialAuthCompleted) {
            Serial.println("🔐 INITIAL AUTHENTICATION REQUIRED - Please authenticate to start using the system...");
        } else {
            Serial.println("🚫 MAIN FUNCTIONS BLOCKED - Please validate fingerprint to continue...");
            Serial.println("⏰ Timer interrupt #" + String(interruptCount) + " triggered - Validation required");
        }
        fadeColor(BLUE_PIN);
        Serial.print("🔍 Place finger on sensor... ");
        lastStatusMsg = millis();
    }
    
    // Check for fingerprint validation
    int result = getFingerprintID();
    if (result >= 0) {
        // Valid fingerprint found - validation successful
        uint8_t userId = convertSensorIdToUserId(result);
        
        if (!initialAuthCompleted) {
            Serial.println("\n✅ INITIAL AUTHENTICATION SUCCESSFUL!");
            Serial.println("🔓 System UNLOCKED and ready for normal operation");
            initialAuthCompleted = true;
            
            // Start the timer after initial authentication
            startTimerInterrupt();
            Serial.printf("⏰ Recurring timer started - next validation in %lu seconds\n", TIMER_INTERRUPT_INTERVAL);
        } else {
            Serial.println("\n✅ VALIDATION SUCCESSFUL!");
            Serial.println("🔓 Main functions UNLOCKED");
            Serial.printf("⏱️  Timer continues running for next %lu-second cycle\n", TIMER_INTERRUPT_INTERVAL);
        }
        
        // Reset validation flags
        validationRequired = false;
        mainFunctionBlocked = false;
        
        // Handle access control
        handleAccessGranted(userId, result);
        
        Serial.println("🔄 Returning to main function...");
        if (initialAuthCompleted) {
            Serial.printf("⏳ Next validation required in %lu seconds from now\n", TIMER_INTERRUPT_INTERVAL);
        }
    }
    // If no finger or error, continue waiting (no delays to block the system)
}

// Function to handle initial authentication requirement
void handleInitialAuthentication() {
    static unsigned long lastStatusMsg = 0;
    if (millis() - lastStatusMsg > 3000) {
        Serial.println("🔐 SYSTEM LOCKED - Initial fingerprint authentication required");
        Serial.println("📱 WiFi connected successfully - please authenticate to proceed");
        Serial.println("🔍 Place finger on sensor to unlock system...");
        fadeColor(BLUE_PIN);
        lastStatusMsg = millis();
    }
    
    // Check for fingerprint authentication
    int result = getFingerprintID();
    if (result >= 0) {
        uint8_t userId = convertSensorIdToUserId(result);
        
        Serial.println("\n✅ INITIAL AUTHENTICATION SUCCESSFUL!");
        Serial.println("🔓 System UNLOCKED - All functions now available");
        Serial.println("👤 Authenticated User ID: " + String(userId));
        
        initialAuthCompleted = true;
        
        // Start the timer for recurring validations
        startTimerInterrupt();
        
        // Handle the access granted (this will start transition mode)
        handleAccessGranted(userId, result);
        
        Serial.println("🚀 System ready for normal operation!");
        Serial.printf("⏰ Next automatic validation in %lu seconds\n", TIMER_INTERRUPT_INTERVAL);
    }
}

//////////////////////////////////////
// ====== MAIN SETUP & LOOP ======
//////////////////////////////////////

void setup() {
    Serial.begin(115200);
    delay(1000);
    
    Serial.println("🚀 Starting Integrated Wristband System...");
    Serial.println("============================================");
    
    // BUTTON SETUP
    pinMode(buttonPin, INPUT_PULLUP);
    Serial.println("✅ Button setup complete - Press button to start WiFi provisioning");
    
    // TIMER INTERRUPT SETUP - DO NOT START YET
    Serial.printf("✅ Timer interrupt configured - %lu second interval (will start after WiFi + authentication)\n", TIMER_INTERRUPT_INTERVAL);
    
    // HARDWARE PIN SETUP
    pinMode(relay, OUTPUT);
    pinMode(wakeupPin, OUTPUT);
    pinMode(touchPin, INPUT_PULLUP);
    
    digitalWrite(relay, LOW);      // Initialize relay as OFF
    digitalWrite(wakeupPin, HIGH); // Keep sensor always awake
    delay(100);

    // FINGERPRINT SENSOR SETUP
    mySerial.begin(57600, SERIAL_8N1, 7, 8);
    delay(1000);
    finger.begin(57600);
    
    // Enhanced sensor detection with multiple attempts
    bool sensorFound = false;
    Serial.println("🔍 Connecting to fingerprint sensor...");
    
    for(int attempts = 0; attempts < 15; attempts++) {
        Serial.print("⏳ Attempt " + String(attempts + 1) + "/15... ");
        
        // Try different approaches to establish connection
        if(attempts > 5) {
            // Reset UART connection
            mySerial.end();
            delay(500);
            mySerial.begin(57600, SERIAL_8N1, 7, 8);
            delay(500);
            finger.begin(57600);
        }
        
        if (finger.verifyPassword()) {
            Serial.println("✅ Connected!");
            sensorFound = true;
            break;
        } else {
            Serial.println("❌ Failed");
            delay(1000);
        }
    }
    
    if(!sensorFound) {
        Serial.println("\n❌ SENSOR CONNECTION FAILED!");
        Serial.println("🔧 Troubleshooting Tips:");
        Serial.println("1. Check all wiring connections");
        Serial.println("2. Ensure R502 has stable 3.3V power");
        Serial.println("3. Verify TX/RX pins are not swapped");
        Serial.println("4. Check if sensor LED lights up");
        Serial.println("5. Try different baud rates if needed");
        while (1) { 
            Serial.println("System halted - fix connections and restart");
            delay(5000); 
        }
    }

    // Display sensor information
    Serial.println("\n📊 Fingerprint Sensor Information:");
    finger.getParameters();
    Serial.println("Status: 0x" + String(finger.status_reg, HEX));
    Serial.println("Capacity: " + String(finger.capacity));
    Serial.println("Security Level: " + String(finger.security_level));
    Serial.println("Baud Rate: " + String(finger.baud_rate));

    finger.getTemplateCount();
    Serial.println("Enrolled Templates: " + String(finger.templateCount));
    
    if (finger.templateCount == 0) {
        Serial.println("\n⚠️  No fingerprints enrolled!");
        Serial.println("Run enrollment code first.");
        delay(3000);
    } else {
        int estimatedUsers = finger.templateCount / ORIENTATIONS_PER_FINGER;
        Serial.println("Estimated Users: ~" + String(estimatedUsers));
    }
    
    Serial.println("\n🚀 Fingerprint System Ready!");
    Serial.println("🔍 Will require authentication after WiFi connection...");
    
    // LED SYSTEM SETUP
    initializeLED();
    
    // MPU6050 SETUP
    Wire.begin(D6, D7);
    
    if (!mpu.begin()) {
        Serial.println("❌ Failed to find MPU6050 chip");
        while (1) delay(10);
    }
    
    Serial.println("✅ MPU6050 Found!");
    mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
    mpu.setGyroRange(MPU6050_RANGE_250_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ); // Lower bandwidth for stability
    
    // GESTURE RECOGNITION SETUP
    gestureRecognizer = new GestureRecognizer(&mpu);
    if (!gestureRecognizer->initialize()) {
        Serial.println("❌ Failed to initialize ML module");
        while (1) delay(1000);
    }
    
    // UNPLUG CABLE DELAY - Give user time to disconnect from USB
    Serial.println("🔴 RED LED ON - UNPLUG CABLE NOW!");
    Serial.println("⏰ You have 5 seconds to unplug the wristband from COM port");
    Serial.println("📱 This ensures accurate sensor calibration on battery power");
    Serial.println("⏳ Calibration will start after countdown...");
    
    // Turn on red LED to indicate unplug time
    setColorRGB(255, 0, 0); // Red LED on
    
    // 5-second countdown with serial feedback
    for (int i = 5; i >= 1; i--) {
        Serial.printf("⏳ %d... (UNPLUG NOW if still connected)\n", i);
        delay(1000);
    }
    
    // Turn off red LED - calibration starting
    setColorRGB(0, 0, 0); // Turn off all LEDs
    Serial.println("🔴 RED LED OFF - Starting calibration...");
    Serial.println("📏 Keep device still for calibration");
    
    // Now calibrate the sensor
    gestureRecognizer->calibrateSensor();
    
    // WIFI SETUP - TRY SAVED CREDENTIALS FIRST
    Serial.println("🔍 Attempting to connect to WiFi...");
    
    // Try to connect to saved WiFi credentials first
    if (!tryConnectSavedWiFi()) {
        Serial.println("❌ No saved WiFi or connection failed");
        Serial.println("🔘 Press button to start WiFi provisioning");
        
        // Wait for button press to start provisioning
        while (!provisioningRequested) {
            checkButtonPress();
            delay(100);
        }
        
        startWiFiProvisioning();
    }
    
    // MQTT SETUP
    if (wifi_connected) {
        connectMQTT();
        
        // Test MQTT connection with a simple message
        if (client.connected()) {
            Serial.println("✅ MQTT connection successful - sending test message");
            JsonDocument testDoc;
            testDoc["system_status"] = "wifi_connected_auth_pending";
            testDoc["modules"] = "fingerprint+gesture+mqtt";
            testDoc["timestamp"] = millis();
            publishMessage(testDoc);
        } else {
            Serial.println("❌ MQTT connection failed - gestures will not be published");
        }
    }
    
    Serial.println("============================================");
    Serial.println("🎉 INTEGRATED WRISTBAND SYSTEM READY!");
    Serial.println("✅ Fingerprint Authentication: ACTIVE");
    Serial.println("✅ Gesture Recognition: STANDBY");
    Serial.println("✅ MQTT Publishing: " + String(wifi_connected ? "ACTIVE" : "INACTIVE"));
    if (wifi_connected) {
        Serial.println("🔐 Status: WiFi connected - INITIAL AUTHENTICATION REQUIRED");
        Serial.printf("⏰ Timer will start after authentication (%lu second intervals)\n", TIMER_INTERRUPT_INTERVAL);
    } else {
        Serial.println("⚠️  Status: No WiFi - Timer disabled");
    }
    Serial.println("🔘 Button Control: Press to reconfigure WiFi");
    Serial.println("============================================");
    
    setColor(0, 0);
    delay(20);
    
    if (wifi_connected) {
        // Show blue light indicating WiFi connected but authentication required
        setColor(0, 255); // Blue for authentication required
    } else {
        blinkColor(0, 255, 0); // Green blink for ready but no WiFi
    }
}

void loop() {
    // Check for button press to trigger WiFi provisioning
    checkButtonPress();
    
    // Handle WiFi provisioning if requested
    if (provisioningRequested) {
        startWiFiProvisioning();
    }
    
    // WiFi connection management
    handleWiFiReconnection();
    
    // MQTT connection check (less aggressive)
    static unsigned long last_mqtt_check = 0;
    if (millis() - last_mqtt_check > 30000) { // Check every 30 seconds
        if (wifi_connected && !client.connected()) {
            Serial.println("🔄 Attempting to reconnect to MQTT...");
            connectMQTT();
        }
        last_mqtt_check = millis();
    } 
    
    // Only run MQTT loop if connected
    if (client.connected()) {
        client.loop();
    }

    // PRIORITY 1: If WiFi connected but initial auth not completed, require authentication
    if (wifi_connected && !initialAuthCompleted) {
        handleInitialAuthentication();
        return; // Skip everything else until initial authentication complete
    }

    // PRIORITY 2: Check if validation is required (triggered by interrupt)
    if (validationRequired) {
        handleFingerprintValidation();
        return; // Skip everything else until validation complete
    }

    // PRIORITY 3: Handle transition state to gesture mode
    if (inTransitionToGestureMode) {
        handleTransitionState();
        return; // Skip other operations during transition
    }

    // MAIN GESTURE DETECTION (only runs when system is fully ready)
    if (isReadyForGestureDetection() && gestureRecognizer) {
        GestureResult result = gestureRecognizer->detectGesture();
        
        // If a gesture was confirmed, publish it via MQTT
        if (result.is_confirmed && client.connected()) {
            JsonDocument gestureDoc = gestureRecognizer->createGestureJSON(result);
            publishMessage(gestureDoc);
            
            // Visual feedback for confirmed gesture
            blinkColor(0,255,0);
        }
    }
    
    // FINGERPRINT ACCESS CONTROL (when not in validation mode and system is authenticated)
    if (wifi_connected && initialAuthCompleted && !validationRequired && !inTransitionToGestureMode) {
        int result = getFingerprintID();
        if (result >= 0) {
            // Valid fingerprint found for access control
            uint8_t userId = convertSensorIdToUserId(result);
            handleAccessGranted(userId, result);
        }
    }
    
    yield(); // Prevent watchdog timeout
}