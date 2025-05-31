#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>

// Create a hardware serial object for ESP32
// Using Serial2 (GPIO16=RX2, GPIO17=TX2)
HardwareSerial mySerial(2);

Adafruit_Fingerprint finger = Adafruit_Fingerprint(&mySerial);

uint8_t baseId;
const uint8_t ORIENTATIONS_PER_FINGER = 4; // Number of different orientations to capture

void setup()
{
  Serial.begin(115200);
  delay(100);
  Serial.println("\n\n🔐 ESP32 R502 Enhanced Fingerprint Enrollment System");
  Serial.println("📱 Multi-Orientation Capture (Like Smartphone)");
  Serial.println("==============================================");

  // Initialize Serial2 with custom pins
  mySerial.begin(57600, SERIAL_8N1, 16, 17);
  delay(500);
  
  finger.begin(57600);
  
  // Enhanced sensor detection with better error handling
  bool sensorFound = false;
  Serial.println("🔍 Searching for fingerprint sensor...");
  
  for(int attempts = 0; attempts < 10; attempts++) {
    if (finger.verifyPassword()) {
      Serial.println("✅ Fingerprint sensor connected successfully!");
      sensorFound = true;
      break;
    } else {
      Serial.print("⏳ Attempt ");
      Serial.print(attempts + 1);
      Serial.println("/10 - Retrying connection...");
      delay(800);
    }
  }
  
  if(!sensorFound) {
    Serial.println("❌ SENSOR CONNECTION FAILED!");
    Serial.println("📋 Check these connections:");
    Serial.println("   R502 Pin 1 (VCC) -> ESP32 3.3V");
    Serial.println("   R502 Pin 2 (GND) -> ESP32 GND");
    Serial.println("   R502 Pin 3 (TXD) -> ESP32 GPIO16");
    Serial.println("   R502 Pin 4 (RXD) -> ESP32 GPIO17");
    while (1) { delay(1000); }
  }

  // Display sensor information
  Serial.println("📊 Reading sensor parameters...");
  finger.getParameters();
  Serial.print("💾 Storage Capacity: "); Serial.println(finger.capacity);
  Serial.print("🔒 Security Level: "); Serial.println(finger.security_level);
  Serial.print("📡 Baud Rate: "); Serial.println(finger.baud_rate);
  
  finger.getTemplateCount();
  Serial.print("📁 Current Templates: "); Serial.println(finger.templateCount);
  Serial.print("💽 Available Slots: "); Serial.println(finger.capacity - finger.templateCount);
  
  Serial.println("\n🎯 ENHANCED ENROLLMENT PROCESS");
  Serial.println("This system will capture multiple orientations of your finger");
  Serial.println("for better recognition accuracy (like smartphone enrollment)");
  Serial.println("=======================================================");
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
    if (num < 1 || num > (finger.capacity / ORIENTATIONS_PER_FINGER)) {
      Serial.print("❌ Invalid ID! Enter between 1 and ");
      Serial.println(finger.capacity / ORIENTATIONS_PER_FINGER);
      num = 0;
    }
  }
  return num;
}

void loop()
{
  Serial.println("\n👤 FINGERPRINT ENROLLMENT");
  Serial.println("========================");
  Serial.print("Enter User ID (1-");
  Serial.print(finger.capacity / ORIENTATIONS_PER_FINGER);
  Serial.println("):");
  
  baseId = readnumber();
  
  Serial.print("🆔 Enrolling User ID: ");
  Serial.println(baseId);
  Serial.print("📍 Will use sensor slots: ");
  
  // Calculate the actual sensor IDs this user will occupy
  for(int i = 0; i < ORIENTATIONS_PER_FINGER; i++) {
    Serial.print((baseId - 1) * ORIENTATIONS_PER_FINGER + i + 1);
    if(i < ORIENTATIONS_PER_FINGER - 1) Serial.print(", ");
  }
  Serial.println();
  
  Serial.println("\n🚀 Starting multi-orientation enrollment...");
  delay(2000);
  
  if (enrollMultipleOrientations()) {
    Serial.println("\n🎉 SUCCESS! Fingerprint enrollment completed!");
    Serial.println("✨ Your finger has been registered with multiple orientations");
    Serial.println("📱 Recognition accuracy should now be significantly improved");
  } else {
    Serial.println("\n❌ Enrollment failed. Please try again.");
  }
  
  Serial.println("\n" + String('=', 50));
  delay(3000);
}

bool enrollMultipleOrientations() {
  Serial.println("\n📋 ENROLLMENT INSTRUCTIONS:");
  Serial.println("1. You'll be asked to place your finger " + String(ORIENTATIONS_PER_FINGER) + " times");
  Serial.println("2. Each time, place your finger slightly differently:");
  Serial.println("   - Different angles (rotate finger)");
  Serial.println("   - Different positions (center, left, right)");
  Serial.println("   - Different pressure levels");
  Serial.println("3. This mimics smartphone fingerprint enrollment");
  Serial.println("");
  
  for(int orientation = 0; orientation < ORIENTATIONS_PER_FINGER; orientation++) {
    uint8_t sensorId = (baseId - 1) * ORIENTATIONS_PER_FINGER + orientation + 1;
    
    Serial.println("📍 ORIENTATION " + String(orientation + 1) + "/" + String(ORIENTATIONS_PER_FINGER));
    Serial.println("🎯 Sensor Slot: " + String(sensorId));
    
    switch(orientation) {
      case 0:
        Serial.println("👆 Place finger NORMALLY (center position)");
        break;
      case 1:
        Serial.println("↗️  Place finger at SLIGHT ANGLE (rotate 15-20°)");
        break;
      case 2:
        Serial.println("👈 Place finger SLIGHTLY LEFT of center");
        break;
      case 3:
        Serial.println("👉 Place finger SLIGHTLY RIGHT of center");
        break;
    }
    
    if (!enrollSingleOrientation(sensorId)) {
      Serial.println("❌ Failed to enroll orientation " + String(orientation + 1));
      return false;
    }
    
    Serial.println("✅ Orientation " + String(orientation + 1) + " enrolled successfully!");
    
    if(orientation < ORIENTATIONS_PER_FINGER - 1) {
      Serial.println("⏳ Get ready for next orientation...");
      delay(2000);
    }
  }
  
  return true;
}

bool enrollSingleOrientation(uint8_t sensorId) {
  int p = -1;
  
  // Step 1: Get first image
  Serial.println("👆 Place finger on sensor...");
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    switch (p) {
      case FINGERPRINT_OK:
        Serial.println("📸 First image captured");
        break;
      case FINGERPRINT_NOFINGER:
        Serial.print(".");
        break;
      case FINGERPRINT_PACKETRECIEVEERR:
        Serial.println("❌ Communication error");
        break;
      case FINGERPRINT_IMAGEFAIL:
        Serial.println("❌ Imaging error - try repositioning finger");
        break;
      default:
        Serial.println("❌ Unknown error: " + String(p));
        break;
    }
    delay(50);
  }

  // Convert first image
  p = finger.image2Tz(1);
  if (p != FINGERPRINT_OK) {
    handleConversionError(p, "first");
    return false;
  }
  
  Serial.println("✅ First image processed");
  Serial.println("✋ Remove finger completely...");
  delay(2000);
  
  // Wait for finger removal
  p = 0;
  while (p != FINGERPRINT_NOFINGER) {
    p = finger.getImage();
    delay(50);
  }

  // Step 2: Get second image (same orientation)
  Serial.println("👆 Place SAME finger again (same position/angle)...");
  p = -1;
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    switch (p) {
      case FINGERPRINT_OK:
        Serial.println("📸 Second image captured");
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
        Serial.println("❌ Unknown error: " + String(p));
        break;
    }
    delay(50);
  }

  // Convert second image
  p = finger.image2Tz(2);
  if (p != FINGERPRINT_OK) {
    handleConversionError(p, "second");
    return false;
  }
  
  Serial.println("✅ Second image processed");

  // Create model from both images
  Serial.println("🔄 Creating fingerprint model...");
  p = finger.createModel();
  
  if (p == FINGERPRINT_OK) {
    Serial.println("✅ Fingerprint model created successfully!");
  } else if (p == FINGERPRINT_PACKETRECIEVEERR) {
    Serial.println("❌ Communication error during model creation");
    return false;
  } else if (p == FINGERPRINT_ENROLLMISMATCH) {
    Serial.println("❌ Fingerprints didn't match - try again with consistent placement");
    return false;
  } else {
    Serial.println("❌ Unknown error during model creation: " + String(p));
    return false;
  }

  // Store the model
  Serial.println("💾 Storing fingerprint model...");
  p = finger.storeModel(sensorId);
  
  if (p == FINGERPRINT_OK) {
    Serial.println("✅ Fingerprint stored in slot " + String(sensorId));
    return true;
  } else if (p == FINGERPRINT_PACKETRECIEVEERR) {
    Serial.println("❌ Communication error during storage");
    return false;
  } else if (p == FINGERPRINT_BADLOCATION) {
    Serial.println("❌ Invalid storage location");
    return false;
  } else if (p == FINGERPRINT_FLASHERR) {
    Serial.println("❌ Flash memory error");
    return false;
  } else {
    Serial.println("❌ Unknown storage error: " + String(p));
    return false;
  }
}

void handleConversionError(int error, String imageType) {
  switch (error) {
    case FINGERPRINT_IMAGEMESS:
      Serial.println("❌ " + imageType + " image too messy - clean finger and try again");
      break;
    case FINGERPRINT_PACKETRECIEVEERR:
      Serial.println("❌ Communication error during " + imageType + " image conversion");
      break;
    case FINGERPRINT_FEATUREFAIL:
      Serial.println("❌ Could not extract features from " + imageType + " image");
      break;
    case FINGERPRINT_INVALIDIMAGE:
      Serial.println("❌ " + imageType + " image invalid");
      break;
    default:
      Serial.println("❌ Unknown error during " + imageType + " image conversion: " + String(error));
      break;
  }
}
