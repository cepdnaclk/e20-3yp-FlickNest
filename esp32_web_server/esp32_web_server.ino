#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <MPU9250_asukiaaa.h>
#include <Adafruit_BMP280.h>

#ifdef _ESP32_HAL_I2C_H_
#define SDA_PIN 21
#define SCL_PIN 22
#endif

const char *ssid = "Huawei Nova 9";
const char *password = "01711559";
WebServer server(80);
Adafruit_BMP280 bme;
MPU9250_asukiaaa mySensor;
float aX, aY, aZ, gX, gY, gZ, mX, mY, mZ, mDirection;

void handleRoot() {
  String html = "<html><head><meta http-equiv='refresh' content='0.5'/><title>ESP32 Sensor Data</title></head><body>";
  html += "<h1>ESP32 Sensor Data</h1>";
  html += "<p>Temperature: " + String(bme.readTemperature()) + " °C</p>";
  html += "<p>Pressure: " + String(bme.readPressure() / 3377) + " inHg</p>";
  html += "<p>Altitude: " + String(bme.readAltitude(1013.25)) + " m</p>";
  html += "<p>Accel (X,Y,Z): " + String(aX) + ", " + String(aY) + ", " + String(aZ) + "</p>";
  html += "<p>Gyro (X,Y,Z): " + String(gX) + ", " + String(gY) + ", " + String(gZ) + "</p>";
  html += "<p>Mag (X,Y,Z): " + String(mX) + ", " + String(mY) + ", " + String(mZ) + "</p>";
  html += "<p>Direction: " + String(mDirection) + " °</p></body></html>";
  server.send(200, "text/html", html);
}

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  mySensor.setWire(&Wire);
  bme.begin();
  mySensor.beginAccel();
  mySensor.beginGyro();
  mySensor.beginMag();

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(200);
    Serial.print(".");
  }
  Serial.print("Connected. IP: ");
  Serial.println(WiFi.localIP());
  if (MDNS.begin("esp32")) {
    Serial.println("MDNS responder started");
  }
  server.on("/", handleRoot);
  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  if (mySensor.accelUpdate() == 0) {
    aX = mySensor.accelX(); aY = mySensor.accelY(); aZ = mySensor.accelZ();
  }
  if (mySensor.gyroUpdate() == 0) {
    gX = mySensor.gyroX(); gY = mySensor.gyroY(); gZ = mySensor.gyroZ();
  }
  if (mySensor.magUpdate() == 0) {
    mX = mySensor.magX(); mY = mySensor.magY(); mZ = mySensor.magZ();
    mDirection = mySensor.magHorizDirection();
  }
  server.handleClient();
  delay(1); // Higher update frequency
}
