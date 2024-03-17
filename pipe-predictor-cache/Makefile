SHELL := /bin/bash

CC = iverilog
sources := $(wildcard *.v)
targets = $(wildcard $(output_dir)/*.vvp)
testbench := $(wildcard *_tb.v)

vvp_flags := 
output_dir = ./target
vcd_dir = ./wave

$(shell mkdir -p $(output_dir))
$(shell mkdir -p $(vcd_dir))

pipe-test: $(sources)
	@$(CC) -o $(output_dir)/pipe-cpu.vvp pipe-cpu.v
	vvp $(output_dir)/pipe-cpu.vvp
	@gtkwave pipe.gtkw

auto-test: $(sources)
	@$(CC) -o $(output_dir)/cpu.vvp pipe-cpu.v
	vvp $(output_dir)/cpu.vvp
	rm  $(output_dir)/cpu.vvp

.PHONY : clean
clean :
	-rm -r $(output_dir)
	-rm -r $(vcd_dir)
	-rm *.vcd
