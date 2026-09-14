import sys
from PIL import Image

if len(sys.argv) < 2:
    print("Usage: python3 png2bin.py ")
    sys.exit(1)

# Resize any input image automatically to 320x240 grayscale
img = Image.open(sys.argv[1]).convert("L")
img_resized = img.resize((320, 240), Image.Resampling.LANCZOS)

# Save 76,800 raw binary bytes directly to input.bin
with open("input.bin", "wb") as f:
    f.write(img_resized.tobytes())

print("Created input.bin (320x240, 76,800 bytes)")
