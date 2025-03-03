#include <Adafruit_Fingerprint.h>
#include <SoftwareSerial.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7735.h>
#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>

// WiFi credentials
#define WIFI_SSID "HUWAI Y5"
#define WIFI_PASSWORD "12345678"

// Firebase credentials
#define FIREBASE_HOST "flicknestfirebase-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "V9RtIPyVlbMyLzWzVgDowuBP1Hb2wixZGTWr2Coz"

// Firebase and WiFi objects
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// TFT Display pins for ESP8266
#define TFT_CS   15  // GPIO15 (D8)
#define TFT_DC   2   // GPIO2  (D4)
#define TFT_RST  0   // GPIO0  (D3)  - or you can tie this to 3.3V if not used

// Initialize TFT Display object (hardware SPI used by ESP8266)
Adafruit_ST7735 tft = Adafruit_ST7735(TFT_CS, TFT_DC, TFT_RST);

// Fingerprint Sensor setup using SoftwareSerial
// Connect sensor TX to ESP8266 RX (GPIO4) and sensor RX to ESP8266 TX (GPIO5)
// IMPORTANT: If sensor operates at 5V, use a voltage divider on the sensor TX line.
SoftwareSerial fingerSerial(4, 5); // (RX, TX)
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerSerial);

// Relay pin controlling the magnetic door lock
#define RELAY_PIN D0  // GPIO12 (D6)

void setup() {
  // Initialize Serial monitor for debugging
  Serial.begin(9600);
  delay(1000);
  
  // Initialize SoftwareSerial for fingerprint sensor
  fingerSerial.begin(57600);
  finger.begin(57600);

    // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }
  Serial.println("\nConnected to WiFi!");

  // Print Wi-Fi signal strength
  Serial.print("WiFi Signal Strength: ");
  Serial.println(WiFi.RSSI());

  // Configure Firebase
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Setup relay pin
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);  // Start with door locked
  
  // Initialize TFT Display
  tft.initR(INITR_144GREENTAB);  // Try INITR_144GREENTAB; if colors are off, try INITR_BLACKTAB or INITR_GREENTAB
  tft.fillScreen(ST7735_BLACK);
  tft.setTextColor(ST7735_WHITE);
  tft.setTextSize(2);
  
  // Check for fingerprint sensor connection
  if (finger.verifyPassword()) {
    Serial.println("Fingerprint sensor found!");
    tft.setCursor(10, 30);
    tft.print("Ready...");
  } else {
    Serial.println("Fingerprint sensor not found!");
    tft.setCursor(10, 30);
    tft.print("Sensor Error");
    while (1);  // Stop further execution
  }
}

void loop() {
    Serial.println("\nChecking Firebase for updates...");

  // Fetch bulb status from Firebase
  if (Firebase.get(firebaseData, "/symbols/sym_001/state")) {
    Serial.print("Firebase Data Type: ");
    Serial.println(firebaseData.dataType());

    // Verify if data type is boolean
    if (firebaseData.dataType() == "boolean") {
      bool bulbState = firebaseData.boolData();
      digitalWrite(RELAY_PIN, bulbState ? HIGH : LOW);
      Serial.print("Bulb Status Updated: ");
      Serial.println(bulbState ? "ON" : "OFF");

        if (bulbState == HIGH) {
    tft.fillScreen(ST7735_GREEN);
    tft.setCursor(10, 30);
    tft.print("Access OK via Band");}
    } 
    // If it's not boolean, print the value received
    else {
      Serial.print("Unexpected data type! Received: ");
      Serial.println(firebaseData.stringData());  // Print as string for debugging
    }
  } 
  // If Firebase read fails, print error
  else {
    Serial.println("Failed to get data from Firebase!");
    Serial.print("Error: ");
    Serial.println(firebaseData.errorReason());
  }

  delay(500); // Check for updates every 2 seconds
  
  // Clear display and prompt for a fingerprint
  tft.fillScreen(ST7735_BLACK);
  tft.setCursor(10, 30);
  tft.print("Place Finger");
  Serial.println("Waiting for fingerprint...");
  
  int fingerprintID = getFingerprintID();
  if (fingerprintID > 0) {
    // Valid fingerprint recognized
    Serial.println("Access Granted!");
    tft.fillScreen(ST7735_GREEN);
    tft.setCursor(10, 30);
    tft.print("Access OK");
    
    // Activate relay to unlock the door (adjust HIGH/LOW if your relay is active LOW)
    digitalWrite(RELAY_PIN, HIGH);
    delay(5000);  // Keep the door unlocked for 5 seconds
    digitalWrite(RELAY_PIN, LOW);
  } else {
    // Fingerprint not recognized
    Serial.println("Access Denied!");
    tft.fillScreen(ST7735_RED);
    tft.setCursor(10, 30);
    tft.print("Denied");
    delay(2000);
  }
}

// Function to capture and search for a fingerprint
int getFingerprintID() {
  // Wait for a finger to be placed on the sensor
  if (finger.getImage() != FINGERPRINT_OK) return -1;
  if (finger.image2Tz() != FINGERPRINT_OK) return -1;
  if (finger.fingerFastSearch() != FINGERPRINT_OK) return -1;
  
  // Return the found fingerprint ID
  return finger.fingerID;
}
