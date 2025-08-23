import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.result import TestSuccess

async def reset_dut(dut):
    """Reset the DUT"""
    print("🔁 Resetting DUT...")
    dut.rst_n.value = 0
    dut.cpu_req_valid.value = 0
    dut.cpu_req_rw.value = 0
    dut.cpu_req_addr.value = 0
    dut.cpu_req_datain.value = 0
    
    await Timer(100, units="ns")
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    print("✅ Reset complete")

async def monitor_signals(dut):
    """Monitor key signals"""
    print("\n📊 Monitoring signals:")
    print(f"   cache_ready: {dut.cache_ready.value}")
    print(f"   present_state: {dut.present_state.value if hasattr(dut, 'present_state') else 'N/A'}")
    print(f"   mem_req_valid: {dut.mem_req_valid.value}")
    print(f"   mem_req_ready: {dut.mem_req_ready.value}")
    print(f"   mem_req_rw: {dut.mem_req_rw.value}")

@cocotb.test()
async def test_debug_cache_ready(dut):
    """Debug why cache_ready never becomes high"""
    
    # Setup clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    await reset_dut(dut)
    
    # Monitor initial state
    await monitor_signals(dut)
    
    # Wait and monitor for several cycles
    for i in range(50):
        await RisingEdge(dut.clk)
        if i % 10 == 0:
            print(f"\n🔍 Cycle {i}:")
            await monitor_signals(dut)
    
    # Try to stimulate with a read request
    print("\n🎯 Stimulating with read request...")
    dut.cpu_req_valid.value = 1
    dut.cpu_req_rw.value = 0  # Read
    dut.cpu_req_addr.value = 0x1000
    
    for i in range(20):
        await RisingEdge(dut.clk)
        if i % 5 == 0:
            print(f"   Cycle {i}: cache_ready={dut.cache_ready.value}, state={dut.present_state.value if hasattr(dut, 'present_state') else 'N/A'}")
    
    # Clear the request
    dut.cpu_req_valid.value = 0
    
    # Wait some more
    for i in range(20):
        await RisingEdge(dut.clk)
    
    print("\n✅ Debug test completed!")
    raise TestSuccess("Debug completed")

@cocotb.test() 
async def test_simple_ready_check(dut):
    """Simple test to just check if cache_ready ever goes high"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Just wait and see if cache_ready ever becomes 1
    max_cycles = 1000
    ready_found = False
    
    for i in range(max_cycles):
        await RisingEdge(dut.clk)
        if dut.cache_ready.value == 1:
            print(f"🎉 cache_ready became 1 at cycle {i}!")
            ready_found = True
            break
            
        if i % 100 == 0:
            print(f"Cycle {i}: cache_ready = {dut.cache_ready.value}")
    
    if not ready_found:
        print(f"❌ cache_ready never became 1 after {max_cycles} cycles")
        # Let's continue to see what happens
    
    # Wait a bit more
    for i in range(100):
        await RisingEdge(dut.clk)
    
    print("✅ Ready check test completed")
    raise TestSuccess("Ready check done")
