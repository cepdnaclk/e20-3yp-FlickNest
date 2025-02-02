import time
import numpy as np
import serial
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from scipy.integrate import cumulative_trapezoid as cumtrapz

from ahrs.filters import Madgwick
from ahrs.common.orientation import acc2q

# Initialize Serial Port (Modify as needed)
ser = serial.Serial('COM9', 115200)  # Adjust the COM port

# Initialize Madgwick Filter
madgwick = Madgwick()

# Initial quaternion (Identity quaternion to start)
q = np.array([1.0, 0.0, 0.0, 0.0])

# Position, Velocity, and Time Tracking
position = np.array([0.0, 0.0, 0.0])  # Initial position [x, y, z]
velocity = np.array([0.0, 0.0, 0.0])  # Initial velocity [vx, vy, vz]
prev_time = None  # Used for time integration

# Data storage for plotting
pos_x, pos_y, pos_z = [], [], []

def process_mpu6050_data(data):
    """Process the raw sensor data from MPU6050 and compute position."""
    global q, velocity, position, prev_time

    try:
        values = list(map(float, data.split(',')))  # Convert CSV string to float list
        
        if len(values) < 7:
            return None

        timestamp, ax, ay, az, gx, gy, gz = values[:7]  # Ignore temperature

        # Convert gyroscope data from degrees/sec to radians/sec
        gx, gy, gz = np.radians([gx, gy, gz])

        # If quaternion is at the initial state, estimate it from accelerometer
        if np.array_equal(q, np.array([1.0, 0.0, 0.0, 0.0])):
            q = acc2q([ax, ay, az])  

        # Apply Madgwick Filter to update orientation
        q = madgwick.updateIMU(q, gyr=[gx, gy, gz], acc=[ax, ay, az])

        # Convert quaternion to rotation matrix
        R = np.array([
            [1 - 2 * (q[2] ** 2 + q[3] ** 2), 2 * (q[1] * q[2] - q[0] * q[3]), 2 * (q[1] * q[3] + q[0] * q[2])],
            [2 * (q[1] * q[2] + q[0] * q[3]), 1 - 2 * (q[1] ** 2 + q[3] ** 2), 2 * (q[2] * q[3] - q[0] * q[1])],
            [2 * (q[1] * q[3] - q[0] * q[2]), 2 * (q[2] * q[3] + q[0] * q[1]), 1 - 2 * (q[1] ** 2 + q[2] ** 2)]
        ])

        # Transform accelerometer readings to world coordinates
        acc_world = R @ np.array([ax, ay, az])

        # Subtract gravity (assuming gravity acts along Z-axis)
        acc_world[2] -= 9.81  

        # Compute time difference (dt)
        if prev_time is None:
            prev_time = timestamp
            return position  # No update on first run

        dt = (timestamp - prev_time) / 1000.0  # Convert ms to seconds
        prev_time = timestamp  # Update previous time

        # Integrate acceleration to get velocity (Trapezoidal Integration)
        velocity += acc_world * dt

        # Integrate velocity to get position (Trapezoidal Integration)
        position += velocity * dt

        return position

    except Exception as e:
        print("Error processing data:", e)
        return None

# Initialize Matplotlib figure for 3D plot
fig = plt.figure(figsize=(8, 6))
ax = fig.add_subplot(111, projection='3d')
ax.set_title("MPU6050 Position Tracking (50 cm Scale)")
ax.set_xlabel("X Position (m)")
ax.set_ylabel("Y Position (m)")
ax.set_zlabel("Z Position (m)")

# Set axis limits for 50 cm movement range
ax.set_xlim(-0.5, 0.5)  # X-axis (meters)
ax.set_ylim(-0.5, 0.5)  # Y-axis (meters)
ax.set_zlim(-0.5, 0.5)  # Z-axis (meters)

def update(frame):
    """Updates the 3D plot in real-time."""
    raw_data = ser.readline().decode('utf-8').strip()
    result = process_mpu6050_data(raw_data)

    if result is not None:
        x, y, z = result
        pos_x.append(x)
        pos_y.append(y)
        pos_z.append(z)

        # Keep only last 200 points for real-time effect
        if len(pos_x) > 200:
            pos_x.pop(0)
            pos_y.pop(0)
            pos_z.pop(0)

        ax.clear()
        ax.plot(pos_x, pos_y, pos_z, color='b', label="Path")
        ax.scatter(pos_x[-1], pos_y[-1], pos_z[-1], color='r', marker='o', label="Current Position")

        # Set axis limits for 50 cm movement
        ax.set_xlim(-0.5, 0.5)
        ax.set_ylim(-0.5, 0.5)
        ax.set_zlim(-0.5, 0.5)

        ax.legend()

    return ax

# Animate real-time 3D position tracking
ani = FuncAnimation(fig, update, interval=50, blit=False)
plt.show()

# Close Serial Connection when done
ser.close()
