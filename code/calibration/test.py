import serial
import time

# Initialize serial connection
ser = serial.Serial('COM9', 115200, timeout=1)  # Replace 'COM9' with your actual port
time.sleep(2)

# Print header for better visualization
print("\n" + "=" * 90)
print("{:<12} {:<12} {:<12} {:<12} {:<12} {:<12} {:<12}".format(
    "Accel_X", "Accel_Y", "Accel_Z", "Gyro_X", "Gyro_Y", "Gyro_Z", "Temp"
))
print("=" * 90)

try:
    while True:
        if ser.in_waiting > 0:  # Check if data is available
            raw_data = ser.readline().decode('utf-8').strip()  # Read and decode data
            values = raw_data.split(",")  # Split data by delimiter

            # Validate and parse data
            if len(values) == 7:
                try:
                    accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z, temp = map(float, values)
                    print("{:<12.3f} {:<12.3f} {:<12.3f} {:<12.3f} {:<12.3f} {:<12.3f} {:<12.2f}".format(
                        accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z, temp
                    ))
                except ValueError:
                    print(f"⚠ Malformed data skipped (conversion error): {raw_data}")
            else:
                print(f"⚠ Incomplete data skipped: {raw_data}")
except KeyboardInterrupt:
    print("\nExiting...")
finally:
    ser.close()
