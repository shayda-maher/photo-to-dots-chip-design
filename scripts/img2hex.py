#!/usr/bin/env python3
"""Convert an image to 8-bit grayscale hex for the Verilog testbench.

Usage: python scripts/img2hex.py INPUT_IMAGE [--width 128]
Writes build/input.hex, build/input_gray.png and build/dims.txt ("W H").
"""
import argparse
import os
from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("image")
    p.add_argument("--width", type=int, default=128,
                   help="resize to this width, keeping aspect ratio (default 128)")
    args = p.parse_args()

    img = Image.open(args.image).convert("L")
    h = max(1, round(img.height * args.width / img.width))
    img = img.resize((args.width, h), Image.LANCZOS)

    os.makedirs("build", exist_ok=True)
    with open("build/input.hex", "w") as f:
        for v in img.tobytes():
            f.write(f"{v:02x}\n")
    with open("build/dims.txt", "w") as f:
        f.write(f"{img.width} {img.height}\n")
    img.save("build/input_gray.png")
    print(f"wrote build/input.hex ({img.width}x{img.height})")


if __name__ == "__main__":
    main()
