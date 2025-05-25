#include <Adafruit_Sensor.h>
#include <Adafruit_MPU6050.h>
#include <ArduinoJson.h>
#include "secrets.h"
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <WiFiProv.h>
#include <WiFi.h>
#include <wristband_inferencing.h>
#include <nvs_flash.h>
#include <Preferences.h>

#define FREQUENCY_HZ 60  // Increased frequency for real-time
#define INTERVAL_MS (1000 / (FREQUENCY_HZ + 1))

#define AWS_PUB "esp32/pub"
#define AWS_SUB "esp32/sub"

// WiFi connection timeout and retry settings
#define WIFI_CONNECT_TIMEOUT 10000  // 10 seconds timeout
#define WIFI_RETRY_DELAY 5000       // 5 seconds between retries
#define MAX_WIFI_RETRIES 3          // Maximum retry attempts

// Enhanced fuzzy logic parameters with circle-specific tuning
#define MIN_CONFIDENCE_THRESHOLD 0.45          // Lowered for circle detection
#define HIGH_CONFIDENCE_THRESHOLD 0.70         
#define VERY_HIGH_CONFIDENCE_THRESHOLD 0.85    
#define SYMBOL_CONFIDENCE_THRESHOLD 0.40       // Lower for symbols including circle
#define CIRCLE_CONFIDENCE_THRESHOLD 0.35       // Special low threshold for circle
#define STABILITY_WINDOW 7                     // Increased for better circle stability
#define MIN_GESTURE_DURATION 80                // Reduced for faster circle response
#define ANOMALY_THRESHOLD 0.0                
#define CONSISTENCY_THRESHOLD 0.5              // Lowered for circle detection
#define CIRCLE_CONSISTENCY_THRESHOLD 0.4       // Special threshold for circle
#define SYMBOL_BOOST_FACTOR 1.20               
#define CIRCLE_BOOST_FACTOR 1.35               // Special boost for circle

// Enhanced circle detection parameters
#define CIRCLE_PATTERN_WINDOW 10               // Window for circular motion analysis
#define CIRCLE_MOTION_THRESHOLD 0.3            // Threshold for detecting circular motion
#define CIRCLE_STABILITY_BONUS 1.25            // Bonus multiplier for stable circular motion

String current_state = "";
String last_published_state = "";

const char *pop = "abcd1234";
const char *service_name = "PROV_FLICKNEST_BAND";

bool reset_provisioned = false;
bool wifi_connected = false;
bool provisioning_complete = false;
bool wifi_provisioned = false;

Preferences preferences;

// Enhanced prediction variables
float features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
size_t feature_ix = 0;
static unsigned long last_interval_ms = 0;
Adafruit_MPU6050 mpu;

// Enhanced fuzzy logic for gesture stability with special circle handling
struct GestureCandidate {
  String label;
  float confidence;
  unsigned long timestamp;
  int count;
  bool is_symbol;
  bool is_circle;
  float raw_confidence;
  float motion_pattern_score;
};

// Circular motion detection structure
struct MotionData {
  float ax, ay, az;
  unsigned long timestamp;
};

GestureCandidate gesture_history[STABILITY_WINDOW];
MotionData motion_history[CIRCLE_PATTERN_WINDOW];
int history_index = 0;
int motion_index = 0;
unsigned long last_gesture_time = 0;
String stable_gesture = "";
float stable_confidence = 0.0;

// Enhanced gesture classification
bool isSymbolGesture(String gesture) {
  return (gesture.indexOf("symbol") >= 0 || 
          gesture.indexOf("sign") >= 0 || 
          gesture.indexOf("letter") >= 0 ||
          gesture.indexOf("number") >= 0 ||
          gesture.indexOf("character") >= 0 ||
          gesture.indexOf("circle") >= 0);
}

bool isCircleGesture(String gesture) {
  return (gesture.indexOf("circle") >= 0 || 
          gesture.indexOf("Circle") >= 0 ||
          gesture.indexOf("CIRCLE") >= 0 ||
          gesture.indexOf("round") >= 0 ||
          gesture.indexOf("circular") >= 0);
}

// Calculate circular motion score from accelerometer data
float calculateCircularMotionScore() {
  if (motion_index < 6) return 0.0; // Need minimum data points
  
  float score = 0.0;
  int valid_points = 0;
  
  // Analyze motion patterns for circular characteristics
  for (int i = 1; i < min(motion_index, CIRCLE_PATTERN_WINDOW - 1); i++) {
    int prev_idx = (i - 1) % CIRCLE_PATTERN_WINDOW;
    int curr_idx = i % CIRCLE_PATTERN_WINDOW;
    
    // Calculate acceleration magnitude changes (circular motion has smoother transitions)
    float prev_mag = sqrt(pow(motion_history[prev_idx].ax, 2) + 
                         pow(motion_history[prev_idx].ay, 2) + 
                         pow(motion_history[prev_idx].az, 2));
    float curr_mag = sqrt(pow(motion_history[curr_idx].ax, 2) + 
                         pow(motion_history[curr_idx].ay, 2) + 
                         pow(motion_history[curr_idx].az, 2));
    
    // Circular motion tends to have consistent magnitude with directional changes
    float mag_consistency = 1.0 - abs(prev_mag - curr_mag) / max(prev_mag, curr_mag);
    
    // Calculate directional change (circles have continuous direction changes)
    float dot_product = (motion_history[prev_idx].ax * motion_history[curr_idx].ax +
                        motion_history[prev_idx].ay * motion_history[curr_idx].ay +
                        motion_history[prev_idx].az * motion_history[curr_idx].az);
    float directional_change = 1.0 - (dot_product / (prev_mag * curr_mag));
    
    // Circular motion score combines magnitude consistency with directional change
    score += (mag_consistency * 0.4 + directional_change * 0.6);
    valid_points++;
  }
  
  return valid_points > 0 ? (score / valid_points) : 0.0;
}

// Enhanced confidence calculation with circle-specific handling
float calculateEnhancedConfidence(String label, float raw_confidence, float motion_score = 0.0) {
  if (isCircleGesture(label)) {
    // Special handling for circles
    float enhanced = raw_confidence * CIRCLE_BOOST_FACTOR;
    
    // Apply motion pattern bonus for circles
    if (motion_score > CIRCLE_MOTION_THRESHOLD) {
      enhanced *= CIRCLE_STABILITY_BONUS;
    }
    
    return enhanced;
  } else if (isSymbolGesture(label)) {
    return raw_confidence * SYMBOL_BOOST_FACTOR;
  }
  return raw_confidence;
}

WiFiClientSecure net;
PubSubClient client(net);

unsigned long last_wifi_check = 0;
int wifi_retry_count = 0;

// Custom ei_printf function for Edge Impulse
void ei_printf(const char *format, ...) {
  static char print_buf[1024] = { 0 };
  va_list args;
  va_start(args, format);
  int r = vsnprintf(print_buf, sizeof(print_buf), format, args);
  va_end(args);
  if (r > 0) Serial.write(print_buf);
}

// WiFi management functions (unchanged)
bool isWiFiProvisioned() {
  preferences.begin("wifi_creds", true);
  bool provisioned = preferences.getBool("provisioned", false);
  preferences.end();
  return provisioned;
}

void markWiFiProvisioned() {
  preferences.begin("wifi_creds", false);
  preferences.putBool("provisioned", true);
  preferences.end();
}

void clearWiFiProvisioned() {
  preferences.begin("wifi_creds", false);
  preferences.putBool("provisioned", false);
  preferences.end();
}

bool connectToStoredWiFi() {
  Serial.println("Attempting to connect to stored WiFi...");
  
  WiFi.mode(WIFI_STA);
  WiFi.begin();
  
  unsigned long start_time = millis();
  while (WiFi.status() != WL_CONNECTED && (millis() - start_time) < WIFI_CONNECT_TIMEOUT) {
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
    Serial.println("Failed to connect to stored WiFi");
    return false;
  }
}

void handleWiFiReconnection() {
  if (millis() - last_wifi_check < WIFI_RETRY_DELAY) {
    return;
  }
  
  last_wifi_check = millis();
  
  if (WiFi.status() != WL_CONNECTED && wifi_retry_count < MAX_WIFI_RETRIES) {
    Serial.print("WiFi disconnected. Retry attempt: ");
    Serial.print(wifi_retry_count + 1);
    Serial.print("/");
    Serial.println(MAX_WIFI_RETRIES);
    
    if (connectToStoredWiFi()) {
      wifi_retry_count = 0;
    } else {
      wifi_retry_count++;
    }
  } else if (wifi_retry_count >= MAX_WIFI_RETRIES) {
    Serial.println("Max WiFi retries reached. Device may need reprovisioning.");
    wifi_retry_count = 0;
  }
}

// Enhanced fuzzy logic function with improved circle detection
String evaluateGestureStability(String candidate_gesture, float confidence, float motion_score = 0.0) {
  bool is_symbol = isSymbolGesture(candidate_gesture);
  bool is_circle = isCircleGesture(candidate_gesture);
  float enhanced_confidence = calculateEnhancedConfidence(candidate_gesture, confidence, motion_score);
  
  // Add current prediction to history with motion analysis
  gesture_history[history_index].label = candidate_gesture;
  gesture_history[history_index].confidence = confidence;
  gesture_history[history_index].raw_confidence = confidence;
  gesture_history[history_index].timestamp = millis();
  gesture_history[history_index].count = 1;
  gesture_history[history_index].is_symbol = is_symbol;
  gesture_history[history_index].is_circle = is_circle;
  gesture_history[history_index].motion_pattern_score = motion_score;
  history_index = (history_index + 1) % STABILITY_WINDOW;
  
  // Enhanced gesture analysis with circle-specific logic
  struct GestureAnalysis {
    String label;
    float total_confidence;
    float max_confidence;
    int count;
    bool is_symbol;
    bool is_circle;
    float consistency_score;
    float motion_bonus;
    unsigned long latest_time;
  };
  
  GestureAnalysis analyses[15];
  int analysis_count = 0;
  
  // Analyze recent gesture history with enhanced temporal weighting
  unsigned long current_time = millis();
  for (int i = 0; i < STABILITY_WINDOW; i++) {
    if (gesture_history[i].label != "" && (current_time - gesture_history[i].timestamp) < 1000) {
      
      // Enhanced temporal weighting (more recent = higher weight)
      float temporal_weight = 1.0 - ((current_time - gesture_history[i].timestamp) / 1000.0) * 0.25;
      
      // Find existing analysis or create new one
      int found_idx = -1;
      for (int j = 0; j < analysis_count; j++) {
        if (analyses[j].label == gesture_history[i].label) {
          found_idx = j;
          break;
        }
      }
      
      if (found_idx >= 0) {
        analyses[found_idx].count++;
        analyses[found_idx].total_confidence += gesture_history[i].confidence * temporal_weight;
        if (gesture_history[i].confidence > analyses[found_idx].max_confidence) {
          analyses[found_idx].max_confidence = gesture_history[i].confidence;
        }
        if (gesture_history[i].timestamp > analyses[found_idx].latest_time) {
          analyses[found_idx].latest_time = gesture_history[i].timestamp;
        }
        // Add motion bonus for circles
        if (analyses[found_idx].is_circle) {
          analyses[found_idx].motion_bonus += gesture_history[i].motion_pattern_score;
        }
      } else if (analysis_count < 15) {
        analyses[analysis_count].label = gesture_history[i].label;
        analyses[analysis_count].total_confidence = gesture_history[i].confidence * temporal_weight;
        analyses[analysis_count].max_confidence = gesture_history[i].confidence;
        analyses[analysis_count].count = 1;
        analyses[analysis_count].is_symbol = gesture_history[i].is_symbol;
        analyses[analysis_count].is_circle = gesture_history[i].is_circle;
        analyses[analysis_count].latest_time = gesture_history[i].timestamp;
        analyses[analysis_count].motion_bonus = gesture_history[i].is_circle ? gesture_history[i].motion_pattern_score : 0.0;
        analysis_count++;
      }
    }
  }
  
  // Calculate enhanced consistency scores with circle-specific bonuses
  for (int i = 0; i < analysis_count; i++) {
    float stability_factor = (float)analyses[i].count / STABILITY_WINDOW;
    float avg_confidence = analyses[i].total_confidence / analyses[i].count;
    float recency_factor = 1.0 - ((current_time - analyses[i].latest_time) / 1000.0) * 0.15;
    
    analyses[i].consistency_score = (stability_factor * 0.35 + 
                                   avg_confidence * 0.45 + 
                                   analyses[i].max_confidence * 0.20) * 
                                   recency_factor;
    
    // Apply gesture-specific boosts
    if (analyses[i].is_circle) {
      analyses[i].consistency_score *= CIRCLE_BOOST_FACTOR;
      
      // Apply motion pattern bonus for circles
      if (analyses[i].motion_bonus > CIRCLE_MOTION_THRESHOLD) {
        analyses[i].consistency_score *= (1.0 + analyses[i].motion_bonus);
      }
    } else if (analyses[i].is_symbol) {
      analyses[i].consistency_score *= SYMBOL_BOOST_FACTOR;
    }
  }
  
  // Find best gesture using enhanced fuzzy rules with circle priority
  String best_gesture = "";
  float best_score = 0.0;
  float best_confidence = 0.0;
  
  for (int i = 0; i < analysis_count; i++) {
    float final_score = 0.0;
    float confidence_factor = analyses[i].max_confidence;
    float stability_factor = (float)analyses[i].count / STABILITY_WINDOW;
    float consistency = analyses[i].consistency_score;
    
    // Enhanced fuzzy rules with circle-specific priority
    if (analyses[i].is_circle) {
      // Circle-specific rules (most lenient)
      if (confidence_factor >= CIRCLE_CONFIDENCE_THRESHOLD) {
        if (confidence_factor >= 0.6) {
          final_score = consistency * 1.5; // High confidence circles
        } else if (confidence_factor >= 0.45 && stability_factor >= 0.3) {
          final_score = consistency * 1.4; // Medium confidence with some stability
        } else if (stability_factor >= 0.4) {
          final_score = consistency * 1.3; // Lower confidence but decent stability
        } else if (analyses[i].motion_bonus > CIRCLE_MOTION_THRESHOLD) {
          final_score = consistency * 1.35; // Motion pattern detected
        }
      }
    } else if (analyses[i].is_symbol) {
      // Other symbol rules
      if (confidence_factor >= SYMBOL_CONFIDENCE_THRESHOLD) {
        if (confidence_factor >= 0.7) {
          final_score = consistency * 1.3;
        } else if (confidence_factor >= 0.55 && stability_factor >= 0.4) {
          final_score = consistency * 1.2;
        } else if (stability_factor >= 0.6) {
          final_score = consistency * 1.1;
        }
      }
    } else {
      // Regular gesture rules
      if (confidence_factor >= VERY_HIGH_CONFIDENCE_THRESHOLD) {
        final_score = consistency * 1.25;
      } else if (confidence_factor >= HIGH_CONFIDENCE_THRESHOLD && stability_factor >= 0.4) {
        final_score = consistency * 1.1;
      } else if (confidence_factor >= MIN_CONFIDENCE_THRESHOLD && stability_factor >= 0.6) {
        final_score = consistency;
      }
    }
    
    // Additional boost for consistent recent predictions
    if (analyses[i].count >= 3 && (current_time - analyses[i].latest_time) < 300) {
      final_score *= 1.15;
    }
    
    // Priority boost for circles when motion pattern is detected
    if (analyses[i].is_circle && analyses[i].motion_bonus > CIRCLE_MOTION_THRESHOLD) {
      final_score *= 1.2;
    }
    
    if (final_score > best_score) {
      best_score = final_score;
      best_gesture = analyses[i].label;
      best_confidence = analyses[i].max_confidence;
    }
  }
  
  // Enhanced validation with gesture-specific thresholds
  float min_threshold, min_consistency;
  
  if (isCircleGesture(best_gesture)) {
    min_threshold = CIRCLE_CONFIDENCE_THRESHOLD;
    min_consistency = CIRCLE_CONSISTENCY_THRESHOLD;
  } else if (isSymbolGesture(best_gesture)) {
    min_threshold = SYMBOL_CONFIDENCE_THRESHOLD;
    min_consistency = CONSISTENCY_THRESHOLD * 0.8;
  } else {
    min_threshold = MIN_CONFIDENCE_THRESHOLD;
    min_consistency = CONSISTENCY_THRESHOLD;
  }
  
  if (best_score >= min_consistency && best_confidence >= min_threshold && best_gesture != "") {
    stable_confidence = best_confidence;
    return best_gesture;
  }
  
  return "";
}

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
      Serial.println("Use ESP BLE Provisioning app to configure WiFi");
      break;
      
    case ARDUINO_EVENT_PROV_CRED_RECV:
      Serial.println("Received WiFi credentials");
      Serial.print("SSID: ");
      Serial.println((const char *)e->event_info.prov_cred_recv.ssid);
      break;
      
    case ARDUINO_EVENT_PROV_CRED_FAIL:
      Serial.println("Provisioning failed!");
      if (e->event_info.prov_fail_reason == NETWORK_PROV_WIFI_STA_AUTH_ERROR) {
        Serial.println("WiFi password incorrect");
      } else {
        Serial.println("WiFi AP not found");
      }
      break;
      
    case ARDUINO_EVENT_PROV_CRED_SUCCESS:
      Serial.println("Provisioning successful");
      markWiFiProvisioned();
      wifi_provisioned = true;
      break;
      
    case ARDUINO_EVENT_PROV_END:
      Serial.println("Provisioning ended");
      provisioning_complete = true;
      break;
  }
}

void connectAWS() {
  if (!wifi_connected) {
    Serial.println("WiFi not connected, cannot connect to AWS");
    return;
  }

  Serial.println("Connecting to AWS IoT...");
  
  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);
  
  int attempts = 0;
  while (!client.connect(THINGNAME) && attempts < 10) {
    Serial.print("AWS connection attempt ");
    Serial.print(attempts + 1);
    Serial.println("/10");
    delay(2000);
    attempts++;
  }

  if (client.connected()) {
    Serial.println("Connected to AWS IoT!");
    client.subscribe(AWS_SUB);
    client.subscribe("firebase/device-control");
    Serial.println("Subscribed to topics");
    
    JsonDocument statusDoc;
    statusDoc["connected"] = true;
    publishMessage(statusDoc);
  } else {
    Serial.println("Failed to connect to AWS IoT");
  }
}

void publishMessage(JsonDocument &doc) {
  if (!client.connected()) {
    Serial.println("AWS not connected, cannot publish");
    return;
  }
  
  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  
  if (client.publish(AWS_PUB, jsonBuffer)) {
    Serial.print("Published: ");
    Serial.println(jsonBuffer);
  } else {
    Serial.println("Failed to publish message");
  }
}

void detectGesture() {
  sensors_event_t a, g, temp;
  
  if (millis() > last_interval_ms + INTERVAL_MS) {
    last_interval_ms = millis();
    mpu.getEvent(&a, &g, &temp);
    
    // Store motion data for circular motion analysis
    motion_history[motion_index % CIRCLE_PATTERN_WINDOW].ax = a.acceleration.x;
    motion_history[motion_index % CIRCLE_PATTERN_WINDOW].ay = a.acceleration.y;
    motion_history[motion_index % CIRCLE_PATTERN_WINDOW].az = a.acceleration.z;
    motion_history[motion_index % CIRCLE_PATTERN_WINDOW].timestamp = millis();
    motion_index++;
    
    features[feature_ix++] = a.acceleration.x;
    features[feature_ix++] = a.acceleration.y;
    features[feature_ix++] = a.acceleration.z;

    if (feature_ix == EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE) {
      signal_t signal;
      ei_impulse_result_t result;
      
      int err = numpy::signal_from_buffer(features, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal);
      if (err != 0) {
        feature_ix = 0;
        return;
      }
      
      unsigned long start_time = micros();
      EI_IMPULSE_ERROR res = run_classifier(&signal, &result, false);
      unsigned long inference_time = micros() - start_time;
      
      if (res != 0) {
        feature_ix = 0;
        return;
      }
      
      // Enhanced anomaly detection
      bool is_anomaly = false;
      #if EI_CLASSIFIER_HAS_ANOMALY == 1
      if (result.anomaly > ANOMALY_THRESHOLD) {
        is_anomaly = true;
        Serial.print("Anomaly detected: ");
        Serial.println(result.anomaly);
      }
      #endif
      
      if (!is_anomaly) {
        // Calculate circular motion score
        float motion_score = calculateCircularMotionScore();
        
        // Enhanced prediction selection
        float top_confidences[3] = {0.0, 0.0, 0.0};
        String top_labels[3] = {"", "", ""};
        
        for (size_t ix = 0; ix < EI_CLASSIFIER_LABEL_COUNT; ix++) {
          float current_val = result.classification[ix].value;
          String current_label = String(result.classification[ix].label);
          
          if (current_val > top_confidences[0]) {
            top_confidences[2] = top_confidences[1];
            top_labels[2] = top_labels[1];
            top_confidences[1] = top_confidences[0];
            top_labels[1] = top_labels[0];
            top_confidences[0] = current_val;
            top_labels[0] = current_label;
          } else if (current_val > top_confidences[1]) {
            top_confidences[2] = top_confidences[1];
            top_labels[2] = top_labels[1];
            top_confidences[1] = current_val;
            top_labels[1] = current_label;
          } else if (current_val > top_confidences[2]) {
            top_confidences[2] = current_val;
            top_labels[2] = current_label;
          }
        }
        
        String best_label = top_labels[0];
        float best_confidence = top_confidences[0];
        bool is_circle = isCircleGesture(best_label);
        bool is_symbol = isSymbolGesture(best_label);
        
        // Enhanced threshold selection with circle priority
        float min_threshold;
        if (is_circle) {
          min_threshold = CIRCLE_CONFIDENCE_THRESHOLD;
          // Apply motion pattern bonus for circles
          if (motion_score > CIRCLE_MOTION_THRESHOLD) {
            best_confidence *= (1.0 + motion_score * 0.5);
          }
        } else if (is_symbol) {
          min_threshold = SYMBOL_CONFIDENCE_THRESHOLD;
        } else {
          min_threshold = MIN_CONFIDENCE_THRESHOLD;
        }
        
        // Confidence gap analysis with circle consideration
        float confidence_gap = best_confidence - top_confidences[1];
        if (confidence_gap > 0.1 && best_confidence >= min_threshold) {
          best_confidence *= 1.05;
        }
        
        // Apply enhanced fuzzy logic with motion analysis
        if (best_confidence >= min_threshold) {
          String fuzzy_result = evaluateGestureStability(best_label, best_confidence, motion_score);
          
          if (fuzzy_result != "" && fuzzy_result != last_published_state) {
            unsigned long current_time = millis();
            unsigned long min_duration = is_circle ? MIN_GESTURE_DURATION * 0.7 : 
                                        (is_symbol ? MIN_GESTURE_DURATION * 0.8 : MIN_GESTURE_DURATION);
            
            if (current_time - last_gesture_time >= min_duration) {
              
              Serial.print("Gesture detected: ");
              Serial.print(fuzzy_result);
              Serial.print(" (confidence: ");
              Serial.print(stable_confidence);
              if (is_circle) {
                Serial.print(", motion_score: ");
                Serial.print(motion_score);
              }
              Serial.print(", inference: ");
              Serial.print(inference_time);
              Serial.println("μs)");
              
              // Publish to AWS
              JsonDocument doc;
              doc[fuzzy_result] = true;
              publishMessage(doc);
              
              last_published_state = fuzzy_result;
              last_gesture_time = current_time;
            }
          }
        }
      }
      
      feature_ix = 0;
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("Starting ESP32 with Enhanced Circle Detection...");
  
  // Initialize enhanced gesture history
  for (int i = 0; i < STABILITY_WINDOW; i++) {
    gesture_history[i].label = "";
    gesture_history[i].confidence = 0.0;
    gesture_history[i].raw_confidence = 0.0;
    gesture_history[i].timestamp = 0;
    gesture_history[i].count = 0;
    gesture_history[i].is_symbol = false;
    gesture_history[i].is_circle = false;
    gesture_history[i].motion_pattern_score = 0.0;
  }
  
  // Initialize motion history
  for (int i = 0; i < CIRCLE_PATTERN_WINDOW; i++) {
    motion_history[i].ax = 0.0;
    motion_history[i].ay = 0.0;
    motion_history[i].az = 0.0;
    motion_history[i].timestamp = 0;
  }
  
  // Initialize I2C for MPU6050
  Wire.begin(D6, D7);
  
  if (reset_provisioned) {
    Serial.println("Clearing stored WiFi credentials...");
    nvs_flash_erase();
    nvs_flash_init();
    clearWiFiProvisioned();
  }
  
  wifi_provisioned = isWiFiProvisioned();
  
  if (wifi_provisioned) {
    Serial.println("Device already provisioned. Attempting to connect...");
    
    WiFi.onEvent([](WiFiEvent_t event, WiFiEventInfo_t info) {
      if (event == ARDUINO_EVENT_WIFI_STA_DISCONNECTED) {
        Serial.println("WiFi disconnected, will attempt reconnection");
        wifi_connected = false;
      } else if (event == ARDUINO_EVENT_WIFI_STA_GOT_IP) {
        Serial.print("WiFi reconnected! IP: ");
        Serial.println(WiFi.localIP());
        wifi_connected = true;
        wifi_retry_count = 0;
      }
    });
    
    if (connectToStoredWiFi()) {
      Serial.println("Successfully connected using stored credentials!");
    } else {
      Serial.println("Failed to connect with stored credentials. Starting provisioning...");
      wifi_provisioned = false;
    }
  }
  
  if (!wifi_provisioned) {
    Serial.println("Starting BLE provisioning...");
    
    WiFi.onEvent(SysProvEvent);
    
    uint8_t uuid[16] = {0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 
                        0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02};
    
    WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, 
                            NETWORK_PROV_SCHEME_HANDLER_FREE_BLE,
                            NETWORK_PROV_SECURITY_1, 
                            pop, 
                            service_name, 
                            NULL, 
                            uuid, 
                            false);
    
    WiFiProv.printQR(service_name, pop, "ble");
    Serial.println("Scan the QR code above with ESP BLE Provisioning app");
    Serial.println("Or search for device: " + String(service_name));
    Serial.println("PIN: " + String(pop));
    
    Serial.println("Waiting for WiFi connection...");
    while (!wifi_connected) {
      delay(1000);
      Serial.print(".");
    }
  }
  
  Serial.println("\nWiFi connected successfully!");
  
  // Initialize MPU6050 with optimized settings
  Serial.println("Initializing MPU6050...");
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) delay(10);
  }
  
  Serial.println("MPU6050 Found!");
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_94_HZ);
  
  Serial.print("Features: ");
  Serial.println(EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE);
  Serial.print("Label count: ");
  Serial.println(EI_CLASSIFIER_LABEL_COUNT);
  Serial.println("Enhanced circle detection with motion analysis enabled");
  
  // Connect to AWS
  connectAWS();
  
  Serial.println("Setup complete - Enhanced circle detection active!");
}

void loop() {
  // Handle WiFi reconnection if disconnected
  if (!wifi_connected) {
    handleWiFiReconnection();
  }
  
  // Reconnect to AWS if disconnected (non-blocking)
  static unsigned long last_aws_check = 0;
  if (millis() - last_aws_check > 5000) {
    if (wifi_connected && !client.connected()) {
      Serial.println("AWS disconnected, attempting to reconnect...");
      connectAWS();
    }
    last_aws_check = millis();
  }
  
  // Handle MQTT messages
  if (client.connected()) {
    client.loop();
  }
  
  // Enhanced real-time gesture detection with circle priority
  detectGesture();
  
  // Minimal delay to prevent watchdog timeout
  yield();
}