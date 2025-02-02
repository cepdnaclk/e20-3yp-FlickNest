import serial
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from scipy.integrate import cumulative_trapezoid

# Set up plot style
plt.style.use('ggplot')  # Matplotlib visual style

# Initialize serial port
ser = serial.Serial('COM8', baudrate=115200, timeout=1)

# Initialize data storage
time_data = []
accel_data = [[], [], []]  # Accelerometer data
gyro_data = [[], [], []]  # Gyroscope data
position_data = [[], [], []]  # X, Y, Z positions

# Sampling time (update interval in seconds)
dt = 0.1  # 100ms

# Gravity constant (assume for now)
GRAVITY = 9.81

# Update function for animation
def update(frame):
    global time_data, accel_data, gyro_data, position_data

    # Read and parse data from serial port
    try:
        line = ser.readline().decode('utf-8').strip()

        # Skip empty lines
        if not line:
            return

        # Debug: Print raw line
        print(f"Raw data: {line}")

        # Remove trailing comma, if present
        if line.endswith(','):
            line = line[:-1]

        # Split and validate data
        values = line.split(",")
        if len(values) != 7:
            print(f"Invalid data: {line}")
            return

        # Convert to floats
        values = [float(x) for x in values]

        # Separate accelerometer and gyroscope data
        accel = values[:3]  # Accelerometer: [Ax, Ay, Az]
        gyro = values[4:]   # Gyroscope: [Gx, Gy, Gz]

        # Append accelerometer and gyroscope data
        time_data.append(len(time_data) * dt)
        for i in range(3):
            accel_data[i].append(accel[i])
            gyro_data[i].append(gyro[i])

        # Remove gravity (assuming Z-axis is vertical)
        accel_corrected = [
            accel[0],  # Ax
            accel[1],  # Ay
            accel[2] - GRAVITY  # Az (gravity compensated)
        ]

        # Calculate velocity and position
        if len(time_data) > 1:
            # Integrate acceleration to get velocity
            velocity = [cumulative_trapezoid(accel_corrected[i], time_data, initial=0)[-1] for i in range(3)]
            # Integrate velocity to get position
            position = [cumulative_trapezoid(velocity[i], time_data, initial=0)[-1] for i in range(3)]
        else:
            velocity = [0, 0, 0]
            position = [0, 0, 0]

        # Append position data
        for i in range(3):
            position_data[i].append(position[i])

        # Limit data size for smooth animation
        max_points = 100
        if len(time_data) > max_points:
            time_data = time_data[-max_points:]
            for i in range(3):
                accel_data[i] = accel_data[i][-max_points:]
                gyro_data[i] = gyro_data[i][-max_points:]
                position_data[i] = position_data[i][-max_points:]
    except ValueError as e:
        print(f"ValueError: {e}")
    except Exception as e:
        print(f"Error: {e}")

    # Clear and redraw plots
    ax1.clear()
    ax2.clear()
    ax3.clear()

    # Plot accelerometer data
    ax1.plot(time_data, accel_data[0], label="AccelX")
    ax1.plot(time_data, accel_data[1], label="AccelY")
    ax1.plot(time_data, accel_data[2], label="AccelZ")
    ax1.set_title("Time vs Accel")
    ax1.legend()
    ax1.grid(True)

    # Plot gyroscope data
    ax2.plot(time_data, gyro_data[0], label="GyroX")
    ax2.plot(time_data, gyro_data[1], label="GyroY")
    ax2.plot(time_data, gyro_data[2], label="GyroZ")
    ax2.set_title("Time vs Gyro")
    ax2.legend()
    ax2.grid(True)

    # Plot 3D position data (relative path)
    ax3.plot(position_data[0], position_data[1], position_data[2], label="Path")
    ax3.set_title("Relative Path")
    ax3.set_xlabel("X")
    ax3.set_ylabel("Y")
    ax3.set_zlabel("Z")
    ax3.legend()
    ax3.grid(True)

# Set up figure and axes
fig = plt.figure(figsize=(10, 12))
ax1 = fig.add_subplot(311)
ax2 = fig.add_subplot(312)
ax3 = fig.add_subplot(313, projection='3d')

# Configure animation
ani = FuncAnimation(fig, update, interval=1)

# Show plot
plt.tight_layout()
plt.show()

# Close serial port on exit
ser.close()
