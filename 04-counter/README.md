# Soan Papdi - Up/Down Counter & Stopwatch

This is a 3-digit counter that runs on the Soan Papdi iCE40UP5K board and shows its count on a 3-digit 7-segment display. It can count up, count down, or act as a stopwatch (counting up in 0.1 sec). You can run/pause it and reset it back to 0.

## Files
- `top.v` - It divides the 12 MHz clock down to timing pulses, runs the actual counter, and multiplexes the count out to the 3-digit display.

## How it works

**Clock divider** - The board clock runs at 12 MHz. Two counters divide it down: one ticks once every second (for the up/down modes), the other ticks 10 times a second (for the stopwatch mode, so it can show tenths of a second).

**Counter** - Three 4-bit registers hold the ones, tens, and hundreds digit, each in BCD (0-9). Pulling `reset` high resets all three digits back to 0.

**Display** - You only get one set of 7 segment lines but there are 3 digits to show. So instead of driving all 3 digits at once, the board rapidly switches between them: it lights up digit 1 for a moment, then digit 2, then digit 3, then back to digit 1, over and over. The `comm` signal is what picks which digit is currently active - it's active-low, so pulling one of the 3 lines low turns that digit on while the other two stay off.

**7-segment decoding** - Whichever digit is currently selected gets converted from its BCD value into the actual segment pattern (which of the 7 LED segments to light up to draw that digit), and sent out on `seg`.


## Pin connections

| Signal    | FPGA Pin | Description |
|-----------|----------|-------------|
| clk       | 35       | Onboard 12 MHz clock |
| mode[0]   | 3        | Mode select |
| mode[1]   | 48       | Mode select |
| run       | 4        | Run/start button |
| reset     | 12       | Reset button |
| comm[0]   | 18       | Digit 1 common (enables which digit is active) |
| comm[1]   | 19       | Digit 2 common |
| comm[2]   | 20       | Digit 3 common |
| seg[0]    | 28       | Segment g |
| seg[1]    | 27       | Segment f |
| seg[2]    | 26       | Segment e |
| seg[3]    | 25       | Segment d |
| seg[4]    | 23       | Segment c |
| seg[5]    | 13       | Segment b |
| seg[6]    | 21       | Segment a |

`comm` is active-low (a digit turns on when its line goes low) and `seg` is active-high - make sure your display matches this, or flip the polarity in the code if it doesn't. Put current-limiting resistors (around 220-330 ohm) on each seg line.

## Mode switch

| mode | Behavior |
|------|----------|
| 00   | Count up, 1 per second |
| 01   | Count down, 1 per second |
| 10   | Stopwatch, counts up 1 per 0.1 second |
