# Soan Papdi - HC-SR04 Ultrasonic Sensor

This project reads distance from an HC-SR04 ultrasonic sensor using the Soan Papdi iCE40UP5K board (12 MHz clock) and lights up 8 LEDs like a distance meter. As an object gets closer to the sensor, more LEDs light up one by one.

## Files

- top.v - connects everything together, takes the measured distance from the sensor module and turns on the 8 LEDs based on how close an object is
- ultrasonic_sensor.v - sends a 10us trigger pulse to the HC-SR04 and measures how long the echo pulse stays high to calculate distance

## How it works

The sensor module sends a short 10us pulse on the trig pin every 60ms to tell the HC-SR04 to take a distance reading. The sensor responds by pulling its echo pin high, and the time echo stays high is proportional to how far away the object is. top.v splits the measured distance into 8 zones, from 0 to 40 cm. If an object is far away, 35 to 40 cm, only 1 LED turns on. As it gets closer, LEDs light up one by one until all 8 LEDs are on at under 5 cm. If nothing is in range, all LEDs stay off.

## Protect your FPGA pin

The HC-SR04 sensor runs on 5V, so its echo pin outputs 5V signals. The iCE40UP5K FPGA inputs only tolerate 3.3V max, so you need a resistor divider between the sensor Echo pin and your FPGA pin to drop 5V down to 3.3V.

Build this circuit:

HC-SR04 Echo (5V) ----[ 1 kOhm Resistor ]----+---- FPGA Input Pin (3.3V)
                                             |
                                      [ 2 kOhm Resistor ]
                                             |
                                           GND (0V)


## Pin connections

| Signal      | FPGA Pin              | Description |
|-------------|------------------------|-------------|
| clk         | 35                     | Onboard 12 MHz clock |
| trig        | 27                     | HC-SR04 Trig pin |
| echo        | 28                     | HC-SR04 Echo pin (through resistor circuit) |
| leds[7:0]   | Onboard LEDs D0 to D8  | Map leds[7:0] to onboard LEDs D0 to D8 in pins.pcf |
| VCC         | 3v3                     | Connect HC-SR04 VCC to 3V3 power |
| GND         | GND                    | Connect HC-SR04 GND to FPGA GND |
