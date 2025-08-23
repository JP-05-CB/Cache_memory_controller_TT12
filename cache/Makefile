# Makefile
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = cache.v vcd_dump.v
TOPLEVEL = cache_controller
MODULE = test_cache


include $(shell cocotb-config --makefiles)/Makefile.sim

# Enable VCD dumping
COMPILE_ARGS += -DCOCOTB_SIM=1

wave:
	if [ -f waveforms.vcd ]; then gtkwave waveforms.vcd & fi
