module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/cache_controller.fst");
    $dumpvars(0, cache_controller);
end
endmodule
