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
	
fetch-test: $(wildcard fetch*)
	@$(CC) -o $(output_dir)/fetch.vvp fetch_tb.v
	vvp $(output_dir)/fetch.vvp
	@gtkwave fetch.gtkw

decode-test: $(wildcard decode*)
	@$(CC) -o $(output_dir)/decode.vvp decode_tb.v
	vvp $(output_dir)/decode.vvp

execute-test: $(wildcard execute*)
	@$(CC) -o $(output_dir)/pipe-test.vvp pipe_tb.v
	vvp $(output_dir)/pipe-test.vvp
	@gtkwave wave.vcd

memory-test: $(wildcard memory*)
	@$(CC) -o $(output_dir)/memory.vvp memory_tb.v
	vvp $(output_dir)/memory.vvp $(vvp_flags)
	
write-test: decode.v $(wildcard write*)
	@$(CC) -o $(output_dir)/write.vvp write_tb.v
	vvp $(output_dir)/write.vvp $(vvp_flags)
	@gtkwave wave.vcd &

.PHONY : clean
clean :
	-rm -r $(output_dir)
	-rm -r $(vcd_dir)
	-rm *.vcd
