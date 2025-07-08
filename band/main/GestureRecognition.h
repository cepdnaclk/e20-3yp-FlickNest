#ifndef GESTURE_RECOGNITION_H
#define GESTURE_RECOGNITION_H

#include <Arduino.h>
#include <Adafruit_MPU6050.h>
#include <ArduinoJson.h>
#include <wristband2_inferencing.h>

// ====== MACHINE LEARNING PARAMETERS ======
#define FREQUENCY_HZ 100
#define INTERVAL_MS (1000 / FREQUENCY_HZ)

// ADAPTIVE THRESHOLDING PARAMETERS
#define BASE_CONFIDENCE_THRESHOLD 0.25          
#define SYMBOL_CONFIDENCE_THRESHOLD 0.20        
#define DYNAMIC_THRESHOLD_FACTOR 0.2            
#define MAX_CONFIDENCE_THRESHOLD 0.65           
#define MIN_CONFIDENCE_THRESHOLD 0.10           

// CONTROL SYSTEM PARAMETERS
#define FILTER_ALPHA 0.5                        
#define DERIVATIVE_FILTER_ALPHA 0.6             
#define GESTURE_STATE_TIMEOUT 600               
#define CONFIDENCE_SMOOTHING_FACTOR 0.4         
#define PREDICTION_BUFFER_SIZE 4                

// DUPLICATE PREVENTION PARAMETERS
#define DUPLICATE_PREVENTION_TIME_MS 1000        // 1 second delay for same gesture

// ANOMALY DETECTION PARAMETERS
#define ADAPTIVE_ANOMALY_THRESHOLD 1.2          
#define ANOMALY_ADAPTATION_RATE 0.0             
#define SIGNAL_NOISE_THRESHOLD 0.5              

// ====== ML DATA STRUCTURES ======

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

// Gesture Recognition Results
struct GestureResult {
    String gesture;
    float confidence;
    float signal_quality;
    bool is_symbol;
    bool is_confirmed;
    unsigned long timestamp;
};

// ====== GESTURE RECOGNITION CLASS ======
class GestureRecognizer {
private:
    // ML Processing variables
    float features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
    size_t feature_ix = 0;
    unsigned long last_interval_ms = 0;
    
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
    String symbol_gestures[6] = {"peace", "ok", "thumbs_up", "thumbs_down", "fist", "open_hand"};
    int num_symbol_gestures = 6;
    
    // Current state tracking
    String current_gesture = "";
    String last_published_gesture = "";
    float current_confidence = 0.0;
    unsigned long last_gesture_time = 0;
    
    // MPU6050 reference
    Adafruit_MPU6050* mpu_sensor;
    
    // ====== PRIVATE METHODS ======
    
    // Digital filtering functions
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
        float magnitude = sqrt(x*x + y*y + z*z);
        float normalized_magnitude = magnitude / 9.81;
        float quality = min(1.0f, normalized_magnitude);
        return max(0.1f, quality);
    }
    
    // Adaptive anomaly detection
    void updateAdaptiveParams(float current_anomaly, float signal_quality) {
        unsigned long current_time = millis();
        
        if (current_time - adaptive_params.last_update > 100) {
            float target_threshold = ADAPTIVE_ANOMALY_THRESHOLD * (2.0 - signal_quality);
            
            adaptive_params.current_anomaly_threshold += 
                adaptive_params.adaptation_rate * (target_threshold - adaptive_params.current_anomaly_threshold);
            
            adaptive_params.current_anomaly_threshold = 
                constrain(adaptive_params.current_anomaly_threshold, 0.1, 1.0);
            
            adaptive_params.noise_level = 0.9 * adaptive_params.noise_level + 0.1 * current_anomaly;
            adaptive_params.signal_strength = signal_quality;
            adaptive_params.last_update = current_time;
        }
    }
    
    // Confidence control system
    float applyConfidenceControl(float raw_confidence, float signal_quality) {
        float target_confidence = raw_confidence * signal_quality;
        float error = target_confidence - conf_controller.prev_confidence;
        
        float proportional = conf_controller.proportional_gain * error;
        
        conf_controller.integral_sum += error;
        conf_controller.integral_sum = constrain(conf_controller.integral_sum, -10.0, 10.0);
        float integral = conf_controller.integral_gain * conf_controller.integral_sum;
        
        float derivative = conf_controller.derivative_gain * (error - conf_controller.prev_error);
        
        float controlled_confidence = raw_confidence + 0.1 * (proportional + integral + derivative);
        controlled_confidence = constrain(controlled_confidence, 0.0, 1.0);
        
        conf_controller.prev_error = error;
        conf_controller.prev_confidence = controlled_confidence;
        
        return controlled_confidence;
    }
    
    // Gesture classification helpers
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
        
        for (int i = 0; i < PREDICTION_BUFFER_SIZE; i++) {
            if (prediction_buffer[i].label == gesture_label && 
                (current_time - prediction_buffer[i].timestamp) < 500) {
                stability += prediction_buffer[i].filtered_confidence;
                count++;
            }
        }
        
        return count > 0 ? stability / count : 0.0;
    }
    
    // Check if gesture can be published (duplicate prevention)
    bool canPublishGesture(String gesture) {
        unsigned long current_time = millis();
        
        // Allow if it's a different gesture
        if (gesture != last_published_gesture) {
            return true;
        }
        
        // Allow same gesture if enough time has passed
        if (current_time - last_gesture_time >= DUPLICATE_PREVENTION_TIME_MS) {
            return true;
        }
        
        // Block duplicate within time window
        Serial.printf("ML Duplicate blocked: %s (last: %lu ms ago)\n", 
                     gesture.c_str(), current_time - last_gesture_time);
        return false;
    }
    
    // Gesture state machine
    String processGestureStateMachine(String predicted_gesture, float confidence, float signal_quality) {
        unsigned long current_time = millis();
        String result = "";
        
        bool is_symbol = isSymbolGesture(predicted_gesture);
        float threshold = is_symbol ? SYMBOL_CONFIDENCE_THRESHOLD : BASE_CONFIDENCE_THRESHOLD;
        threshold *= (0.7 + 0.3 * signal_quality);
        
        switch (current_gesture_state) {
            case IDLE:
                if (confidence >= threshold && predicted_gesture != "") {
                    current_gesture_state = DETECTING;
                    current_gesture = predicted_gesture;
                    state_entry_time = current_time;
                    Serial.printf("ML State: IDLE -> DETECTING (%s, conf: %.2f)\n", 
                                 predicted_gesture.c_str(), confidence);
                }
                break;
                
            case DETECTING:
                if (predicted_gesture == current_gesture && confidence >= threshold) {
                    float stability = calculateStabilityScore(current_gesture);
                    
                    if (stability >= threshold && (current_time - state_entry_time) >= 150) {
                        current_gesture_state = CONFIRMED;
                        current_confidence = confidence;
                        result = current_gesture;
                        Serial.printf("ML State: DETECTING -> CONFIRMED (%s, stability: %.2f)\n", 
                                     current_gesture.c_str(), stability);
                    }
                } else if (current_time - state_entry_time > 800) {
                    current_gesture_state = IDLE;
                    current_gesture = "";
                    Serial.println("ML State: DETECTING -> IDLE (timeout)");
                } else if (confidence < threshold * 0.7) {
                    current_gesture_state = IDLE;
                    current_gesture = "";
                    Serial.println("ML State: DETECTING -> IDLE (low confidence)");
                }
                break;
                
            case CONFIRMED:
                current_gesture_state = COOLDOWN;
                state_entry_time = current_time;
                Serial.println("ML State: CONFIRMED -> COOLDOWN");
                break;
                
            case COOLDOWN:
                if (current_time - state_entry_time > (is_symbol ? 300 : 500)) {
                    current_gesture_state = IDLE;
                    current_gesture = "";
                    Serial.println("ML State: COOLDOWN -> IDLE");
                }
                break;
        }
        
        return result;
    }
    
public:
    // ====== PUBLIC METHODS ======
    
    // Constructor
    GestureRecognizer(Adafruit_MPU6050* mpu) : mpu_sensor(mpu) {
        // Initialize prediction buffer
        for (int i = 0; i < PREDICTION_BUFFER_SIZE; i++) {
            prediction_buffer[i] = {"", 0.0, 0.0, 0.0, 0, false, 0.0};
        }
    }
    
    // Initialize the gesture recognition system
    bool initialize() {
        Serial.println("🧠 Initializing Gesture Recognition ML Module...");
        Serial.printf("Features: %d, Labels: %d\n", 
                      EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, EI_CLASSIFIER_LABEL_COUNT);
        Serial.printf("Base thresholds - Normal: %.2f, Symbol: %.2f\n",
                      BASE_CONFIDENCE_THRESHOLD, SYMBOL_CONFIDENCE_THRESHOLD);
        Serial.printf("Duplicate prevention time: %d ms\n", DUPLICATE_PREVENTION_TIME_MS);
        return true;
    }
    
    // Calibrate the sensor offsets
    void calibrateSensor() {
        Serial.println("🎯 ML Calibrating sensor... Keep device still for 3 seconds");
        delay(1000);
        
        float sum_x = 0, sum_y = 0, sum_z = 0;
        
        for (int i = 0; i < 100; i++) {
            sensors_event_t a, g, temp;
            mpu_sensor->getEvent(&a, &g, &temp);
            sum_x += a.acceleration.x;
            sum_y += a.acceleration.y;
            sum_z += a.acceleration.z - 9.81;
            delay(20);
        }
        
        accel_offset_x = sum_x / 100.0;
        accel_offset_y = sum_y / 100.0;
        accel_offset_z = sum_z / 100.0;
        
        Serial.println("🎯 ML Sensor calibration complete!");
        Serial.printf("ML Offsets - X: %.2f, Y: %.2f, Z: %.2f\n", 
                      accel_offset_x, accel_offset_y, accel_offset_z);
        sensor_calibrated = true;
    }
    
    // Main gesture detection function - call this in loop()
    GestureResult detectGesture() {
        GestureResult result = {"", 0.0, 0.0, false, false, millis()};
        
        if (millis() <= last_interval_ms + INTERVAL_MS) return result;
        
        last_interval_ms = millis();
        sensors_event_t a, g, temp;
        mpu_sensor->getEvent(&a, &g, &temp);
        
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
            ei_impulse_result_t ei_result;
            
            int err = numpy::signal_from_buffer(features, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal);
            if (err != 0) {
                feature_ix = 0;
                return result;
            }
            
            // Run classifier
            EI_IMPULSE_ERROR res = run_classifier(&signal, &ei_result, false);
            if (res != 0) {
                feature_ix = 0;
                return result;
            }
            
            // Enhanced anomaly detection
            bool is_valid = true;
            #if EI_CLASSIFIER_HAS_ANOMALY == 1
            updateAdaptiveParams(ei_result.anomaly, signal_quality);
            
            if (ei_result.anomaly > adaptive_params.current_anomaly_threshold) {
                is_valid = false;
                Serial.printf("ML Anomaly: %.3f > %.3f (adaptive)\n", 
                             ei_result.anomaly, adaptive_params.current_anomaly_threshold);
            }
            #endif
            
            if (is_valid) {
                // Find best prediction
                float max_confidence = 0.0;
                String best_label = "";
                
                for (size_t ix = 0; ix < EI_CLASSIFIER_LABEL_COUNT; ix++) {
                    float conf = ei_result.classification[ix].value;
                    if (conf > max_confidence) {
                        max_confidence = conf;
                        best_label = String(ei_result.classification[ix].label);
                    }
                }
                
                // Apply confidence control
                float controlled_confidence = applyConfidenceControl(max_confidence, signal_quality);
                
                // Update prediction buffer
                prediction_buffer[buffer_index] = {
                    best_label,
                    max_confidence,
                    controlled_confidence,
                    0.0,
                    millis(),
                    isSymbolGesture(best_label),
                    signal_quality
                };
                buffer_index = (buffer_index + 1) % PREDICTION_BUFFER_SIZE;
                
                // Process through state machine
                String confirmed_gesture = processGestureStateMachine(
                    best_label, controlled_confidence, signal_quality);
                
                // Return result if confirmed and passes duplicate check
                if (confirmed_gesture != "" && canPublishGesture(confirmed_gesture)) {
                    Serial.printf("🧠 ML CONFIRMED GESTURE: %s (conf: %.2f, quality: %.2f)\n",
                                 confirmed_gesture.c_str(), current_confidence, signal_quality);
                    
                    result.gesture = confirmed_gesture;
                    result.confidence = current_confidence;
                    result.signal_quality = signal_quality;
                    result.is_symbol = isSymbolGesture(confirmed_gesture);
                    result.is_confirmed = true;
                    result.timestamp = millis();
                    
                    last_published_gesture = confirmed_gesture;
                    last_gesture_time = millis();
                }
                
                // Debug output (reduced frequency)
                static unsigned long last_debug = 0;
                if (millis() - last_debug > 500) {
                    Serial.printf("ML Top: %s(%.2f->%.2f) Quality:%.2f State:%d\n",
                                 best_label.c_str(), max_confidence, controlled_confidence, 
                                 signal_quality, current_gesture_state);
                    last_debug = millis();
                }
            }
            
            feature_ix = 0;
        }
        
        return result;
    }
    
    // Get current ML system status
    void getStatus() {
        Serial.println("🧠 ML System Status:");
        Serial.printf("   Current State: %d\n", current_gesture_state);
        Serial.printf("   Last Gesture: %s\n", last_published_gesture.c_str());
        Serial.printf("   Last Gesture Time: %lu ms ago\n", millis() - last_gesture_time);
        Serial.printf("   Duplicate Prevention: %d ms\n", DUPLICATE_PREVENTION_TIME_MS);
        Serial.printf("   Anomaly Threshold: %.2f\n", adaptive_params.current_anomaly_threshold);
        Serial.printf("   Sensor Calibrated: %s\n", sensor_calibrated ? "Yes" : "No");
    }
    
    // Reset ML system state
    void reset() {
        current_gesture_state = IDLE;
        current_gesture = "";
        last_published_gesture = "";
        last_gesture_time = 0;
        feature_ix = 0;
        Serial.println("🧠 ML System Reset");
    }
    
    // Create JSON document for MQTT publishing
    JsonDocument createGestureJSON(const GestureResult& gestureResult) {
        JsonDocument doc;
        doc[gestureResult.gesture] = true;
        doc["confidence"] = gestureResult.confidence;
        doc["signal_quality"] = gestureResult.signal_quality;
        doc["is_symbol"] = gestureResult.is_symbol;
        doc["anomaly_threshold"] = adaptive_params.current_anomaly_threshold;
        doc["timestamp"] = gestureResult.timestamp;
        doc["ml_module"] = "v1.0";
        doc["duplicate_prevention_ms"] = DUPLICATE_PREVENTION_TIME_MS;
        return doc;
    }
};

#endif // GESTURE_RECOGNITION_H