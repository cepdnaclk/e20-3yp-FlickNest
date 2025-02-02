import serial
import matplotlib
matplotlib.use('Qt5Agg')  # Use Qt5Agg or Agg for non-interactive mode
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import time

# Set up the serial port
ser = serial.Serial('CO83', 112500)  # Replace 'COM3' with your actual serial port
ser.flushInput()

# Set up the plot
fig, ax = plt.subplots(figsize=(8, 6))

# Time lists to hold time data and sensor values
times = []
data_1 = []
data_2 = []

line1, = ax.plot([], [], label='Data 1', marker='o')
line2, = ax.plot([], [], label='Data 2', marker='o')

ax.set_xlabel('Time')
ax.set_ylabel('Value')
ax.set_title('Live Data from Serial Port')
ax.legend()
ax.grid(True)

# Function to update the plot
def update(frame):
    # Read data from serial port with error handling
    if ser.in_waiting > 0:
        data = ser.readline().decode('utf-8', errors='ignore').strip()
        try:
            # Parse the incoming comma-separated data
            values = list(map(float, data.split(',')))

            # Get the current time in seconds since the epoch
            current_time = time.time()

            # Append data to respective lists
            data_1.append(values[0])  # Assuming first value goes to data_1
            data_2.append(values[3])  # Assuming 4th value goes to data_2
            times.append(current_time)  # Add timestamp

            # Limit the number of data points to 10
            if len(times) > 10:
                times.pop(0)
                data_1.pop(0)
                data_2.pop(0)

            # Update the plot data
            line1.set_data(times, data_1)
            line2.set_data(times, data_2)

        except ValueError:
            pass  # Ignore invalid data

    return line1, line2

# Animate the plot
ani = FuncAnimation(fig, update, interval=1000, blit=True)

# Show the plot
plt.show()
