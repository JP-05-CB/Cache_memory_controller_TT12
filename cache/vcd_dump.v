// vcd_dump.v - Simple VCD dumping module
`ifdef COCOTB_SIM
module vcd_dump;
    initial begin
        $dumpfile("waveforms.vcd");
        $dumpvars(0, cache_controller);
        $dumpvars(1, cache_controller.tag_mem[0]);
        $dumpvars(1, cache_controller.data_mem[0]);
    end
endmodule
`endif
