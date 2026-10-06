#!/usr/bin/env python3
"""Turn the simulation output into an image, and check it against a
pure-Python reference model of the same algorithm.

Usage: python scripts/hex2img.py
Reads build/dims.txt, build/input_gray.png, build/output.txt
Writes build/output.png and build/comparison.png
Exits non-zero if hardware output != reference model.
"""
import sys
import numpy as np
from PIL import Image


def bayer_threshold(w, h):
    """Reference model: same maths as the Verilog, written independently."""
    y, x = np.mgrid[0:h, 0:w]
    a = (x ^ y) & 7
    b = y & 7
    bayer6 = (((a & 1) << 5) | ((b & 1) << 4) |
              (((a >> 1) & 1) << 3) | (((b >> 1) & 1) << 2) |
              (((a >> 2) & 1) << 1) | ((b >> 2) & 1))
    return bayer6 * 4 + 2


def main():
    w, h = map(int, open("build/dims.txt").read().split())
    gray = np.array(Image.open("build/input_gray.png"), dtype=np.int32)
    hw = np.array([int(l) for l in open("build/output.txt")], dtype=np.uint8)

    if hw.size != w * h:
        print(f"FAIL: expected {w*h} pixels, got {hw.size}")
        sys.exit(1)
    hw = hw.reshape(h, w)

    ref = (gray > bayer_threshold(w, h)).astype(np.uint8)
    mismatches = int(np.count_nonzero(hw != ref))
    if mismatches:
        print(f"FAIL: {mismatches} pixels differ from the reference model")
        sys.exit(1)
    print(f"PASS: hardware output matches reference model ({w}x{h}, 0 mismatches)")

    out = Image.fromarray((hw * 255).astype(np.uint8), "L")
    out.save("build/output.png")

    # side-by-side: original | dithered, upscaled so pixels are visible
    scale = max(1, 512 // w)
    left = Image.fromarray(gray.astype(np.uint8), "L").resize((w * scale, h * scale), Image.NEAREST)
    right = out.resize((w * scale, h * scale), Image.NEAREST)
    combo = Image.new("L", (w * scale * 2 + 8, h * scale), 128)
    combo.paste(left, (0, 0))
    combo.paste(right, (w * scale + 8, 0))
    combo.save("build/comparison.png")
    print("wrote build/output.png and build/comparison.png")


if __name__ == "__main__":
    main()
