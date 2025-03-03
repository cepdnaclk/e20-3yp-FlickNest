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

// Define GPIO for Bulb
#define BULB_PIN D5

void setup() {
  Serial.begin(115200);
  pinMode(BULB_PIN, OUTPUT);
  digitalWrite(BULB_PIN, LOW);  // Default OFF

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
}

void loop() {
  Serial.println("\nChecking Firebase for updates...");

  // Fetch bulb status from Firebase
  if (Firebase.get(firebaseData, "/symbols/sym_002/state")) {
    Serial.print("Firebase Data Type: ");
    Serial.println(firebaseData.dataType());

    // Verify if data type is boolean
    if (firebaseData.dataType() == "boolean") {
      bool bulbState = firebaseData.boolData();
      digitalWrite(BULB_PIN, bulbState ? HIGH : LOW);
      Serial.print("Bulb Status Updated: ");
      Serial.println(bulbState ? "ON" : "OFF");
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
}
