# AI Hardware Accelerator: Configurable Systolic Array for Matrix Multiplication

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![HDL: SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![Simulator: Verilator](https://img.shields.io/badge/Simulator-Verilator-green.svg)](https://verilator.org/)
[![GitHub Stars](https://img.shields.io/github/stars/SharmaSaurabh-git/ai-hardware-accelerator?style=social)](https://github.com/SharmaSaurabh-git/ai-hardware-accelerator/stargazers)

A parameterizable systolic array implementation for high-throughput matrix multiplication, optimized for AI/ML workloads (CNNs, Transformers). This project demonstrates VLSI design skills targeting the fastest-growing segment in semiconductor industry: AI accelerators.

## Features
- Parameterizable N x N systolic array
- Support for configurable data widths (8/16/32-bit)
- Pipelined dataflow with maximum throughput
- Synchronous FIFO-based input/output buffers
- Verilog/SystemVerilog implementation
- Comprehensive testbench with random stimulus
- Performance analysis scripts
- FPGA implementation constraints (optional)
- SVA-based assertions for verification
- **Fixed-point support** (via input/output scaling)
- **Convolution capabilities** (via im2col transformation - see documentation)

## Target Applications
- Convolutional Neural Networks (CNNs)
- Transformer models (self-attention layers)
- General matrix multiplication (GEMM)
- Edge AI accelerators

## Why This Matters
The AI chip market is projected to exceed $200B by 2030. Systolic arrays are the core computational unit in Google's TPU, NVIDIA's Tensor Cores, and numerous AI startups. Mastering this architecture demonstrates skills directly applicable to top-tier semiconductor and hardware companies.

## Repository Structure
```
ai-hardware-accelerator/
├── rtl/                 # Register Transfer Level (Verilog/SystemVerilog)
│   ├── systolic_array.sv
│   ├── pe.sv            # Processing Element
│   ├── fifo_sync.sv
│   └── ...
├── tb/                  # Testbenches
│   ├── tb_systolic_array.sv
│   └── ...
├── scripts/             # Simulation and analysis scripts
├── doc/                 # Documentation
├── constraints/         # FPGA constraints (Xilinx/Intel)
└── README.md
```

## Getting Started
1. Clone repository: `git clone https://github.com/SharmaSaurabh-git/ai-hardware-accelerator.git`
2. Install Verilator: `sudo apt-get install verilator` (or use your preferred simulator)
3. Simulate: `make sim`
4. View waveform: `gtkwave systolic_array.vcd`

## Performance Metrics
- Peak throughput: N² operations/cycle (ideal)
- Utilization: >95% for large matrices
- Latency: 2N + M - 2 cycles for NxN * NxM
- Area: O(N²) processing elements + O(N) buffers

## Fixed-Point Support
The systolic array uses integer arithmetic, but can be used for fixed-point numbers by appropriate scaling:
1. Represent your fixed-point numbers as integers by scaling: `integer_value = round(float_value * (2^frac_bits))`
2. Choose your integer and fractional bits such that the maximum expected value does not overflow.
3. After multiplication, the result will be scaled by 2^(2*frac_bits). You will need to right-shift by 2*frac_bits to get the correct fixed-point result.
4. For accumulation of N products, you may need to right-shift by an additional log2(N) bits to avoid overflow, or use a wider accumulator.

Example for Q4.4 format (4 integer, 4 fractional bits, total 8 bits):
   - Input range: [-8, 7.9375] (if signed)
   - Multiply two Q4.4 numbers: result is Q8.8 (16 bits)
   - Accumulate N products: you need extra log2(N) bits in the integer part to avoid overflow.
   - After accumulation, right-shift by (2*frac_bits + log2(N)) to get back to Q4.4.

See `doc/fixed_point_guide.md` for detailed examples.

## Convolution Capabilities
2D convolution can be performed using the systolic array by:
1. Convolution via im2col: Convert the 2D convolution into a matrix multiplication problem.
2. The im2col transformation rearranges the input feature map into columns where each column is a flattened patch.
3. The kernel is rearranged into rows where each row is a flattened kernel.
4. Then, convolution becomes: output = im2col_matrix * kernel_matrix^T
5. This matrix multiplication can be computed using our systolic array.

See `doc/convolution_guide.md` for detailed examples and hardware considerations.

## Example Usage
See `tb/tb_systolic_array.sv` for a complete testbench demonstrating:
- Matrix multiplication verification
- Clock and reset sequencing
- Input/output timing
- Result validation

## Future Enhancements
- Fixed-point hardware support (to avoid external scaling)
- Sparsity optimization for efficient computation
- Integration with on-chip memory hierarchy
- AXI-Lite interface for SoC integration
- DSP block utilization reporting for FPGA targets
- Direct hardware support for im2col transformation

## License
MIT
