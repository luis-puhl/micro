import serial
# /dev/ttyUSB0
ser = serial.Serial('/dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0', 9600, timeout=1)	
print ser.read()
ser.write("hello")      #write a string
ser.close()
