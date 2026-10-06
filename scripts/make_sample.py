#!/usr/bin/env python3
"""Generate a sample grayscale test image (soft shapes + gradient) so the
project runs out of the box. Replace with any photo you like."""
import numpy as np
from PIL import Image

W = H = 256
y, x = np.mgrid[0:H, 0:W].astype(np.float32)
img = x / W * 0.6 + 0.1                                    # horizontal ramp
cx, cy = W * 0.5, H * 0.5
r = np.hypot(x - cx, y - cy)
img = np.where(r < 70, 1.0 - r / 90.0, img)                # bright soft disc
img += 0.25 * np.clip(1 - np.abs((x + y) - W) / 18, 0, 1)  # diagonal stripe
img = np.clip(img, 0, 1)
Image.fromarray((img * 255).astype(np.uint8), "L").save("sample/sample.png")
print("wrote sample/sample.png")
