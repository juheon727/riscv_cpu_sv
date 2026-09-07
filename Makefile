.PHONY: build run

build:
	mkdir -p out
	iverilog -g2012 -o out/sim.out pipeline/*.sv testbench/core_tb.sv

run: build
	out/sim.out