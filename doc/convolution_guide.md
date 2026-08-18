# Convolution Guide for Systolic Array

## Overview
This guide explains how to use the systolic array for 2D convolution via the im2col transformation.

## Convolution as Matrix Multiplication
A 2D convolution can be rewritten as a matrix multiplication using the im2col technique:

Given:
- Input feature map: X of shape (H, W, C_in)
- Kernel: K of shape (K_h, K_w, C_in, C_out)
- Output: Y of shape (H_out, W_out, C_out) where:
   H_out = (H - K_h + 2*padding_h) / stride_h + 1
   W_out = (W - K_w + 2*padding_w) / stride_w + 1

The im2col transformation:
1. Extracts all K_h x K_w patches from X (with padding and stride)
2. Flattens each patch into a column vector of length (K_h * K_w * C_in)
3. Forms a matrix X_col of shape ( (H_out * W_out) , (K_h * K_w * C_in) )
4. Reshapes the kernel K into a matrix K_col of shape (C_out, (K_h * K_w * C_in))
   (each row is a flattened kernel for one output channel)

Then the convolution is:
   Y_col = X_col * K_col^T
   where Y_col has shape (H_out * W_out, C_out)
   and is reshaped to (H_out, W_out, C_out)

## Using the Systolic Array for Convolution
To compute Y_col = X_col * K_col^T with our systolic array:

### Option 1: Direct Use (if matrices fit)
If the dimensions of X_col and K_col^T are small enough to fit in the systolic array:
   - Set the systolic array dimensions to at least:
        rows >= H_out * W_out
        cols >= K_h * K_w * C_in   (for X_col)
        and we need to compute: X_col * K_col^T
   - But note: K_col^T has shape (K_h*K_w*C_in, C_out)
   - So we need:
        systolic_array_rows >= H_out * W_out
        systolic_array_cols >= K_h * K_w * C_in   (to hold X_col rows)
        and we will stream K_col^T as the B matrix (which has rows of length C_out)

   Actually, the systolic array computes: C = A * B
   where A is streamed row-by-row (west to east) and B is streamed column-by-column (north to south).

   To compute Y_col = X_col * K_col^T:
     - Let A = X_col (shape: [H_out*W_out, K*K*C_in])
     - Let B = K_col^T (shape: [K*K*C_in, C_out])
     - Then C = A * B has shape: [H_out*W_out, C_out]

   So we need:
     - Systolic array rows >= H_out * W_out
     - Systolic array cols >= K*K*C_in   (to hold one row of A and one column of B at a time? Actually, the array processes multiple rows and columns in parallel.)

   Actually, the systolic array of size N x N can compute a tile of the output matrix:
     - It computes N x N elements of the output matrix at a time.
     - We need to tile the output matrix.

### Option 2: Tiling for Large Matrices
For large matrices, we break the multiplication into tiles:

   C_tile = A_tile * B_tile

   where:
     - A_tile is a tile of A (size: N_A x K)
     - B_tile is a tile of B (size: K x N_B)
     - C_tile is a tile of C (size: N_A x N_B)

   We iterate over tiles of A and B to accumulate the full result.

### Hardware Implementation Options
1. **Software im2col + Hardware Matrix Mult**:
   - Perform im2col transformation in software (or on a CPU/DSP)
   - Stream the resulting X_col and K_col matrices to the systolic array
   - This offloads the memory-intensive im2col step to software but keeps the compute-intensive matrix multiplication in hardware.

2. **Hardware im2col + Hardware Matrix Mult**:
   - Implement the im2col transformation in hardware (using line buffers and windowing)
   - Stream the resulting patches directly to the systolic array
   - This provides full hardware acceleration but is more complex.

## Example: 3x3 Convolution on 5x5 Input (1 channel, 1 output)
Given:
- Input: 5x5x1 (H=5, W=5, C_in=1)
- Kernel: 3x3x1x1 (K_h=3, K_w=3, C_in=1, C_out=1)
- Stride: 1, Padding: 0
- Output: 3x3x1 (H_out=3, W_out=3, C_out=1)

Steps:
1. im2col transformation:
   - Extract 9 patches (3x3 grid of patches, each 3x3x1)
   - Flatten each patch to a vector of length 9 (3*3*1)
   - Form X_col: 9x9 matrix (each column is a patch)
   - Reshape kernel: 1x9 matrix (the single kernel flattened)
   - Actually, K_col is 1x9, so K_col^T is 9x1
   - Then Y_col = X_col (9x9) * K_col^T (9x1) = 9x1 matrix
   - Reshape to 3x3x1 output

2. Using the systolic array:
   - We need to compute: 9x9 matrix * 9x1 matrix = 9x1 matrix
   - We can use a systolic array of size 9x9 to do it in one shot, or we can tile.

   Example with 2x2 systolic array:
     - Break the 9x9 A matrix into tiles of 2x2 (we need 5x5 tiles of 2x2, with overlap? Actually, we break into tiles of 2 rows and 2 columns)
     - Break the 9x1 B matrix into tiles of 2x1 (we need 5 tiles of 2x1 and 1 tile of 1x1)
     - For each tile of A (2x2) and tile of B (2x1), we compute a tile of C (2x1)
     - Then we assemble the output tiles.

   This is complex to manage but demonstrates the principle.

## Using Our Testbench for Reference
See `tb/tb_systolic_array.sv` for a simple matrix multiplication testbench.
To adapt it for convolution:
1. Generate your input feature map and kernel.
2. Perform im2col transformation (in software or using a simple hardware module).
3. Feed the resulting matrices to the systolic array as A and B.
4. Collect the result and reshape it to the output feature map.

See `doc/convolution_example.md` for a step-by-step example.

## Practical Tips
1. Choose your systolic array size based on the largest dimension you expect to handle in one tile.
2. For large convolutions, use tiling and accumulate results in an external buffer.
3. Consider data reuse: the same kernel row is used for multiple input patches, so streaming the kernel once and reusing it can save bandwidth.
4. Explore different data layouts (NCHW vs NHWC) to optimize memory access.
5. For deep learning, consider quantizing to fixed-point to reduce bandwidth and increase throughput.
