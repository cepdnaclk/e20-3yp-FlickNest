#include <Adafruit_Sensor.h>
#include <Adafruit_MPU6050.h>
#include <ArduinoJson.h>
#include "secrets.h"
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <WiFiProv.h>
#include <WiFi.h>
#include <wristband2_inferencing.h>
#include <nvs_flash.h>
#include <Preferences.h>

// ====== CONTROL SYSTEMS OPTIMIZED PARAMETERS ======
#define FREQUENCY_HZ 100
#define INTERVAL_MS (1000 / FREQUENCY_HZ)
#define AWS_PUB "esp32/pub"
#define AWS_SUB "esp32/sub"

// ADAPTIVE THRESHOLDING PARAMETERS
#define BASE_CONFIDENCE_THRESHOLD 0.45
#define SYMBOL_CONFIDENCE_THRESHOLD 0.40  // Lower for symbols
#define DYNAMIC_THRESHOLD_FACTOR 0.1
#define MAX_CONFIDENCE_THRESHOLD 0.85
#define MIN_CONFIDENCE_THRESHOLD 0.25

// CONTROL SYSTEM PARAMETERS
#define FILTER_ALPHA 0.3              // Low-pass filter coefficient
#define DERIVATIVE_FILTER_ALPHA 0.5   // Derivative filter
#define GESTURE_STATE_TIMEOUT 2000    // State machine timeout
#define CONFIDENCE_SMOOTHING_FACTOR 0.7
#define PREDICTION_BUFFER_SIZE 10

// ANOMALY DETECTION PARAMETERS
#define ADAPTIVE_ANOMALY_THRESHOLD 0.5
#define ANOMALY_ADAPTATION_RATE 0.0
#define SIGNAL_NOISE_THRESHOLD 0.1

// WiFi and provisioning
const char *pop = "abcd1234";
const char *service_name = "PROV_FLICKNEST_BAND";
bool reset_provisioned = false;
bool wifi_connected = false;
bool provisioning_complete = false;
bool force_provisioning = false;

// ====== CONTROL SYSTEMS COMPONENTS ======

// Digital Filter Structure
struct DigitalFilter {
  float prev_input;
  float prev_output;
  float alpha;
};

// PID-like Controller for Confidence
struct ConfidenceController {
  float proportional_gain;
  float integral_gain;
  float derivative_gain;
  float integral_sum;
  float prev_error;
  float prev_confidence;
};

// State Machine for Gesture Recognition
enum GestureState {
  IDLE,
  DETECTING,
  CONFIRMED,
  COOLDOWN
};

// Enhanced Prediction Structure
struct EnhancedPrediction {
  String label;
  float raw_confidence;
  float filtered_confidence;
  float stability_score;
  unsigned long timestamp;
  bool is_symbol;
  float signal_quality;
};

// Adaptive System Parameters
struct AdaptiveParams {
  float current_anomaly_threshold;
  float noise_level;
  float signal_strength;
  float adaptation_rate;
  unsigned long last_update;
};

// ====== GLOBAL VARIABLES ======
float features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
size_t feature_ix = 0;
static unsigned long last_interval_ms = 0;

// Sensor calibration
float accel_offset_x = 0, accel_offset_y = 0, accel_offset_z = 0;
bool sensor_calibrated = false;

// Digital filters for each axis
DigitalFilter accel_filter_x = {0, 0, FILTER_ALPHA};
DigitalFilter accel_filter_y = {0, 0, FILTER_ALPHA};
DigitalFilter accel_filter_z = {0, 0, FILTER_ALPHA};

// Confidence controller
ConfidenceController conf_controller = {1.0, 0.1, 0.2, 0, 0, 0};

// Gesture state machine
GestureState current_gesture_state = IDLE;
unsigned long state_entry_time = 0;

// Enhanced prediction buffer
EnhancedPrediction prediction_buffer[PREDICTION_BUFFER_SIZE];
int buffer_index = 0;

// Adaptive parameters
AdaptiveParams adaptive_params = {ADAPTIVE_ANOMALY_THRESHOLD, 0.1, 1.0, ANOMALY_ADAPTATION_RATE, 0};

// Symbol gestures list
String symbol_gestures[] = {"peace", "ok", "thumbs_up", "thumbs_down", "fist", "open_hand"};
int num_symbol_gestures = 6;

// Current state tracking
String current_gesture = "";
String last_published_gesture = "";
float current_confidence = 0.0;
unsigned long last_gesture_time = 0;

Adafruit_MPU6050 mpu;
Preferences preferences;
WiFiClientSecure net;
PubSubClient client(net);

void ei_printf(const char *format, ...) {
  static char print_buf[1024] = { 0 };
  va_list args;
  va_start(args, format);
  int r = vsnprintf(print_buf, sizeof(print_buf), format, args);
  va_end(args);
  if (r > 0) Serial.write(print_buf);
}

// ====== DIGITAL FILTERING FUNCTIONS ======

float applyLowPassFilter(DigitalFilter* filter, float input) {
  filter->prev_output = filter->alpha * input + (1.0 - filter->alpha) * filter->prev_output;
  return filter->prev_output;
}

float calculateDerivative(DigitalFilter* filter, float input) {
  float derivative = (input - filter->prev_input) * FREQUENCY_HZ;
  filter->prev_input = input;
  return applyLowPassFilter(filter, derivative);
}

float calculateSignalQuality(float x, float y, float z) {
  // Calculate signal magnitude and stability
  float magnitude = sqrt(x*x + y*y + z*z);
  float normalized_magnitude = magnitude / 9.81; // Normalize by gravity
  
  // Quality based on signal strength and stability
  float quality = min(1.0f, normalized_magnitude);
  return max(0.1f, quality);
}

// ====== ADAPTIVE ANOMALY DETECTION ======

void updateAdaptiveParams(float current_anomaly, float signal_quality) {
  unsigned long current_time = millis();
  
  if (current_time - adaptive_params.last_update > 100) { // Update every 100ms
    // Adapt anomaly threshold based on signal quality
    float target_threshold = ADAPTIVE_ANOMALY_THRESHOLD * (2.0 - signal_quality);
    
    adaptive_params.current_anomaly_threshold += 
      adaptive_params.adaptation_rate * (target_threshold - adaptive_params.current_anomaly_threshold);
    
    // Constrain threshold
    adaptive_params.current_anomaly_threshold = 
      constrain(adaptive_params.current_anomaly_threshold, 0.1, 1.0);
    
    // Update noise level estimation
    adaptive_params.noise_level = 0.9 * adaptive_params.noise_level + 0.1 * current_anomaly;
    adaptive_params.signal_strength = signal_quality;
    adaptive_params.last_update = current_time;
  }
}

// ====== CONFIDENCE CONTROL SYSTEM ======

float applyConfidenceControl(float raw_confidence, float signal_quality) {
  // PID-like control for confidence enhancement
  float target_confidence = raw_confidence * signal_quality;
  float error = target_confidence - conf_controller.prev_confidence;
  
  // Proportional term
  float proportional = conf_controller.proportional_gain * error;
  
  // Integral term (with windup protection)
  conf_controller.integral_sum += error;
  conf_controller.integral_sum = constrain(conf_controller.integral_sum, -10.0, 10.0);
  float integral = conf_controller.integral_gain * conf_controller.integral_sum;
  
  // Derivative term
  float derivative = conf_controller.derivative_gain * (error - conf_controller.prev_error);
  
  // Combined output
  float controlled_confidence = raw_confidence + 0.1 * (proportional + integral + derivative);
  controlled_confidence = constrain(controlled_confidence, 0.0, 1.0);
  
  // Update controller state
  conf_controller.prev_error = error;
  conf_controller.prev_confidence = controlled_confidence;
  
  return controlled_confidence;
}

// ====== ENHANCED GESTURE STATE MACHINE ======

bool isSymbolGesture(String gesture) {
  for (int i = 0; i < num_symbol_gestures; i++) {
    if (gesture.equalsIgnoreCase(symbol_gestures[i])) {
      return true;
    }
  }
  return false;
}

float calculateStabilityScore(String gesture_label) {
  float stability = 0.0;
  int count = 0;
  unsigned long current_time = millis();
  
  // Check recent predictions in buffer
  for (int i = 0; i < PREDICTION_BUFFER_SIZE; i++) {
    if (prediction_buffer[i].label == gesture_label && 
        (current_time - prediction_buffer[i].timestamp) < 500) {
      stability += prediction_buffer[i].filtered_confidence;
      count++;
    }
  }
  
  return count > 0 ? stability / count : 0.0;
}

String processGestureStateMachine(String predicted_gesture, float confidence, float signal_quality) {
  unsigned long current_time = millis();
  String result = "";
  
  // Determine appropriate threshold
  bool is_symbol = isSymbolGesture(predicted_gesture);
  float threshold = is_symbol ? SYMBOL_CONFIDENCE_THRESHOLD : BASE_CONFIDENCE_THRESHOLD;
  
  // Adjust threshold based on signal quality
  threshold *= (0.7 + 0.3 * signal_quality);
  
  switch (current_gesture_state) {
    case IDLE:
      if (confidence >= threshold && predicted_gesture != "") {
        current_gesture_state = DETECTING;
        current_gesture = predicted_gesture;
        state_entry_time = current_time;
        Serial.printf("State: IDLE -> DETECTING (%s, conf: %.2f)\n", 
                     predicted_gesture.c_str(), confidence);
      }
      break;
      
    case DETECTING:
      if (predicted_gesture == current_gesture && confidence >= threshold) {
        // Check if we have enough stability
        float stability = calculateStabilityScore(current_gesture);
        int required_detections = is_symbol ? 3 : 5; // Fewer required for symbols
        
        if (stability >= threshold && (current_time - state_entry_time) >= 150) {
          current_gesture_state = CONFIRMED;
          current_confidence = confidence;
          result = current_gesture;
          Serial.printf("State: DETECTING -> CONFIRMED (%s, stability: %.2f)\n", 
                       current_gesture.c_str(), stability);
        }
      } else if (current_time - state_entry_time > 800) {
        // Timeout - return to idle
        current_gesture_state = IDLE;
        current_gesture = "";
        Serial.println("State: DETECTING -> IDLE (timeout)");
      } else if (confidence < threshold * 0.7) {
        // Confidence dropped significantly
        current_gesture_state = IDLE;
        current_gesture = "";
        Serial.println("State: DETECTING -> IDLE (low confidence)");
      }
      break;
      
    case CONFIRMED:
      current_gesture_state = COOLDOWN;
      state_entry_time = current_time;
      Serial.println("State: CONFIRMED -> COOLDOWN");
      break;
      
    case COOLDOWN:
      if (current_time - state_entry_time > (is_symbol ? 300 : 500)) {
        current_gesture_state = IDLE;
        current_gesture = "";
        Serial.println("State: COOLDOWN -> IDLE");
      }
      break;
  }
  
  return result;
}

// ====== SENSOR CALIBRATION ======

void calibrateSensor() {
  Serial.println("Calibrating sensor... Keep device still for 3 seconds");
  delay(1000);
  
  float sum_x = 0, sum_y = 0, sum_z = 0;
  
  for (int i = 0; i < 100; i++) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    sum_x += a.acceleration.x;
    sum_y += a.acceleration.y;
    sum_z += a.acceleration.z - 9.81;
    delay(20);
  }
  
  accel_offset_x = sum_x / 100.0;
  accel_offset_y = sum_y / 100.0;
  accel_offset_z = sum_z / 100.0;
  
  Serial.println("Sensor calibration complete!");
  Serial.printf("Offsets - X: %.2f, Y: %.2f, Z: %.2f\n", 
                accel_offset_x, accel_offset_y, accel_offset_z);
  sensor_calibrated = true;
}

// ====== WiFi CONNECTION FUNCTIONS ======

bool connectToStoredWiFi() {
  Serial.println("Attempting to connect to stored WiFi credentials...");
  WiFi.begin();
  
  unsigned long start_time = millis();
  while (WiFi.status() != WL_CONNECTED && (millis() - start_time) < 20000) {
    delay(500);
    Serial.print(".");
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("Connected to WiFi! IP address: ");
    Serial.println(WiFi.localIP());
    wifi_connected = true;
    return true;
  } else {
    Serial.println();
    Serial.println("Failed to connect to stored WiFi credentials");
    return false;
  }
}

bool hasStoredWiFiCredentials() {
  preferences.begin("wifi_creds", true);
  String ssid = preferences.getString("ssid", "");
  preferences.end();
  return (ssid.length() > 0);
}

// ====== AWS FUNCTIONS ======

void SysProvEvent(arduino_event_t *e) {
  switch (e->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("Connected to WiFi! IP address: ");
      Serial.println(WiFi.localIP());
      wifi_connected = true;
      break;
      
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("WiFi disconnected");
      wifi_connected = false;
      break;
      
    case ARDUINO_EVENT_PROV_START:
      Serial.println("Provisioning started");
      break;
      
    case ARDUINO_EVENT_PROV_CRED_RECV:
      Serial.println("Received WiFi credentials");
      break;
      
    case ARDUINO_EVENT_PROV_CRED_FAIL:
      Serial.println("Provisioning failed!");
      break;
      
    case ARDUINO_EVENT_PROV_CRED_SUCCESS:
      Serial.println("Provisioning successful");
      break;
      
    case ARDUINO_EVENT_PROV_END:
      Serial.println("Provisioning ended");
      provisioning_complete = true;
      break;
  }
}

void connectAWS() {
  if (!wifi_connected) return;
  
  Serial.println("Connecting to AWS IoT...");
  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);
  client.setServer(AWS_IOT_ENDPOINT, 8883);
  
  int attempts = 0;
  while (!client.connect(THINGNAME) && attempts < 5) {
    Serial.printf("AWS connection attempt %d/5\n", attempts + 1);
    delay(2000);
    attempts++;
  }
  
  if (client.connected()) {
    Serial.println("Connected to AWS IoT!");
    client.subscribe(AWS_SUB);
    
    JsonDocument statusDoc;
    statusDoc["connected"] = true;
    statusDoc["system"] = "control_optimized";
    publishMessage(statusDoc);
  }
}

void publishMessage(JsonDocument &doc) {
  if (!client.connected()) return;
  
  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  
  if (client.publish(AWS_PUB, jsonBuffer)) {
    Serial.printf("Published: %s\n", jsonBuffer);
  }
}

// ====== MAIN GESTURE DETECTION WITH CONTROL SYSTEMS ======

void detectGesture() {
  if (millis() <= last_interval_ms + INTERVAL_MS) return;
  
  last_interval_ms = millis();
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);
  
  // Apply calibration and filtering
  float raw_x = a.acceleration.x - accel_offset_x;
  float raw_y = a.acceleration.y - accel_offset_y;
  float raw_z = a.acceleration.z - accel_offset_z;
  
  // Digital filtering for noise reduction
  float filtered_x = applyLowPassFilter(&accel_filter_x, raw_x);
  float filtered_y = applyLowPassFilter(&accel_filter_y, raw_y);
  float filtered_z = applyLowPassFilter(&accel_filter_z, raw_z);
  
  // Calculate signal quality
  float signal_quality = calculateSignalQuality(filtered_x, filtered_y, filtered_z);
  
  // Collect features
  features[feature_ix++] = filtered_x;
  features[feature_ix++] = filtered_y;
  features[feature_ix++] = filtered_z;
  
  if (feature_ix >= EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE) {
    signal_t signal;
    ei_impulse_result_t result;
    
    int err = numpy::signal_from_buffer(features, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal);
    if (err != 0) {
      feature_ix = 0;
      return;
    }
    
    // Run classifier
    EI_IMPULSE_ERROR res = run_classifier(&signal, &result, false);
    if (res != 0) {
      feature_ix = 0;
      return;
    }
    
    // Enhanced anomaly detection
    bool is_valid = true;
    #if EI_CLASSIFIER_HAS_ANOMALY == 1
    updateAdaptiveParams(result.anomaly, signal_quality);
    
    if (result.anomaly > adaptive_params.current_anomaly_threshold) {
      is_valid = false;
      Serial.printf("Anomaly: %.3f > %.3f (adaptive)\n", 
                   result.anomaly, adaptive_params.current_anomaly_threshold);
    }
    #endif
    
    if (is_valid) {
      // Find best prediction
      float max_confidence = 0.0;
      String best_label = "";
      
      for (size_t ix = 0; ix < EI_CLASSIFIER_LABEL_COUNT; ix++) {
        float conf = result.classification[ix].value;
        if (conf > max_confidence) {
          max_confidence = conf;
          best_label = String(result.classification[ix].label);
        }
      }
      
      // Apply confidence control
      float controlled_confidence = applyConfidenceControl(max_confidence, signal_quality);
      
      // Update prediction buffer
      prediction_buffer[buffer_index] = {
        best_label,
        max_confidence,
        controlled_confidence,
        0.0, // Will be calculated in state machine
        millis(),
        isSymbolGesture(best_label),
        signal_quality
      };
      buffer_index = (buffer_index + 1) % PREDICTION_BUFFER_SIZE;
      
      // Process through state machine
      String confirmed_gesture = processGestureStateMachine(
        best_label, controlled_confidence, signal_quality);
      
      // Publish if confirmed and different from last
      if (confirmed_gesture != "" && confirmed_gesture != last_published_gesture) {
        Serial.printf("CONFIRMED GESTURE: %s (conf: %.2f, quality: %.2f)\n",
                     confirmed_gesture.c_str(), current_confidence, signal_quality);
        
        JsonDocument doc;
        doc[confirmed_gesture] = true;
        doc["confidence"] = current_confidence;
        doc["signal_quality"] = signal_quality;
        doc["is_symbol"] = isSymbolGesture(confirmed_gesture);
        doc["anomaly_threshold"] = adaptive_params.current_anomaly_threshold;
        publishMessage(doc);
        
        last_published_gesture = confirmed_gesture;
        last_gesture_time = millis();
      }
      
      // Debug output (reduced frequency)
      static unsigned long last_debug = 0;
      if (millis() - last_debug > 500) {
        Serial.printf("Top: %s(%.2f->%.2f) Quality:%.2f State:%d\n",
                     best_label.c_str(), max_confidence, controlled_confidence, 
                     signal_quality, current_gesture_state);
        last_debug = millis();
      }
    }
    
    feature_ix = 0;
  }
}

void handleWiFiReconnection() {
  static unsigned long last_wifi_check = 0;
  
  if (millis() - last_wifi_check > 10000) { // Check every 10 seconds
    if (!wifi_connected && WiFi.status() != WL_CONNECTED) {
      Serial.println("WiFi disconnected, attempting to reconnect...");
      connectToStoredWiFi();
    }
    last_wifi_check = millis();
  }
}

// ====== SETUP ======

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("Starting Control Systems Optimized Gesture Recognition...");
  
  // Initialize prediction buffer
  for (int i = 0; i < PREDICTION_BUFFER_SIZE; i++) {
    prediction_buffer[i] = {"", 0.0, 0.0, 0.0, 0, false, 0.0};
  }
  
  // Initialize I2C
  Wire.begin(D6, D7);
  
  // WiFi setup
  if (reset_provisioned) {
    nvs_flash_erase();
    nvs_flash_init();
    force_provisioning = true;
  } else {
    nvs_flash_init();
  }
  
  WiFi.onEvent(SysProvEvent);
  
  // Connect to WiFi
  bool connected = false;
  if (!force_provisioning && hasStoredWiFiCredentials()) {
    connected = connectToStoredWiFi();
  }
  
  if (!connected) {
    Serial.println("Starting BLE provisioning...");
    uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 
                        0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02};
    
    WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, 
                            NETWORK_PROV_SCHEME_HANDLER_FREE_BLE,
                            NETWORK_PROV_SECURITY_1, 
                            pop, service_name, NULL, uuid, reset_provisioned);
    
    while (!wifi_connected) {
      delay(1000);
      Serial.print(".");
    }
  }
  
  // Initialize MPU6050
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) delay(10);
  }
  
  Serial.println("MPU6050 Found!");
  mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
  mpu.setGyroRange(MPU6050_RANGE_250_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ); // Lower bandwidth for stability
  
  calibrateSensor();
  
  Serial.printf("Features: %d, Labels: %d\n", 
                EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, EI_CLASSIFIER_LABEL_COUNT);
  
  connectAWS();
  
  Serial.println("Control Systems Gesture Recognition Ready!");
  Serial.printf("Base thresholds - Normal: %.2f, Symbol: %.2f\n",
                BASE_CONFIDENCE_THRESHOLD, SYMBOL_CONFIDENCE_THRESHOLD);
}

// ====== MAIN LOOP ======

void loop() {
  handleWiFiReconnection();
  
  // AWS connection check (non-blocking)
  static unsigned long last_aws_check = 0;
  if (millis() - last_aws_check > 15000) {
    if (wifi_connected && !client.connected()) {
      connectAWS();
    }
    last_aws_check = millis();
  }
  
  if (client.connected()) {
    client.loop();
  }
  
  // Main gesture detection
  detectGesture();
  
  yield(); // Prevent watchdog timeout
}