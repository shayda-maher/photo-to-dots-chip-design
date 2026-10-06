# \# Photo-to-Dots Chip Design

# A small computer chip design, written in Verilog and tested in simulation,

# that turns a grayscale photo into black-and-white dots. Dark areas get

# few white dots and bright areas get many, the same trick old newspapers

# used to print photos with only black ink.

# Verilog Ordered-Dither Pipeline

A streaming hardware module that converts 8-bit grayscale pixels to 1-bit
black/white using an **8x8 Bayer ordered dither**, written in Verilog and
verified in simulation against an independent Python reference model.

!\[before and after](docs/comparison.png)

*Left: grayscale input. Right: 1-bit output produced by the simulated hardware.*

## What it does

* Accepts **one pixel per clock** in raster order and produces **one output bit per clock**.
* **2-stage pipeline** (2-cycle latency): threshold lookup, then compare.
* **No ROM needed.** The Bayer threshold is computed from the pixel's (x, y) position
by XOR-ing and interleaving coordinate bits.

## How it works

Ordered dithering compares each pixel to a threshold that depends on where the pixel
sits in a repeating 8x8 grid. Dark areas get few white dots, bright areas get many,
so the eye reads the dot density as shading.

```
x, y counters --> a = x ^ y, b = y --> bayer6 = {a0,b0,a1,b1,a2,b2}
                                          |
                                  thresh = {bayer6, 2'b10}   (2..254)
                                          |
pixel ----------------------------> out\_bit = pixel > thresh
```

Thresholds run from 2 to 254, so pure black never turns white and pure white always does.

## Run it

Requirements: [Icarus Verilog](https://steveicarus.github.io/iverilog/), Python 3 with `numpy` and `pillow`.
GTKWave is optional, for viewing waveforms.

```bash
python3 scripts/make\_sample.py      # generates sample/sample.png
make                                # convert -> simulate -> verify -> images
make IMAGE=my\_photo.jpg WIDTH=160   # use your own image
make view                           # open waveforms in GTKWave
```

A successful run prints:

```
PASS: streamed 16384 pixels, captured 16384 outputs
PASS: hardware output matches reference model (128x128, 0 mismatches)
```

## Verification

`scripts/hex2img.py` recomputes the dither in NumPy using separately written logic and
compares every pixel with the simulated hardware output. The run fails on any mismatch.
GitHub Actions runs the same flow on every push.

## Layout

|Path|Purpose|
|-|-|
|`rtl/bayer\_dither.v`|The dither module|
|`tb/tb\_bayer\_dither.v`|Testbench: streams an image in, captures bits out|
|`scripts/img2hex.py`|Image -> grayscale hex file|
|`scripts/hex2img.py`|Output bits -> PNG, plus reference-model check|
|`Makefile`|One-command build, simulate, verify|

## Ideas for extending it

* Add a 4x4 / 16x16 matrix option via a parameter.
* Replace the ordered dither with Floyd-Steinberg (needs line buffers, a good next step).
* Add backpressure with a `ready` signal.
* Synthesize with Yosys and report area and timing.

