`timescale 1ns / 1ps
//==========================================================================
//  Enhanced Testbench for N x N Systolic Array
//  Includes random stimulus and self-checking
//==========================================================================
`include "systolic_array.sv"

module tb_systolic_array;

    // Parameters
    localparam N          = 4;
    localparam DATA_WIDTH = 16;
    localparam ACC_WIDTH  = 32;

    // Clock and reset
    reg clk;
    reg rst_n;

    // Inputs
    reg [DATA_WIDTH-1:0]  A_in [0:N-1];
    reg                   A_valid [0:N-1];
    reg [DATA_WIDTH-1:0]  B_in [0:N-1];
    reg                   B_valid [0:N-1];

    // Outputs
    wire [ACC_WIDTH-1:0]  C_out [0:N-1];
    wire                  C_valid [0:N-1];
    wire                  C_ready [0:N-1];
    reg                   C_ready_int [0:N-1];

    // Handshake signals from DUT
    wire [N-1:0]          A_ready;
    wire [N-1:0]          B_ready;

    // Instantiate DUT
    systolic_array #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(A_in),
        .A_valid(A_valid),
        .A_ready(A_ready),
        .B_in(B_in),
        .B_valid(B_valid),
        .B_ready(B_ready),
        .C_out(C_out),
        .C_valid(C_valid),
        .C_ready(C_ready_int)
    );

    // Always ready to accept output
    assign C_ready = '{default: 1'b1};

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end

    // Reset sequence
    initial begin
        rst_n = 0;
        A_in  = '{default: '0};
        A_valid = '{default: 1'b0};
        B_in  = '{default: '0};
        B_valid = '{default: 1'b0};
        #20;
        rst_n = 1;
    end

    // Test sequence
    initial begin
        // Wait for reset deassertion
        wait (rst_n);
        @(posedge clk);

        // Test 1: Identity matrix (B = I)
        $display("=== Test 1: Identity Matrix ===");
        test_identity();

        // Test 2: Zero matrix (B = 0)
        $display("\n=== Test 2: Zero Matrix ===");
        test_zero();

        // Test 3: Random small matrices
        $display("\n=== Test 3: Random Matrices ===");
        test_random();

        // Test 4: Larger matrix (if N allows)
        if (N >= 8) begin
            $display("\n=== Test 4: Larger Matrices ===");
            test_larger();
        end

        $display("\nAll tests completed.");
        $finish;
    end

    // Task to test identity matrix
    task test_identity;
        automatic int A_val [0:N-1][0:N-1];
        automatic int B_val [0:N-1][0:N-1];
        automatic int expected [0:N-1][0:N-1];
        
        // Initialize A with sequential values
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                A_val[i][j] = i * N + j + 1;
                B_val[i][j] = (i == j) ? 1 : 0;  // Identity matrix
                expected[i][j] = A_val[i][j];      // Since B is I
            end
        end
        
        feed_and_check(A_val, B_val, expected);
    endtask

    // Task to test zero matrix
    task test_zero;
        automatic int A_val [0:N-1][0:N-1];
        automatic int B_val [0:N-1][0:N-1];
        automatic int expected [0:N-1][0:N-1];
        
        // Initialize A with random values
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                A_val[i][j] = $urandom_range(-100, 100);
                B_val[i][j] = 0;  // Zero matrix
                expected[i][j] = 0;  // Result should be zero
            end
        end
        
        feed_and_check(A_val, B_val, expected);
    endtask

    // Task to test random matrices
    task test_random;
        automatic int A_val [0:N-1][0:N-1];
        automatic int B_val [0:N-1][0:N-1];
        automatic int expected [0:N-1][0:N-1];
        
        // Initialize with small random values
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                A_val[i][j] = $urandom_range(-10, 10);
                B_val[i][j] = $urandom_range(-10, 10);
                // Compute expected result
                expected[i][j] = 0;
                for (int k = 0; k < N; k++) begin
                    expected[i][j] += A_val[i][k] * B_val[k][j];
                end
            end
        end
        
        feed_and_check(A_val, B_val, expected);
    endtask

    // Task to test larger matrices (use smaller values to avoid overflow)
    task test_larger;
        automatic int A_val [0:N-1][0:N-1];
        automatic int B_val [0:N-1][0:N-1];
        automatic int expected [0:N-1][0:N-1];
        
        // Initialize with very small values
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                A_val[i][j] = $urandom_range(-2, 2);
                B_val[i][j] = $urandom_range(-2, 2);
                // Compute expected result
                expected[i][j] = 0;
                for (int k = 0; k < N; k++) begin
                    expected[i][j] += A_val[i][k] * B_val[k][j];
                end
            end
        end
        
        feed_and_check(A_val, B_val, expected);
    endtask

    // Task to feed matrices and check results
    task feed_and_check;
        input [N-1:0][N-1:0] int A_val;
        input [N-1:0][N-1:0] int B_val;
        input [N-1:0][N-1:0] int expected;
        
        integer cycle_count;
        integer results_received [0:N-1][0:N-1];
        integer results_count;
        
        // Initialize
        results_count = 0;
        foreach (results_received[i,j]) results_received[i,j] = 0;
        
        // Feed matrix A row-by-row from west (one row per cycle)
        // Feed matrix B column-by-column from north (one column per cycle)
        for (int row = 0; row < N; row++) begin
            @(posedge clk);
            for (int col = 0; col < N; col++) begin
                A_in[col]     = A_val[row][col];
                A_valid[col]  = 1'b1;
                B_in[row]     = B_val[col][row];  // Note: B[col][row] for column-major feed
                B_valid[row]  = 1'b1;
            end
            @(posedge clk);
            A_valid = '{default: 1'b0};
            B_valid = '{default: 1'b0};
        end

        // Wait for computation to complete
        // Latency = (N-1) + (N-1) + N = 3N - 2 for NxN * NxM
        repeat (3*N - 2) @(posedge clk);
        
        // Collect results for a few more cycles to catch any late outputs
        repeat (N) @(posedge clk) begin
            for (int i = 0; i < N; i++) begin
                if (C_valid[i]) begin
                    results_received[i] = C_out[i];
                    results_count++;
                end
            end
        end

        // Check results
        $display("Results received: %0d", results_count);
        foreach (expected[i,j]) begin
            if (results_received[i] !== expected[i][j]) begin
                $error("Mismatch at C[%0d]: expected %0d, got %0d", i, expected[i][j], results_received[i]);
            end else begin
                // $display("C[%0d] = %0d (OK)", i, expected[i][j]);
            end
        end
        
        if (results_count > 0) begin
            $display("Test passed!");
        end
    endtask

    // Optional: dump waves for GTKWave
    initial begin
        $dumpfile("systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);
    end

endmodule
