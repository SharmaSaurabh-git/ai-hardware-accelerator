# Systolic Array Architecture

## Overview
This systolic array implements matrix multiplication C = A * B using an N x N grid of Processing Elements (PEs). Data flows in a pipelined fashion:
- Matrix A elements flow west-to-east through each row
- Matrix B elements flow north-to-south through each column
- Each PE computes: accum += A * B
- Results emerge from the south edge after pipelining latency

## Dataflow Timing
For N x N array multiplying N x N matrices:
- Latency: 2N - 2 cycles to fill pipeline + N cycles to drain = 3N - 2 cycles
- Throughput: 1 result per cycle after initial latency
- Utilization: Approaches 100% for large matrices

## PE Functionality
Each Processing Element:
1. Receives A from west, B from north
2. Multiplies A * B (signed)
3. Adds to accumulator (from west PE or zero for first column)
4. Sends A east, B south
5. Sends accumulated result south (for output)

## Resource Utilization
- PEs: N²
- FIFOs: O(N) for input buffering (basic version shown)
- Control logic: Minimal (mainly handshake signals)

## Performance Metrics
| Metric          | Value                     |
|-----------------|---------------------------|
| Peak Throughput | N² operations/cycle       |
| Latency         | 3N - 2 cycles (NxN input) |
| Area Complexity | O(N²)                     |
| Power           | Dynamic, data-dependent   |

## Extension Ideas
1. Add support for different data types (float, bfloat16)
2. Implement sparse matrix skipping
3. Add accumulation precision scaling
4. Integrate with on-chip memory hierarchy
5. Add systolic array for convolution (im2col transformation)
6. Implement AXI-Lite slave interface
7. Add performance counters and profiling
