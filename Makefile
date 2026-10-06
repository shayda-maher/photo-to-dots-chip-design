IMAGE ?= sample/sample.png
WIDTH ?= 128

.PHONY: all run view clean

all: run

build/input.hex: $(IMAGE) scripts/img2hex.py
	python3 scripts/img2hex.py $(IMAGE) --width $(WIDTH)

build/sim.vvp: rtl/bayer_dither.v tb/tb_bayer_dither.v build/input.hex
	@W=$$(cut -d" " -f1 build/dims.txt); H=$$(cut -d" " -f2 build/dims.txt); \
	iverilog -g2012 -o build/sim.vvp \
	  -Ptb_bayer_dither.W=$$W -Ptb_bayer_dither.H=$$H \
	  rtl/bayer_dither.v tb/tb_bayer_dither.v

run: build/sim.vvp
	vvp build/sim.vvp
	python3 scripts/hex2img.py

view:
	gtkwave build/dither.vcd

clean:
	rm -rf build/*
