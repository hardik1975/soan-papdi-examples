from machine import Pin, SPI, mem32
import time

# --- Pin Mapping ---
PCLK_PIN  = 28
DATA_PINS = [27, 26, 25, 23, 24, 22, 20, 19] # p_in[0] to p_in[7]
POUT_PIN  = 18                                # p_out

# ST7789 Display (SPI1)
LCD_SCK, LCD_MOSI = 10, 11
LCD_CS, LCD_DC, LCD_RST, LCD_BL = 9, 8, 16, 17

IMG_WIDTH, IMG_HEIGHT = 320, 240
TOTAL_PIXELS   = 76800
OUTPUT_SIZE    = 9600   # 76,800 bits / 8
PIPELINE_DELAY = 12

# Direct Hardware Register Addresses
SIO_BASE     = 0xd0000000
GPIO_IN      = SIO_BASE + 0x004
GPIO_OUT_SET = SIO_BASE + 0x014
GPIO_OUT_CLR = SIO_BASE + 0x018

PCLK_MASK = 1 << PCLK_PIN
POUT_MASK = 1 << POUT_PIN

pclk = Pin(PCLK_PIN, Pin.OUT, value=0)
p_outs = [Pin(p, Pin.OUT, value=0) for p in DATA_PINS]
p_in_bit = Pin(POUT_PIN, Pin.IN)
bl = Pin(LCD_BL, Pin.OUT, value=1)

DATA_BUS_MASK = sum(1 << p for p in DATA_PINS)
GPIO_LUT = [sum((1 << DATA_PINS[b]) for b in range(8) if (val >> b) & 1) for val in range(256)]


# Embedded Driver
class ST7789:
    def __init__(self, spi, dc, cs, rst):
        self.spi = spi
        self.dc = Pin(dc, Pin.OUT, value=0)
        self.cs = Pin(cs, Pin.OUT, value=1)
        self.rst = Pin(rst, Pin.OUT, value=1)
        self.init_display()

    def write_cmd(self, cmd):
        self.dc.value(0); self.cs.value(0)
        self.spi.write(bytearray([cmd]))
        self.cs.value(1)

    def write_data(self, data):
        self.dc.value(1); self.cs.value(0)
        self.spi.write(data)
        self.cs.value(1)

    def init_display(self):
        self.rst.value(0); time.sleep_ms(50); self.rst.value(1); time.sleep_ms(50)
        self.write_cmd(0x01); time.sleep_ms(100) # SWRESET
        self.write_cmd(0x11); time.sleep_ms(100) # SLPOUT
        self.write_cmd(0x3A); self.write_data(b'\x55') # RGB565
        self.write_cmd(0x36); self.write_data(b'\x70') # Landscape
        self.write_cmd(0x29) # DISPON

    def set_window(self, x0, y0, x1, y1):
        self.write_cmd(0x2A); self.write_data(bytearray([x0 >> 8, x0 & 0xFF, x1 >> 8, x1 & 0xFF]))
        self.write_cmd(0x2B); self.write_data(bytearray([y0 >> 8, y0 & 0xFF, y1 >> 8, y1 & 0xFF]))
        self.write_cmd(0x2C)


# Native Engine (Assembly Speed Execution) 
@micropython.native
def run_single_pass(in_bytes, output_packed, lcd_line_buf, lcd):
    lcd.set_window(0, 0, IMG_WIDTH - 1, IMG_HEIGHT - 1)
    
    out_byte = 0
    bit_count = 0
    out_index = 0
    pixel_counter = 0

    sio_clr = GPIO_OUT_CLR
    sio_set = GPIO_OUT_SET
    sio_in  = GPIO_IN
    pclk_m  = PCLK_MASK
    pout_m  = POUT_MASK
    bus_m   = DATA_BUS_MASK
    lut     = GPIO_LUT

    for pixel in in_bytes:
        # Drive data bus & toggle clock in 3 raw assembly register cycles
        mem32[sio_clr] = bus_m
        mem32[sio_set] = lut[pixel]
        mem32[sio_set] = pclk_m
        mem32[sio_clr] = pclk_m

        # Read output pin
        edge_bit = 1 if (mem32[sio_in] & pout_m) else 0

        # Capture & stream 
        if pixel_counter >= PIPELINE_DELAY and out_index < 9600:
            out_byte = (out_byte >> 1) | (edge_bit << 7)
            bit_count += 1

            if bit_count == 8:
                output_packed[out_index] = out_byte
                
                col_base = (out_index % 40) * 16
                for b in range(8):
                    c = 0xFF if ((out_byte >> b) & 1) else 0x00
                    lcd_line_buf[col_base + (b * 2)]     = c
                    lcd_line_buf[col_base + (b * 2) + 1] = c

                out_index += 1
                bit_count = 0
                out_byte = 0

                # Flush line to display when row ends
                if out_index % 40 == 0:
                    lcd.write_data(lcd_line_buf)

        pixel_counter += 1

    # Flush final 12 delay cycles
    while out_index < 9600:
        mem32[sio_set] = pclk_m
        mem32[sio_clr] = pclk_m
        edge_bit = 1 if (mem32[sio_in] & pout_m) else 0

        if pixel_counter >= PIPELINE_DELAY and out_index < 9600:
            out_byte = (out_byte >> 1) | (edge_bit << 7)
            bit_count += 1

            if bit_count == 8:
                output_packed[out_index] = out_byte
                
                col_base = (out_index % 40) * 16
                for b in range(8):
                    c = 0xFF if ((out_byte >> b) & 1) else 0x00
                    lcd_line_buf[col_base + (b * 2)]     = c
                    lcd_line_buf[col_base + (b * 2) + 1] = c

                out_index += 1
                bit_count = 0
                out_byte = 0

                if out_index % 40 == 0:
                    lcd.write_data(lcd_line_buf)

        pixel_counter += 1


# Execution Controller
def main():
    spi = SPI(1, baudrate=60_000_000, sck=Pin(LCD_SCK), mosi=Pin(LCD_MOSI))
    lcd = ST7789(spi, dc=LCD_DC, cs=LCD_CS, rst=LCD_RST)

    print("1. Reading input.bin into RAM...")
    try:
        with open("input.bin", "rb") as f:
            in_bytes = f.read()
    except OSError:
        print("Error: input.bin not found on RP2040 flash!")
        return

    output_packed = bytearray(OUTPUT_SIZE)
    lcd_line_buf = bytearray(IMG_WIDTH * 2)

    print("2. Processing frame through FPGA & rendering to screen...")
    t0 = time.ticks_ms()
    run_single_pass(in_bytes, output_packed, lcd_line_buf, lcd)
    t1 = time.ticks_ms()

    print(f"Done in {time.ticks_diff(t1, t0)} ms!")

    print("3. Saving output_edge.bin...")
    with open("output_edge.bin", "wb") as f:
        f.write(output_packed)

    print("Finished! Screen updated and output_edge.bin created.")

main()
