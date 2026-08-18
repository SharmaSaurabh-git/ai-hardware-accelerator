# AI Hardware Accelerator: Configurable Systolic Array for Matrix Multiplication

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
2. Simulate: `make sim` (requires Verilator or similar)
3. Synthesize: Use Vivado/Quartus with constraints in `constraints/`

## Performance Metrics
- Peak throughput: N² operations/cycle (ideal)
- Utilization: >95% for large matrices
- Latency: 2N + M - 2 cycles for NxN * NxM
- Area: O(N²) processing elements + O(N) buffers

## License
MIT
