## Key Design Decisions

- **Fully pipelined**  
  No frame buffer inside the FPGA. Every stage processes a pixel as soon as it arrives and passes the result to the next stage. This keeps memory usage very low and makes the design scale easily with resolution.

- **320×240 resolution**  
  Chosen because it matches the native resolution of the ST7789 display and fits comfortably in the RP2040’s RAM (both input grayscale + output edge map).

- **Parallel bus instead of SPI**  
  The pipeline can accept one pixel every clock. SPI (even at high speed) could not keep up. A simple 8-bit parallel + clock + 1-bit result bus was both faster and easier to implement.

- **Exact direction calculation**  
  Early versions used bit-shift approximations for the 22.5° / 67.5° thresholds. This produced thick edges. Switching to two DSP multipliers for proper fixed-point multiplies fixed it and gave single-pixel-wide edges.

- **Border padding in line buffers**  
  The first version waited for full rows before producing output, creating a huge and hard-to-predict latency (~4000 cycles). Changing the line buffers to replicate border pixels reduced latency to a small, fixed number of cycles.

## Pipeline Latency

Because of the line buffers (especially in `imageControl`), there is a fixed delay before the first valid edge bit appears.  
After the padding fix, this latency became predictable and easy to handle on the RP2040 side.

## Resource Usage Highlights

- Only **2 DSP blocks** used (for the accurate direction thresholds)
- Line buffers live entirely in Block RAM
- ~30% LUT utilization → plenty of room left for future improvements (camera interface, etc.)

## Known Limitations / Future Work

- Currently uses a static test image (`input.bin`)
- No live camera input yet
- Hysteresis is a simplified version (works well for this resolution)

