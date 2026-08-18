`timescale 1ns / 1ps
//==========================================================================
//  Testbench for N x N Systolic Array
//  Verifies matrix multiplication: C = A * B
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
    reg                   C_ready [0:N-1];

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
        .C_ready(C_ready)
    );

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
        C_ready = '{default: 1'b1};  // Always ready to accept output
        #20;
        rst_n = 1;
    end

    // Test sequence: multiply two small matrices
    initial begin
        // Wait for reset deassertion
        wait (rst_n);
        @(posedge clk);

        // Define test matrices (4x4)
        // A = [1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 16]
        // B = [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]  (Identity)
        // Expected C = A
        automatic int A_val [0:N-1][0:N-1] = '{
            '{1, 2, 3, 4},
            '{5, 6, 7, 8},
            '{9, 10, 11, 12},
            '{13, 14, 15, 16}
        };
        automatic int B_val [0:N-1][0:N-1] = '{
            '{1, 0, 0, 0},
            '{0, 1, 0, 0},
            '{0, 0, 1, 0},
            '{0, 0, 0, 1}
        };

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

        // Wait for computation to complete (latency = 2N + N - 2 = 3N - 2 for NxN * NxN)
        repeat (3*N - 2) @(posedge clk);

        // Check outputs
        $display("=== Test Results ===");
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                automatic int expected = A_val[i][j];  // Since B is identity
                automatic int got      = C_out[i];
                if (got !== expected) begin
                    $error("Mismatch at C[%0d]: expected %0d, got %0d", i, expected, got);
                end else begin
                    $display("C[%0d] = %0d (OK)", i, got);
                end
            end
        end

        $display("Testbench finished.");
        $finish;
    end

    // Optional: dump waves for GTKWave
    initial begin
        $dumpfile("systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);
    end

endmodule
