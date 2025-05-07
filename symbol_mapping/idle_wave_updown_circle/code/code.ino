#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>
#include <symbol_mapper_cloned2_inferencing.h>

#define FREQUENCY_HZ        60
#define INTERVAL_MS         (1000 / (FREQUENCY_HZ + 1))

Adafruit_MPU6050 mpu;

float features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
size_t feature_ix = 0;
static unsigned long last_interval_ms = 0;

String last_state = "";  // Track last printed state

void setup() {
  Serial.begin(115200);

  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) delay(10);
  }
  Serial.println("MPU6050 Found!");

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  Serial.print("Features: ");
  Serial.println(EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE);
  Serial.print("Label count: ");
  Serial.println(EI_CLASSIFIER_LABEL_COUNT);
}

void loop() {
  sensors_event_t a, g, temp;

  if (millis() > last_interval_ms + INTERVAL_MS) {
    last_interval_ms = millis();

    mpu.getEvent(&a, &g, &temp);

    features[feature_ix++] = a.acceleration.x;
    features[feature_ix++] = a.acceleration.y;
    features[feature_ix++] = a.acceleration.z;

    if (feature_ix == EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE) {
      signal_t signal;
      ei_impulse_result_t result;
      int err = numpy::signal_from_buffer(features, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal);
      if (err != 0) {
        ei_printf("Failed to create signal from buffer (%d)\n", err);
        return;
      }

      EI_IMPULSE_ERROR res = run_classifier(&signal, &result, false);
      if (res != 0) return;

      String current_state = "";

      #if EI_CLASSIFIER_HAS_ANOMALY == 1
        if (result.anomaly >= 0.0f) {
          current_state = "anomaly";
        } else {
          float max_val = 0.0;
          const char* max_label = "";

          for (size_t ix = 0; ix < EI_CLASSIFIER_LABEL_COUNT; ix++) {
            if (result.classification[ix].value > 0.6 && result.classification[ix].value > max_val) {
              max_val = result.classification[ix].value;
              max_label = result.classification[ix].label;
            }
          }

          if (strlen(max_label) > 0) {
            current_state = String(max_label);
          }
        }
      #endif

      // Only print if state changed
      if (current_state != "" && current_state != last_state) {
        Serial.print("Symbol detected: ");
        Serial.println(current_state);
        last_state = current_state;
      }

      feature_ix = 0;
    }
  }
}

void ei_printf(const char *format, ...) {
  static char print_buf[1024] = { 0 };
  va_list args;
  va_start(args, format);
  int r = vsnprintf(print_buf, sizeof(print_buf), format, args);
  va_end(args);
  if (r > 0) Serial.write(print_buf);
}
