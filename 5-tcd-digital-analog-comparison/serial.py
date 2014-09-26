import serial

# /dev/ttyUSB0
ser = serial.Serial('/dev/ttyUSB0', 19200, timeout=1)
print ser.portstr       #check which port was really used
ser.write("hello")      #write a string
ser.close()
