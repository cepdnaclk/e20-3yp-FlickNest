#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>

// Pin definitions for XIAO ESP32S3
#define R502_TX_PIN     7   // XIAO D8 (GPIO7) - connects to R502 RXD
#define R502_RX_PIN     8   // XIAO D9 (GPIO8) - connects to R502 TXD
#define R502_WAKEUP_PIN 2   // XIAO D1 (GPIO2) - connects to R502 WAKEUP
#define R502_3V3T_PIN   1   // XIAO D0 (GPIO1) - connects to R502 3.3VT
#define RELAY_PIN       5   // XIAO D10 (GPIO5) - Relay control

// Create a hardware serial object for ESP32S3
HardwareSerial mySerial(1);  // Using UART1 for XIAO ESP32S3
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&mySerial);

uint8_t baseId;
const uint8_t ORIENTATIONS_PER_FINGER = 3; // Reduced to 3 for better reliability

void setup()
{
  Serial.begin(115200);
  delay(100);
  
  Serial.println("\n\n🔐 XIAO ESP32S3 R502 Multi-Orientation Fingerprint Enrollment");
  Serial.println("=======================================================");
  Serial.println("📋 Pin Configuration (XIAO ESP32S3):");
  Serial.println("R502 Pin 1 (VCC) -> XIAO 3.3V");
  Serial.println("R502 Pin 2 (GND) -> XIAO GND");
  Serial.println("R502 Pin 3 (TXD) -> XIAO D8 (GPIO7)");
  Serial.println("R502 Pin 4 (RXD) -> XIAO D9 (GPIO8)");
  Serial.println("R502 Pin 5 (WAKEUP) -> XIAO D1 (GPIO2)");
  Serial.println("R502 Pin 6 (3.3VT) -> XIAO D0 (GPIO1)");
  Serial.println("Relay Control -> XIAO D10 (GPIO5)");
  Serial.println("=======================================================");

  // Initialize control pins
  pinMode(R502_WAKEUP_PIN, OUTPUT);
  pinMode(R502_3V3T_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  
  // Initialize R502 control pins
  digitalWrite(R502_WAKEUP_PIN, HIGH);  // Keep sensor awake
  digitalWrite(R502_3V3T_PIN, HIGH);    // Enable 3.3V touch detection
  digitalWrite(RELAY_PIN, LOW);         // Initialize relay as OFF
  
  delay(500);

  // Initialize Serial1 with custom pins for XIAO ESP32S3
  mySerial.begin(57600, SERIAL_8N1, R502_RX_PIN, R502_TX_PIN);
  delay(500);
  
  finger.begin(57600);
  
  // Simple but reliable sensor detection
  bool sensorFound = false;
  Serial.println("🔍 Connecting to fingerprint sensor...");
  
  for(int attempts = 0; attempts < 10; attempts++) {
    if (finger.verifyPassword()) {
      Serial.println("✅ Fingerprint sensor connected!");
      sensorFound = true;
      break;
    } else {
      Serial.print("⏳ Attempt ");
      Serial.print(attempts + 1);
      Serial.println("/10...");
      delay(1000);
    }
  }
  
  if(!sensorFound) {
    Serial.println("❌ Could not find fingerprint sensor!");
    Serial.println("Check wiring:");
    Serial.println("R502 TXD -> XIAO D8 (GPIO7)");
    Serial.println("R502 RXD -> XIAO D9 (GPIO8)"); 
    Serial.println("R502 VCC -> XIAO 3.3V");
    Serial.println("R502 GND -> XIAO GND");
    Serial.println("R502 WAKEUP -> XIAO D1 (GPIO2)");
    Serial.println("R502 3.3VT -> XIAO D0 (GPIO1)");
    while (1) { delay(1000); }
  }

  // Display sensor info
  finger.getParameters();
  Serial.print("💾 Capacity: "); Serial.println(finger.capacity);
  Serial.print("🔒 Security level: "); Serial.println(finger.security_level);
  
  finger.getTemplateCount();
  Serial.print("📁 Current templates: "); Serial.println(finger.templateCount);
  
  Serial.println("\n🎯 MULTI-ORIENTATION ENROLLMENT");
  Serial.println("This will capture 3 different positions of your finger");
  Serial.println("for much better recognition accuracy!");
  Serial.println("===========================================");
}

uint8_t readnumber(void) {
  uint8_t num = 0;
  while (num == 0) {
    while (!Serial.available()) {
      delay(10);
    }
    String input = Serial.readString();
    input.trim();
    num = input.toInt();
    if (num < 1 || num > 40) { // Max 40 users (120 slots / 3 orientations)
      Serial.println("❌ Enter ID between 1-40");
      num = 0;
    }
  }
  return num;
}

void loop()
{
  Serial.println("\n👤 Enter User ID (1-40):");
  baseId = readnumber();
  
  Serial.print("🆔 Enrolling User ID: ");
  Serial.println(baseId);
  
  // Show which slots will be used
  Serial.print("📍 Using sensor slots: ");
  for(int i = 0; i < ORIENTATIONS_PER_FINGER; i++) {
    uint8_t slot = (baseId - 1) * ORIENTATIONS_PER_FINGER + i + 1;
    Serial.print(slot);
    if(i < ORIENTATIONS_PER_FINGER - 1) Serial.print(", ");
  }
  Serial.println();
  
  if (enrollMultipleOrientations()) {
    Serial.println("\n🎉 SUCCESS! User enrolled with multiple orientations!");
    Serial.println("Recognition should now be much more reliable.");
    
    // Brief relay activation to indicate success
    digitalWrite(RELAY_PIN, HIGH);
    delay(500);
    digitalWrite(RELAY_PIN, LOW);
  } else {
    Serial.println("\n❌ Enrollment failed. Please try again.");
  }
  
  delay(3000);
}

bool enrollMultipleOrientations() {
  Serial.println("\n📋 You will place your finger 3 times:");
  Serial.println("1. Normal position (center)");
  Serial.println("2. Rotated slightly (15-20 degrees)");
  Serial.println("3. Different pressure/position");
  Serial.println("");
  
  for(int orientation = 0; orientation < ORIENTATIONS_PER_FINGER; orientation++) {
    uint8_t sensorId = (baseId - 1) * ORIENTATIONS_PER_FINGER + orientation + 1;
    
    Serial.println("📍 CAPTURING ORIENTATION " + String(orientation + 1) + "/3");
    Serial.print("💾 Storing in slot: ");
    Serial.println(sensorId);
    
    switch(orientation) {
      case 0:
        Serial.println("👆 Place finger NORMALLY in center");
        break;
      case 1:
        Serial.println("🔄 Place finger ROTATED slightly");
        break;
      case 2:
        Serial.println("📍 Place finger with DIFFERENT pressure/position");
        break;
    }
    
    if (!enrollSingleFingerprint(sensorId)) {
      Serial.println("❌ Failed to enroll orientation " + String(orientation + 1));
      return false;
    }
    
    Serial.println("✅ Orientation " + String(orientation + 1) + " saved successfully!");
    
    if(orientation < ORIENTATIONS_PER_FINGER - 1) {
      Serial.println("⏳ Prepare for next capture...");
      delay(2000);
    }
  }
  
  return true;
}

bool enrollSingleFingerprint(uint8_t id) {
  int p = -1;
  
  // Get first image
  Serial.println("👆 Place finger on sensor...");
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    switch (p) {
      case FINGERPRINT_OK:
        Serial.println("📸 Image taken");
        break;
      case FINGERPRINT_NOFINGER:
        Serial.print(".");
        break;
      case FINGERPRINT_PACKETRECIEVEERR:
        Serial.println("❌ Communication error");
        break;
      case FINGERPRINT_IMAGEFAIL:
        Serial.println("❌ Imaging error");
        break;
      default:
        Serial.println("❌ Unknown error");
        break;
    }
    delay(50);
  }

  // Convert first image
  p = finger.image2Tz(1);
  switch (p) {
    case FINGERPRINT_OK:
      Serial.println("✅ Image converted");
      break;
    case FINGERPRINT_IMAGEMESS:
      Serial.println("❌ Image too messy");
      return false;
    case FINGERPRINT_PACKETRECIEVEERR:
      Serial.println("❌ Communication error");
      return false;
    case FINGERPRINT_FEATUREFAIL:
      Serial.println("❌ Could not find fingerprint features");
      return false;
    case FINGERPRINT_INVALIDIMAGE:
      Serial.println("❌ Invalid image");
      return false;
    default:
      Serial.println("❌ Unknown error");
      return false;
  }

  Serial.println("✋ Remove finger");
  delay(2000);
  
  // Wait for finger removal
  p = 0;
  while (p != FINGERPRINT_NOFINGER) {
    p = finger.getImage();
    delay(50);
  }

  // Get second image
  Serial.println("👆 Place same finger again (SAME position/angle)");
  p = -1;
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    switch (p) {
      case FINGERPRINT_OK:
        Serial.println("📸 Second image taken");
        break;
      case FINGERPRINT_NOFINGER:
        Serial.print(".");
        break;
      case FINGERPRINT_PACKETRECIEVEERR:
        Serial.println("❌ Communication error");
        break;
      case FINGERPRINT_IMAGEFAIL:
        Serial.println("❌ Imaging error");
        break;
      default:
        Serial.println("❌ Unknown error");
        break;
    }
    delay(50);
  }

  // Convert second image
  p = finger.image2Tz(2);
  switch (p) {
    case FINGERPRINT_OK:
      Serial.println("✅ Second image converted");
      break;
    case FINGERPRINT_IMAGEMESS:
      Serial.println("❌ Image too messy");
      return false;
    case FINGERPRINT_PACKETRECIEVEERR:
      Serial.println("❌ Communication error");
      return false;
    case FINGERPRINT_FEATUREFAIL:
      Serial.println("❌ Could not find fingerprint features");
      return false;
    case FINGERPRINT_INVALIDIMAGE:
      Serial.println("❌ Invalid image");
      return false;
    default:
      Serial.println("❌ Unknown error");
      return false;
  }

  // Create model
  Serial.println("🔄 Creating model...");
  p = finger.createModel();
  if (p == FINGERPRINT_OK) {
    Serial.println("✅ Prints matched!");
  } else if (p == FINGERPRINT_PACKETRECIEVEERR) {
    Serial.println("❌ Communication error");
    return false;
  } else if (p == FINGERPRINT_ENROLLMISMATCH) {
    Serial.println("❌ Fingerprints did not match - try again");
    return false;
  } else {
    Serial.println("❌ Unknown error");
    return false;
  }

  // Store model
  Serial.println("💾 Storing model...");
  p = finger.storeModel(id);
  if (p == FINGERPRINT_OK) {
    Serial.println("✅ Stored in slot " + String(id));
    return true;
  } else if (p == FINGERPRINT_PACKETRECIEVEERR) {
    Serial.println("❌ Communication error");
    return false;
  } else if (p == FINGERPRINT_BADLOCATION) {
    Serial.println("❌ Could not store in that location");
    return false;
  } else if (p == FINGERPRINT_FLASHERR) {
    Serial.println("❌ Error writing to flash");
    return false;
  } else {
    Serial.println("❌ Unknown error");
    return false;
  }
}
