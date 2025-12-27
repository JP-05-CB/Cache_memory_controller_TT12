# Cache_memory_controller_TT12_01
# Cache Controller Simulation with Cocotb and GTKWave

A complete simulation environment for a direct-mapped cache controller using Cocotb for Python-based testing and GTKWave for waveform visualization.

## 📋 Project Overview

This project implements and simulates a direct-mapped cache controller with the following specifications:
- **Cache Size**: 16 KB (1024 entries × 16 bytes)
- **Line Size**: 16 bytes (128 bits)
- **Addressing**: 32-bit memory addresses
- **Mapping**: Direct-mapped
- **Write Policy**: Write-through with write-around and write-back for dirty blocks

## 🏗️ Architecture

### Cache Structure
```
CPU Address: [31:14] Tag | [13:4] Index | [3:0] Offset
```
- **Tag Memory**: 1024 entries × 20 bits (Valid + Dirty + 18-bit Tag)
- **Data Memory**: 1024 entries × 128 bits (16 bytes per cache line)

### Finite State Machine States
- **IDLE**: Waiting for CPU requests
- **COMPARE_TAG**: Checking for cache hit/miss
- **ALLOCATE**: Fetching data from main memory
- **WRITE_BACK**: Writing dirty data back to memory

## 📁 Project Structure

```
cache/
├── cache_controller.v      # Main Verilog cache controller
├── vcd_dump.v             # VCD waveform dumping module
├── test_debug.py          # Cocotb testbench for debugging
├── test_cache.py          # Comprehensive test suite
├── Makefile               # Build and simulation configuration
├── tag_memory.mem         # Tag memory initialization
├── data_memory.mem        # Data memory initialization
└── README.md              # This file
```

## ⚙️ Prerequisites

### System Requirements
- Python 3.8+
- Icarus Verilog (iverilog)
- GTKWave for waveform viewing
- Cocotb framework

### Python Environment Setup
```bash
# Create and activate virtual environment
python -m venv py310
source py310/bin/activate

# Install cocotb
pip install cocotb
```

### Verilog Simulator Installation
```bash
# Ubuntu/Debian
sudo apt-get install iverilog gtkwave

# CentOS/RHEL
sudo yum install iverilog gtkwave

# macOS with Homebrew
brew install icarus-verilog gtkwave
```

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/JP-05-CB/Cache_memory_controller_TT12.git
cd cocotb/cache
source py310/bin/activate  # Activate virtual environment
```

### 2. Initialize Memory Files
```bash
# Create clean memory initialization files
python3 -c "
with open('tag_memory.mem', 'w') as f:
    for i in range(1024):
        f.write('00000\\n')
        
with open('data_memory.mem', 'w') as f:
    for i in range(1024):
        f.write('00000000000000000000000000000000\\n')
"
```

### 3. Run Simulation
```bash
# Set environment variable for X value handling
export COCOTB_RESOLVE_X=ZEROS

# Run the simulation
make
```

### 4. View Waveforms
```bash
# Open GTKWave to view simulation waveforms
make wave
```

## 🧪 Test Suite

### Available Tests

1. **Basic Operations Test** (`test_cache_basic_operations`)
   - Read misses and hits
   - Write operations
   - Cache coherence verification

2. **Multiple Accesses Test** (`test_cache_multiple_accesses`)
   - Sequential read patterns
   - Address pattern testing
   - Cache replacement validation

3. **Debug Test** (`test_debug`)
   - Signal monitoring
   - State machine debugging
   - Cache ready signal verification

### Running Specific Tests
```bash
# Run all tests
make

# Run with waveform generation
make WAVES=1

# Run specific test
MODULE=test_debug make
```

## 📊 Waveform Analysis

The simulation generates VCD waveforms that can be analyzed in GTKWave:

### Key Signals to Monitor
- `clk`, `rst_n`: Clock and reset signals
- `cpu_req_addr`, `cpu_req_dataout`: CPU interface
- `mem_req_addr`, `mem_req_datain`: Memory interface
- `cache_ready`: Cache status signal
- `present_state`: FSM state tracking
- `hit`: Cache hit/miss indication

### GTKWave Tips
```bash
# Save signal groups for easier analysis
# 1. Add all signals to waveform view
# 2. Group related signals (CPU, Memory, Cache internals)
# 3. Save as .sav file for future sessions
```

## 🔧 Configuration Options

### Makefile Variables
```makefile
WAVES = 1                  # Enable waveform generation (0/1)
TOPLEVEL = cache_controller # Top-level Verilog module
MODULE = test_cache        # Python test module
```

### Environment Variables
```bash
export COCOTB_RESOLVE_X=ZEROS    # Handle X values as zeros
export COCOTB_ANSI_OUTPUT=1      # Colorized output
```

## 🐛 Debugging Tips

### Common Issues
1. **Cache never becomes ready**: Check reset logic and state machine transitions
2. **X values in signals**: Ensure proper initialization and set `COCOTB_RESOLVE_X=ZEROS`
3. **Memory file issues**: Recreate memory files with the provided Python commands

### Debug Commands
```bash
# Enable verbose compilation
make VERBOSE=1

# Clean and rebuild
make clean
make

# Check syntax without simulation
iverilog -t check cache_controller.v
```

## 📈 Performance Metrics

The simulation provides:
- Cycle-accurate timing information
- Cache hit/miss statistics
- Memory access patterns
- State transition frequencies

## 🎯 Key Features

- **Full Verilog Implementation**: Complete cache controller with FSM
- **Cocotb Integration**: Python-based testbench with modern testing features
- **Waveform Support**: GTKWave-compatible VCD output
- **Memory Initialization**: Clean startup state management
- **Comprehensive Testing**: Multiple test scenarios and edge cases

## 📚 Learning Resources

### Cocotb Documentation
- [Cocotb Official Documentation](https://docs.cocotb.org/)
- [Cocotb GitHub Repository](https://github.com/cocotb/cocotb)

### Verilog Resources
- [Verilog HDL Guide](https://www.chipverify.com/verilog/verilog-tutorial)
- [Icarus Verilog Documentation](http://iverilog.icarus.com/)

### GTKWave Tutorials
- [GTKWave User Guide](http://gtkwave.sourceforge.net/gtkwave.pdf)
- [Waveform Analysis Tips](https://github.com/gtkwave/gtkwave)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the [Debugging Tips](#-debugging-tips) section
2. Review Cocotb and Icarus Verilog documentation
3. Open an issue on the GitHub repository

## 🎓 Academic Use

This project is excellent for:
- Computer Architecture courses
- Cache memory design studies
- Verilog and digital design practice
- Python-based verification learning

---

**Happy simulating!** 🚀
