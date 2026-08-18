#!/usr/bin/env python3
"""
Example: Using the systolic array for fixed-point 2D convolution
This script demonstrates the steps to use the systolic array for convolution:
1. Generate input feature map and kernel (as fixed-point values)
2. Perform im2col transformation
3. Use the systolic array (via simulation) to compute the matrix multiplication
4. Descale the result to get the fixed-point convolution output

Note: This script does not actually run the Verilog simulation (for simplicity),
      but shows the steps. To run with Verilog, you would need to:
      - Write the im2col matrix to a file
      - Feed it to the systolic array testbench
      - Read back the result and descale
"""

import numpy as np

def float_to_fixed_point(value, frac_bits):
    """Convert float to fixed-point integer representation."""
    return np.round(value * (2**frac_bits)).astype(int)

def fixed_point_to_float(value, frac_bits):
    """Convert fixed-point integer to float."""
    return value / (2**frac_bits)

def imcol2d(image, kernel_h, kernel_w, stride=1, padding=0):
    """
    Perform im2col transformation for 2D convolution.
    Returns the im2col matrix where each column is a flattened patch.
    """
    # Add padding
    if padding > 0:
        image = np.pad(image, ((padding, padding), (padding, padding)), mode='constant')
    
    H, W, C_in = image.shape
    H_out = (H - kernel_h) // stride + 1
    W_out = (W - kernel_w) // stride + 1
    
    # Initialize output matrix
    out_cols = H_out * W_out
    out_rows = kernel_h * kernel_w * C_in
    X_col = np.zeros((out_rows, out_cols))
    
    col_idx = 0
    for i in range(H_out):
        for j in range(W_out):
            # Extract patch
            h_start = i * stride
            h_end = h_start + kernel_h
            w_start = j * stride
            w_end = w_start + kernel_w
            patch = image[h_start:h_end, w_start:w_end, :]  # Shape: (kernel_h, kernel_w, C_in)
            # Flatten patch (column-major order for consistency with typical im2col)
            X_col[:, col_idx] = patch.flatten(order='F')
            col_idx += 1
            
    return X_col, H_out, W_out

def main():
    print("Fixed-Point Convolution Example using Systolic Array")
    print("=" * 55)
    
    # Example: 5x5 input, 3x3 kernel, 1 channel, 1 output, stride=1, no padding
    H, W, C_in = 5, 5, 1
    K_h, K_w, C_out = 3, 3, 1
    stride = 1
    padding = 0
    
    # Generate random input feature map and kernel (as floats)
    np.random.seed(42)  # For reproducibility
    input_fmap = np.random.randn(H, W, C_in).astype(np.float32)
    kernel = np.random.randn(K_h, K_w, C_in, C_out).astype(np.float32)
    
    print(f"Input feature map shape: {input_fmap.shape}")
    print(f"Kernel shape: {kernel.shape}")
    
    # Choose fixed-point format: Q4.4 (4 integer, 4 fractional bits)
    frac_bits = 4
    int_bits = 4  # Total width = 8 bits
    
    print(f"\nUsing fixed-point format: Q{int_bits}.{frac_bits} (total {int_bits+frac_bits} bits)")
    print(f"Integer range: [{-2**(int_bits-1)}, {2**(int_bits-1)-2**(-frac_bits)}]")
    
    # Convert to fixed-point integers
    input_fmap_fp = float_to_fixed_point(input_fmap, frac_bits)
    kernel_fp = float_to_fixed_point(kernel, frac_bits)
    
    print(f"\nInput feature map (fixed-point, scaled by 2^{frac_bits}):")
    print(input_fmap_fp[0, :, 0])  # Show first row, first channel
    
    print(f"\nKernel (fixed-point, scaled by 2^{frac_bits}):")
    print(kernel_fp[:, :, 0, 0])  # Show kernel for first channel
    
    # Perform im2col transformation
    X_col, H_out, W_out = imcol2d(input_fmap_fp, K_h, K_w, stride, padding)
    K_col = kernel_fp.transpose(2, 3, 0, 1).reshape(C_out, -1)  # Shape: (C_out, K_h*K_w*C_in)
    # Note: For convolution, we need: Y_col = X_col * K_col^T
    # So A = X_col (shape: [H_out*W_out, K_h*K_w*C_in])
    #    B = K_col^T (shape: [K_h*K_w*C_in, C_out])
    #    C = A * B (shape: [H_out*W_out, C_out])
    
    A = X_col.T  # Shape: [H_out*W_out, K_h*K_w*C_in]
    B = K_col.T  # Shape: [K_h*K_w*C_in, C_out]
    
    print(f"\nAfter im2col:")
    print(f"  A matrix shape: {A.shape}  (should be [{H_out*W_out}, {K_h*K_w*C_in}])")
    print(f"  B matrix shape: {B.shape}  (should be [{K_h*K_w*C_in}, {C_out}])")
    print(f"  Expected output shape: {H_out*W_out} x {C_out}")
    
    # Scale note for fixed-point multiplication
    print(f"\nFixed-point scaling notes:")
    print(f"  Inputs scaled by 2^{frac_bits}")
    print(f"  Product of two inputs scaled by 2^{2*frac_bits}")
    print(f"  Accumulation of {H_out*W_out} products requires extra {int(np.ceil(np.log2(H_out*W_out)))} bits to avoid overflow")
    print(f"  To get back to Q{int_bits}.{frac_bits}, right-shift by {2*frac_bits + int(np.ceil(np.log2(H_out*W_out)))} bits")
    
    # Example systolic array usage (conceptual)
    print(f"\nTo use the systolic array:")
    print(f"  1. Set array dimensions to at least {max(A.shape[0], B.shape[1])} x {max(A.shape[1], B.shape[0])}")
    print(f"  2. Feed A matrix row-by-row from west")
    print(f"  3. Feed B matrix column-by-column from north")
    print(f"  4. Collect C matrix row-by-row from south")
    print(f"  5. Descale each result by right-shifting {2*frac_bits + int(np.ceil(np.log2(H_out*W_out)))} bits")
    
    # Compute expected result using floating-point for comparison
    # Convolution using scipy or manual
    from scipy.signal import convolve2d
    expected_float = np.zeros((H_out, W_out, C_out))
    for c_out in range(C_out):
        for c_in in range(C_in):
            expected_float[:, :, c_out] += convolve2d(input_fmap[:, :, c_in], kernel[:, :, c_in, c_out], mode='valid')
    
    # Convert expected to fixed-point integers (after descaling)
    expected_fp = float_to_fixed_point(expected_float, frac_bits)
    print(f"\nExpected output (fixed-point, scaled by 2^{frac_bits}):")
    print(expected_fp[:, :, 0])
    
    # Note: To compare with systolic array output, you would:
    #   1. Feed A and B (as integers) to the systolic array
    #   2. Get raw integer result matrix C_raw
    #   3. Descale: C_fp = C_raw >> (2*frac_bits + int(np.ceil(np.log2(H_out*W_out))))
    #   4. Compare C_fp with expected_fp
    
    print(f"\nExample complete. See doc/fixed_point_guide.md and doc/convolution_guide.md for details.")

if __name__ == "__main__":
    main()
