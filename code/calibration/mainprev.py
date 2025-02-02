import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import time
import serial

# Sampling rate (time step)
dt = 0.05  # 20 updates per second

# Initialize Kalman filter variables
position = np.array([0.0, 0.0, 0.0])
velocity = np.array([0.0, 0.0, 0.0])
position_cov = np.eye(3)  # Initial position covariance matrix

# Kalman filter noise parameters
process_noise = 0.1 * np.eye(3)  # Process noise covariance
measurement_noise = 0.05 * np.eye(3)  # Measurement noise covariance

# Initialize orientation
orientation = np.array([0.0, 0.0, 0.0])  # [pitch, roll, yaw]

# Gravity vector (assume IMU is upright)
gravity = np.array([0, 0, 9.81])
alpha = 0.98  # Complementary filter constant

# Initialize low-pass filter state
accel_filtered_prev = np.array([0.0, 0.0, 0.0])

# Setup live plotting
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
ax.set_xlim(-3, 3)
ax.set_ylim(-3, 3)
ax.set_zlim(0, 3)
ax.set_xlabel("X (m)")
ax.set_ylabel("Y (m)")
ax.set_zlabel("Z (m)")
ax.set_title("Real-Time 3D Path Mapping (IMU Data)")
plt.ion()

positions = []  # Store positions for visualization

# Setup serial connection (change this to your port and baud rate)
serial_port = 'COM9'
baud_rate = 115200
ser = serial.Serial(serial_port, baud_rate, timeout=1)

# Wait for the serial connection to initialize
time.sleep(2)

try:
    while True:
        # Read data from the serial port
        if ser.in_waiting > 0:
            data = ser.readline().decode('utf-8', errors='ignore').strip()

            # Parse and clean the data
            try:
                values = data.replace(',', '').split()
                if len(values) >= 6:
                    # Read accelerometer and gyroscope data
                    # Accelerometer data (X, Y, Z)
                    accel = np.array([float(values[0]), float(values[1]), float(values[2])])
                    # Gyroscope data (X, Y, Z)
                    gyro = np.array([float(values[3]), float(values[4]), float(values[5])])

                    # Low-pass filter for accelerometer
                    accel_filtered = alpha * accel + (1 - alpha) * accel_filtered_prev
                    accel_filtered_prev = accel_filtered

                    # Estimate pitch and roll from accelerometer
                    pitch_acc = np.arctan2(accel_filtered[1], accel_filtered[2])
                    roll_acc = np.arctan2(-accel_filtered[0], np.sqrt(accel_filtered[1]**2 + accel_filtered[2]**2))

                    # Complementary filter for orientation
                    orientation[0] = alpha * (orientation[0] + gyro[0] * dt) + (1 - alpha) * pitch_acc
                    orientation[1] = alpha * (orientation[1] + gyro[1] * dt) + (1 - alpha) * roll_acc
                    orientation[2] += gyro[2] * dt

                    # Correct accelerometer readings for gravity
                    gravity_corrected = gravity * np.array([np.cos(orientation[1]), np.cos(orientation[0]), 1])
                    accel_corrected = accel_filtered - gravity_corrected

                    # Dynamic threshold adjustment
                    dynamic_threshold = max(0.05, 0.01 * np.linalg.norm(accel_corrected))
                    if np.linalg.norm(accel_corrected) < dynamic_threshold:
                        accel_corrected = np.array([0.0, 0.0, 0.0])
                        velocity = np.array([0.0, 0.0, 0.0])

                    # Update Kalman filter
                    velocity += accel_corrected * dt
                    predicted_position = position + velocity * dt
                    predicted_cov = position_cov + process_noise

                    # Measurement update
                    kalman_gain = predicted_cov @ np.linalg.inv(predicted_cov + measurement_noise)
                    position = predicted_position + kalman_gain @ (position - predicted_position)
                    position_cov = (np.eye(3) - kalman_gain) @ predicted_cov

                    # Append position for visualization
                    positions.append(position.copy())

                    # Live plotting
                    positions_np = np.array(positions)
                    ax.clear()
                    ax.set_xlim(-3, 3)
                    ax.set_ylim(-3, 3)
                    ax.set_zlim(0, 3)
                    ax.set_xlabel("X (m)")
                    ax.set_ylabel("Y (m)")
                    ax.set_zlabel("Z (m)")
                    ax.set_title("Real-Time 3D Path Mapping (IMU Data)")
                    ax.plot(positions_np[:, 0], positions_np[:, 1], positions_np[:, 2], color="blue", linewidth=2)
                    ax.scatter(position[0], position[1], position[2], color="red", s=100, label="Current Position")
                    ax.legend()
                    plt.draw()
                    plt.pause(dt)

            except ValueError:
                print(f"Error parsing data: {data}")

except KeyboardInterrupt:
    print("Stopping real-time path mapping.")

finally:
    ser.close()  # Close the serial connection
