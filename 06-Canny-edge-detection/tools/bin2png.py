import sys
from PIL import Image

input_file = sys.argv[1] if len(sys.argv) > 1 else "output.bin"
output_file = sys.argv[2] if len(sys.argv) > 2 else "output.png"

WIDTH, HEIGHT = 320, 240
EXPECTED_BYTES = (WIDTH * HEIGHT) // 8  # 9,600 bytes

with open(input_file, "rb") as f:
    packed_data = f.read()

# Unpack 1-bit binary output into grayscale pixels (0 = Black, 255 = White)
unpacked_pixels = bytearray()
for byte in packed_data[:EXPECTED_BYTES]:
    for bit_idx in range(8):
        pixel_val = 255 if ((byte >> bit_idx) & 1) else 0
        unpacked_pixels.append(pixel_val)

img = Image.frombytes("L", (WIDTH, HEIGHT), bytes(unpacked_pixels))
img.save(output_file)
print(f"Saved reconstructed edge map to {output_file} ({WIDTH}x{HEIGHT})")
