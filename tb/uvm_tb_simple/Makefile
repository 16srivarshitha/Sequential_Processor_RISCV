RTL = ../../rtl
TB = riscv_uvm_simple_tb.v

# all rtl files needed
SOURCES = $(RTL)/instruction_fetch.v \
          $(RTL)/decode.v \
          $(RTL)/execute.v \
          $(RTL)/memory.v \
          $(RTL)/writeback.v \
          $(RTL)/single_cycle_processor.v

OUT = sim.vvp
WAVE = dump.vcd

all: run

# compile everything
compile:
	@echo "Compiling testbench..."
	iverilog -g2012 -o $(OUT) $(TB) $(SOURCES)
	@echo "Done!"

# run simulation
run: compile
	@echo "Running tests..."
	vvp $(OUT) | tee test.log
	@# check if any failures
	@if grep -q "FAIL" test.log; then \
		echo "Some tests failed!"; \
		exit 1; \
	else \
		echo "All tests passed!"; \
	fi

# open waveform
wave:
	gtkwave $(WAVE) &

# cleanup
clean:
	rm -f $(OUT) $(WAVE) test.log

.PHONY: all compile run wave clean