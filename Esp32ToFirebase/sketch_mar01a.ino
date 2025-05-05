#include <symbol_mapper_inferencing.h>
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

//variables for gesture recognition
float features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
size_t feature_ix = 0;
unsigned long last_interval_ms =0;
String lastDev1State ="", lastDev2State ="";
Adafruit_MPU6050 mpu;


WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);

void messageHandler(char* topic , byte* payload,unsigned int length){
  Serial.print("Publishing Message to Topic [");
  Serial.print(topic);
  Serial.println("]");

  //create json doc
  JsonDocument doc;
  deserializeJson(doc, payload);
  const char* device = doc["device"];
  const char* state = doc["state"];
  Serial.print("Device: ");
  Serial.print(device);
  Serial.print(" - State: ");
  Serial.println(state);
}

void connectAWS(){
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("Connecting to wifi");
  while(WiFi.status() != WL_CONNECTED){
    delay(500);
    Serial.print("..");
    
  }

  //configuring wificlientsecure to use aws iot dev credentials
  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  //connect to mqtt broker on the aws endpoint
  client.setServer(AWS_IOT_ENDPOINT,8883);

  //create message handler
  client.setCallback(messageHandler);

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
void publishMessage(const char* device , const char* state){
  Serial.print("publish message");
  Serial.print(device);
  Serial.print("--->");
  Serial.print(state);
  JsonDocument doc; 
  doc["device"] = device;
  doc["state"] = state;
  char jsonBuffer[512];
  serializeJson(doc , jsonBuffer);
  Serial.println(jsonBuffer);
  client.publish(AWS_PUB,jsonBuffer);
}

void detectGesture(){
  sensors_event_t  a , g , temp; //accel, gyro, temperature readings
  if(millis() > last_interval_ms +(1000/60)){
    last_interval_ms = millis();
    mpu.getEvent(&a , &g , &temp);
    features[feature_ix++] = a.acceleration.x; //save all the acceleration data in one array
    features[feature_ix++] = a.acceleration.y;
    features[feature_ix++] = a.acceleration.z;

    if (feature_ix == EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE){ //if enough data is capured
      signal_t signal ; //convert motion into a signal
      ei_impulse_result_t  result;
      if(numpy::signal_from_buffer(features, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE , &signal)==0){// transform raw motion data into format the model can understand
        if(run_classifier(&signal, &result , false)==0){ //feed the motion data(accel) to the model and get prediction about the gesture
          
          for(size_t i =0; i< EI_CLASSIFIER_LABEL_COUNT ; i++){ // loop for all the labels size
            
            if(result.classification[i].value > 0.75){ // if the prediction is higher than 0.75 then take it as a valid gesture
              String label = result.classification[i].label; //take the label of the valid gesture
              if(label == "circle") updateLightstate();// if the gesture is a circle then change light state 
              else if (label =="shake") updateDoorState(); //if the gesture is a shake then change doo state 
            }
            
          }
        }
      }
      feature_ix =0;
    }
  }
}
void updateLightstate(){
  lastDev1State = (lastDev1State == "OFF") ? "ON" :"OFF";
  Serial.print("Light State chnaged");
  Serial.println(lastDev1State);
//  client.publish(AWS_PUB , lastDev1State == "ON" ?  "device1_ON" : "device1_OFF");
  JsonDocument doc;
  doc["device"] = "Light";
  doc["state"] = lastDev1State;
  publishMessage("Light" , lastDev1State.c_str());
  
}
void updateDoorState(){
  lastDev2State = (lastDev2State == "OFF") ? "ON" :"OFF";
  Serial.print("Light State chnaged");
  Serial.println(lastDev2State);
//  client.publish(AWS_PUB , lastDev2State == "ON" ?  "device1_ON" : "device1_OFF");
  JsonDocument doc;
  doc["device"] = "Door";
  doc["state"] = lastDev2State;
  publishMessage("Door" , lastDev2State.c_str());
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
  int metricVal = random(1, 101);
//  Serial.print(F("metrics "));
//  Serial.print(metricVal);
//  publishMessage(metricVal);
  client.loop();
  delay(1000);
  detectGesture();
}
