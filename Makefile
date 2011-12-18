ARDUINO_DIR  = /home/david/Projekt/arduino/arduino-mattair
ARDUINO_CORE_PATH = /home/david/Projekt/arduino/arduino-mattair/hardware/arduino/cores/usbavr

TARGET       = firecrow
ARDUINO_LIBS = XBee

BOARD_TAG    = firecrow
ARDUINO_PORT = /dev/ttyUSB0

AVR_TOOLS_PATH = /usr/bin
AVRDUDE_CONF   = /etc/avrdude/avrdude.conf

include /home/david/Projekt/arduino/arduino-mk-0.6/Arduino.mk
