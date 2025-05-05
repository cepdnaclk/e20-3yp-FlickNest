#include <Adafruit_Sensor.h>
#include <Adafruit_MPU6050.h>
#include <ArduinoJson.h>
#include <Arduino_BuiltIn.h>
#include "secrets.h"
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <WiFi.h>

#define AWS_PUB "esp32/pub"
#define AWS_SUB "esp32/sub"

unsigned long last_interval_ms =0;
String lastDev1State ="", lastDev2State ="";
Adafruit_MPU6050 mpu;


WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);
unsigned long lastWiFiAttempt = 0;
const unsigned long wifiRetryInterval = 500; 
void connectAWS(){
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("Connecting to wifi");
  while(WiFi.status() != WL_CONNECTED){
    if(millis() - lastWiFiAttempt > wifiRetryInterval){
      lastWiFiAttempt = millis();
      Serial.print(".");
    }
    
  }

  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  //connect to mqtt broker on the aws endpoint
  client.setServer(AWS_IOT_ENDPOINT,8883);
  Serial.println("Connecting to AWS");
  while(!client.connect(THINGNAME)){
    Serial.print(".");
    delay(100);
  }
  if(!client.connected()){
    Serial.println("AWS IOT Timeout");
    return;
  }
  client.subscribe(AWS_SUB);
  Serial.println("Aws connected");
}
void publishMessage(JsonDocument &doc){
  Serial.print("publish message:");
  char jsonBuffer[512]; 
  serializeJson(doc , jsonBuffer); 
  Serial.println(jsonBuffer);
  // client.publish(AWS_SUB,jsonBuffer);
  client.publish(AWS_PUB,jsonBuffer);
}

void getAccelData(){
  sensors_event_t a,g, temp;
  if(millis()> last_interval_ms + (1000/60)){ //60hz
    last_interval_ms = millis(); //update time 
    mpu.getEvent(&a, &g,&temp);
    StaticJsonDocument<256> doc; 
    doc["Accel_X:"]  = a.acceleration.x;
    doc["Accel_Y:"]  = a.acceleration.y;
    doc["Accel_Z:"]  = a.acceleration.z;
    doc["timestamp"] =millis();

    publishMessage(doc);
  }


}
void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  connectAWS();
  if(!mpu.begin()){
    Serial.println("Failed to connect to mpu");
    while(1) delay(20);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
}

void loop() {
  client.loop();
  getAccelData();
}
