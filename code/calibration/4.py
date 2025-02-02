import serial

# Open the serial port COM8
ser = serial.Serial('COM8', baudrate=115200, timeout=1)

while True:
    try:
        # Read a line from the serial port, decode it, and strip any leading/trailing whitespace
        line = ser.readline().decode('utf-8').strip()
        
        # Skip empty lines
        if not line:
            continue
        
        # Debug: Print the received line
        print(line)

    except serial.SerialException as e:
        # Handle errors related to the serial port (e.g., port not found)
        print(f"Serial error: {e}")
        break  # Exit the loop if there's a serial error

    except Exception as e:
        # Catch any other unexpected errors
        print(f"Unexpected error: {e}")
        break  # Exit the loop if there's any unexpected error

# Close the serial port
ser.close()
print("Serial port closed.")
