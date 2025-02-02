import serial
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import numpy as np

# Initialize data containers
x_vals = []
y_vals = []  # For storing the calculated positions

# Define the serial data reading function
def read_serial_data(port, baud_rate=9600, timeout=1):
    """
    Generator function to read data from the serial port.
    """
    try:
        with serial.Serial(port, baud_rate, timeout=timeout) as esp32:
            print(f"Connected to {port} at {baud_rate} baud.")
            while True:
                data = esp32.readline().decode('utf-8').strip()
                
                # Skip empty or invalid data
                if not data:
                    continue
                
                data_split = data.split(',')
                if len(data_split) >= 7:
                    try:
                        # Yield the correct data values for accel and gyro
                        accel_data = (float(data_split[0]), float(data_split[1]), float(data_split[2]))
                        gyro_data = (float(data_split[3]), float(data_split[4]), float(data_split[5]))
                        yield accel_data, gyro_data
                    except ValueError:
                        # Skip lines where conversion fails
                        print(f"Skipping invalid data: {data}")
                        continue
    except serial.SerialException as e:
        print(f"Serial error: {e}")

# Function to update the plot in real-time
def update_plot(frame, x_vals, y_vals):
    # Extract accel and gyro data from the frame
    accel_data, gyro_data = frame
    
    # Calculate position using accelerometer and gyroscope data
    position = calculate_coordinates([accel_data], [gyro_data])

    # Increment the x value for time progression
    x_vals.append(x_vals[-1] + 1 if x_vals else 0)
    y_vals.append(position[0])  # Store the x-coordinate (you can store y and z as well)

    # Limit the number of points to display (optional)
    if len(x_vals) > 50:
        x_vals.pop(0)
        y_vals.pop(0)

    # Clear the current plot and plot the new data
    plt.cla()
    plt.plot(x_vals, y_vals, label='X Position')
    
    plt.legend(loc='upper left')
    plt.xlabel("Time (s)")
    plt.ylabel("Position (X)")
    plt.tight_layout()

# Initialize the serial data generator
serial_data_gen = read_serial_data("COM8", baud_rate=115200)

# Create the real-time plot
fig, ax = plt.subplots(figsize=(10, 6))
ax.set_xlim(0, 50)  # Adjust this to the desired number of data points to show
ax.set_ylim(-5, 5)  # Adjust this based on the expected range of position

# Set up the FuncAnimation object
ani = FuncAnimation(fig, update_plot, serial_data_gen, fargs=(x_vals, y_vals), interval=100)

# Show the plot
plt.show()
