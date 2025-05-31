#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>

int relayState = 0;
int relay = 5;        // GPIO5 for relay control
int wakeupPin = 4;    // GPIO4 for WAKEUP signal
int touchPin = 2;     // GPIO2 for 3.3VT (touch induction)

const uint8_t ORIENTATIONS_PER_FINGER = 3; // Must match enrollment
const uint8_t MIN_CONFIDENCE = 35;          // Lower threshold for better recognition

// Create a hardware serial object for ESP32
HardwareSerial mySerial(2);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&mySerial);

void setup()
{
  pinMode(relay, OUTPUT);
  pinMode(wakeupPin, OUTPUT);
  pinMode(touchPin, INPUT_PULLUP);
  
  digitalWrite(relay, LOW);      // Initialize relay as OFF
  digitalWrite(wakeupPin, HIGH); // Keep sensor always awake
  
  Serial.begin(115200);
  delay(100);
  
  Serial.println("\n\n🔐 ESP32 R502 Multi-Orientation Validation System");
  Serial.println("================================================");
  Serial.println("📋 Pin Configuration:");
  Serial.println("R502 Pin 1 (VCC) -> ESP32 3.3V");
  Serial.println("R502 Pin 2 (GND) -> ESP32 GND");
  Serial.println("R502 Pin 3 (TXD) -> ESP32 GPIO16");
  Serial.println("R502 Pin 4 (RXD) -> ESP32 GPIO17");
  Serial.println("R502 Pin 5 (WAKEUP) -> ESP32 GPIO4");
  Serial.println("R502 Pin 6 (3.3VT) -> ESP32 GPIO2");
  Serial.println("Relay Control -> ESP32 GPIO5");
  Serial.println("================================================");

  // Initialize Serial2 with custom pins
  mySerial.begin(57600, SERIAL_8N1, 16, 17);
  delay(1000);
  
  finger.begin(57600);
  
  // Simple reliable sensor detection
  bool sensorFound = false;
  Serial.println("🔍 Connecting to fingerprint sensor...");
  
  for(int attempts = 0; attempts < 10; attempts++) {
    Serial.print("⏳ Attempt " + String(attempts + 1) + "/10... ");
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
    Serial.println("Check all connections and restart");
    setLEDError();
    while (1) { delay(1000); }
  }

  // Display sensor information
  Serial.println("\n📊 Sensor Information:");
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
    setLEDError();
    delay(3000);
  } else {
    int estimatedUsers = finger.templateCount / ORIENTATIONS_PER_FINGER;
    Serial.println("Estimated Users: ~" + String(estimatedUsers));
  }
  
  Serial.println("\n🚀 System Ready!");
  Serial.println("💡 LED Indicators:");
  Serial.println("🔵 Blue: Ready - Place finger");
  Serial.println("🟣 Purple: Processing...");
  Serial.println("🟢 Green: Access Granted");
  Serial.println("🔴 Red: Access Denied");
  Serial.println("📍 Red Blinking: Error");
  Serial.println("🔍 Place finger on sensor to authenticate...");
  Serial.println("================================================");
  
  // Set initial LED state - Ready (Blue)
  setLEDReady();
}

void loop()
{
  int result = getFingerprintID();
  
  if (result >= 0) {
    // Valid fingerprint found
    uint8_t userId = convertSensorIdToUserId(result);
    handleAccessGranted(userId, result);
  } else if (result != -1) {
    // Error occurred (but not "no finger")
    Serial.println("❌ Recognition error occurred");
    setLEDFailed();
    delay(2000);
    setLEDReady(); // Return to ready state
  }
  // If result == -1, it's just "no finger" so continue silently
  
  delay(50); // Reduced delay for more responsive feel
}

int getFingerprintID() {
  // Step 1: Get image
  uint8_t p = finger.getImage();
  
  if (p == FINGERPRINT_NOFINGER) {
    return -1; // No finger detected
  }
  
  // Finger detected - show processing LED
  setLEDProcessing();
  
  if (p == FINGERPRINT_PACKETRECIEVEERR) {
    Serial.println("❌ Communication error");
    return -2;
  }
  
  if (p == FINGERPRINT_IMAGEFAIL) {
    Serial.println("❌ Imaging error - try better placement");
    return -3;
  }
  
  if (p != FINGERPRINT_OK) {
    Serial.println("❌ Image error: " + String(p));
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
    Serial.println("❌ Communication error");
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
    Serial.println("❌ Conversion error: " + String(p));
    return -9;
  }

  Serial.println("✅ Template created");

  // Step 3: Search for match
  Serial.println("🔍 Searching database...");
  p = finger.fingerSearch();
  
  if (p == FINGERPRINT_PACKETRECIEVEERR) {
    Serial.println("❌ Communication error during search");
    return -10;
  }
  
  if (p == FINGERPRINT_NOTFOUND) {
    Serial.println("❌ ACCESS DENIED - Fingerprint not found");
    return -11;
  }
  
  if (p != FINGERPRINT_OK) {
    Serial.println("❌ Search error: " + String(p));
    return -12;
  }

  // Check confidence level
  if (finger.confidence < MIN_CONFIDENCE) {
    Serial.println("⚠️  Low confidence: " + String(finger.confidence) + "% - try again");
    return -13;
  }

  // Success!
  Serial.println("✅ MATCH FOUND!");
  Serial.println("Sensor ID: " + String(finger.fingerID));
  Serial.println("Confidence: " + String(finger.confidence) + "%");
  
  return finger.fingerID;
}

uint8_t convertSensorIdToUserId(uint8_t sensorId) {
  // Convert sensor template ID back to user ID
  return ((sensorId - 1) / ORIENTATIONS_PER_FINGER) + 1;
}

void handleAccessGranted(uint8_t userId, uint8_t sensorId) {
  // Show success LED immediately
  setLEDSuccess();
  
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
    digitalWrite(relay, HIGH);
    relayState = 1;
    Serial.println("🔓 RELAY ON - Door Unlocked");
    
    // Keep success LED for 3 seconds
    delay(3000);
    
    // Auto-lock after showing success
    digitalWrite(relay, LOW);
    relayState = 0;
    Serial.println("🔒 RELAY OFF - Auto-locked");
    
  } else {
    digitalWrite(relay, LOW);
    relayState = 0;
    Serial.println("🔒 RELAY OFF - Manual Lock");
    delay(2000); // Show success for 2 seconds
  }
  
  Serial.println("==================");
  
  // Wait for finger removal with timeout
  Serial.println("✋ Remove finger...");
  unsigned long removeStartTime = millis();
  while (finger.getImage() == FINGERPRINT_OK && (millis() - removeStartTime < 10000)) {
    delay(100);
  }
  
  Serial.println("🔍 Ready for next scan...");
  Serial.println("================================================");
  
  // Return to ready state
  setLEDReady();
}

// LED Control Functions using R502 built-in LED
void setLEDReady() {
  // Blue LED - Ready for fingerprint
  finger.LEDcontrol(true);
  delay(100);
  finger.LEDcontrol(false);
  delay(100);
  finger.LEDcontrol(true); // Blinking effect for ready
}

void setLEDProcessing() {
  // Fast blinking during processing
  for(int i = 0; i < 3; i++) {
    finger.LEDcontrol(true);
    delay(200);
    finger.LEDcontrol(false);
    delay(200);
  }
  finger.LEDcontrol(true); // Keep on during processing
}

void setLEDSuccess() {
  // Steady on for success
  finger.LEDcontrol(true);
}

void setLEDFailed() {
  // Quick flashes for failure
  for(int i = 0; i < 5; i++) {
    finger.LEDcontrol(true);
    delay(100);
    finger.LEDcontrol(false);
    delay(100);
  }
}

void setLEDError() {
  // Rapid blinking for error
  for(int i = 0; i < 10; i++) {
    finger.LEDcontrol(true);
    delay(50);
    finger.LEDcontrol(false);
    delay(50);
  }
}

void setLEDOff() {
  // Turn off LED
  finger.LEDcontrol(false);
}
