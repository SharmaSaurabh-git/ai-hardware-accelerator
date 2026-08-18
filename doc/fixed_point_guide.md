# Fixed-Point Guide for Systolic Array

## Overview
This guide explains how to use the systolic array for fixed-point arithmetic.

## Fixed-Point Representation
We use the Qm.n format where:
- m = number of integer bits (including sign bit)
- n = number of fractional bits
- Total width = m + n

Example: Q4.4 format uses 4 integer bits and 4 fractional bits (total 8 bits).
   - Range: [-2^(m-1), 2^(m-1) - 2^(-n)] = [-8, 7.9375] for signed 8-bit.

## Using the Systolic Array for Fixed-Point
The systolic array performs integer multiplication and addition. To use it for fixed-point:

### Step 1: Scale Inputs to Integers
Convert your fixed-point values to integers by multiplying by 2^n and rounding:
   int_value = round(float_value * (2^n))

### Step 2: Perform Matrix Multiplication
Use the systolic array to compute: C_int = A_int * B_int
   - A_int and B_int are the scaled integer matrices.
   - The result C_int is scaled by 2^(2n).

### Step 3: Descale the Result
Convert the integer result back to fixed-point by dividing by 2^(2n):
   C_float = C_int / (2^(2n))

### Step 4: Handle Accumulation Overflow (Critical!)
When accumulating N products in the systolic array, the result can overflow if not enough bits are provided in the accumulator.

The systolic array has an accumulator width of:
   ACC_WIDTH = 2 * INPUT_WIDTH + $clog2(N)

This provides enough bits to hold the sum of N products without overflow for unsigned numbers.
For signed numbers, we have one less bit for the integer part due to sign extension.

To avoid overflow in the fixed-point result after accumulation, you may need to right-shift the accumulator by an additional log2(N) bits to get the correct scaled result.

### Final Descaling Formula
For Qm.n inputs, after multiplying and accumulating N products:
   C_int = sum_{k=1}^{N} (A_int_k * B_int_k)
   C_float = C_int / (2^(2n + log2(N)))

Example: Q4.4 inputs (n=4), N=16 products to accumulate
   - After multiplication: each product is Q8.8 (16 bits)
   - After accumulating 16 products: we need 4 extra integer bits (log2(16)=4) to avoid overflow
   - So we right-shift by (2*4 + 4) = 12 bits to get back to Q4.4

## Example: 4x4 Systolic Array for Q4.4 Matrix Multiplication
1. Set INPUT_WIDTH = 8 (for Q4.4)
2. Scale your Q4.4 matrices to integers by multiplying by 16 (2^4)
3. Run the systolic array to get integer result matrix
4. Right-shift each result by 12 bits (2*4 + log2(16)=8+4=12) to get back to Q4.4
5. The result is now in Q4.4 format

## Overflow Prevention
To prevent overflow:
- Ensure that the maximum possible value of the accumulated result fits in the accumulator.
- Maximum product value: (2^(m+n-1) - 2^(-n))^2 ≈ 2^(2m+2n-2) for large m,n
- Maximum accumulated value: N * 2^(2m+2n-2)
- Required accumulator bits: log2(N * 2^(2m+2n-2)) = log2(N) + 2m + 2n - 2
- Our accumulator width: 2*(m+n) + log2(N) = 2m+2n+log2(N)
- We have: (2m+2n+log2(N)) - (log2(N)+2m+2n-2) = 2 extra bits
- So we have 2 extra bits beyond the minimum required, which provides some margin.

## Practical Tips
1. Choose your Qm.n format based on the expected range of your data.
2. Simulate with fixed-point values to verify correctness.
3. Consider using rounding instead of truncation when downscaling.
4. For deep networks, consider scaling between layers to prevent overflow or underflow.
