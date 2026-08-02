# Soan Papdi - MAX7219 8x8 LED Matrix

This project drives an 8x8 LED matrix through a MAX7219 driver chip using the Soan Papdi iCE40UP5K board. Three slide switches set a value from 0 to 7, shown as a bar graph on the matrix by default.

## Files

- top.v - reads the switches(remove if not needed) and generates the row data, connects to the max module
- max.v - handles the MAX7219 init sequence and sends row data over SPI, this file does not need to change
- pin.pcf - pin mapping for the board

## How it works

top.v builds eight 8 bit values, row0 through row7, one for each row of the matrix. Whatever pattern of 1s and 0s ends up in these rows is what lights up. max.v just takes these rows and pushes them out over SPI, it does not care how the rows were generated, so all your creative work happens in top.v.

## Display modes in top.v

### Bar graph, default mode

Flip the switches to a value from 0 to 7, that many columns light up from the left. This is the active block by default.

### Static pattern

There is a commented out block further down in top.v meant for drawing a fixed shape. Each row gets its own line, and each line is just eight bits, one bit per LED in that row. Uncomment the block and flip any bit to a 1 to light that LED, or 0 to leave it off.

### Animation

Also commented out, sits below the static pattern block. Instead of storing a shape, it keeps a counter that increases over time and uses it to calculate which single LED should be lit at that moment, walking one dot across all 64 positions of the matrix, row by row, left to right, then looping back to the start. Since the position is calculated from a growing counter rather than looked up from stored data, you can build any other animation on top of this same idea, just change how the counter maps to which LEDs turn on.

## NOTE:- Only one of these three blocks should be active at a time, since they all try to control the same row0 through row7 signals. Comment out or remove whichever ones you are not using at the moment.

## Build and upload

Run apio build to synthesize, then apio upload to flash it to the board.

## Pin connections, FPGA to MAX7219

| Signal | FPGA Pin | MAX7219 Pin |
|--------|----------|-------------|
| din    | 28       | DIN         |
| sclk   | 26       | CLK         |
| cs     | 27       | CS / LOAD   |
| clk    | 35       | onboard 12 MHz clock, not connected to MAX7219 |
| rst_n  | 12       | reset button, not connected to MAX7219 |
| -      | -        | VCC to 5V or 3.3V depending on your module |
| -      | -        | GND to GND  |

## Pin connections, switches

| Signal      | FPGA Pin |
|-------------|----------|
| switches[0] | 48       |
| switches[1] | 3        |
| switches[2] | 4        |
