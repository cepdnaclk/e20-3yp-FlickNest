from machine import Pin, I2C
import time
from mpu6050 import MPU6050
import sys

# Initialize I2C for ESP32 (Modify pins if needed)
i2c = I2C(0, scl=Pin(22), sda=Pin(21))

# Initialize MPU6050
mpu = MPU6050(i2c)

print("ESP32 Ready...")

while True:
    # Get sensor readings
    accel = mpu.accel
    gyro = mpu.gyro
    temp = mpu.temperature
    timestamp = time.ticks_ms()

    # Send data as CSV over UART (Serial)
    sys.stdout.write(f"{timestamp},{accel[0]},{accel[1]},{accel[2]},{gyro[0]},{gyro[1]},{gyro[2]},{temp}\n")
    sys.stdout.flush()

    time.sleep(0.1)  # Small delay for stability
