`timescale 1ns / 1ps
//==========================================================================
//  Processing Element for Systolic Array
//  Implements: accum += A * B
//  Data flows: A west -> east, B north -> south
//==========================================================================
module pe #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 32
) (
    input  wire                   clk,
    input  wire                   rst_n,
    // West input (A data)
    input  wire [DATA_WIDTH-1:0]  A_w,
    input  wire                   A_w_valid,
    output wire                   A_w_ready,
    // North input (B data)
    input  wire [DATA_WIDTH-1:0]  B_n,
    input  wire                   B_n_valid,
    output wire                   B_n_ready,
    // East output (A data)
    output wire [DATA_WIDTH-1:0]  A_e,
    output wire                   A_e_valid,
    input  wire                   A_e_ready,
    // South output (B data)
    output wire [DATA_WIDTH-1:0]  B_s,
    output wire                   B_s_valid,
    input  wire                   B_s_ready,
    // Accumulator input/output
    input  wire [ACC_WIDTH-1:0]   acc_in,
    output wire [ACC_WIDTH-1:0]   acc_out
);

    // Internal registers
    reg [DATA_WIDTH-1:0]   A_reg;
    reg [DATA_WIDTH-1:0]   B_reg;
    reg                    A_valid_reg;
    reg                    B_valid_reg;
    reg [ACC_WIDTH-1:0]    acc_reg;

    // Combinatorial logic
    wire [DATA_WIDTH-1:0]   A_next = A_w_valid ? A_w : A_reg;
    wire [DATA_WIDTH-1:0]   B_next = B_n_valid ? B_n : B_reg;
    wire                    A_valid_next = A_w_valid || A_valid_reg;
    wire                    B_valid_next = B_n_valid || B_valid_reg;

    // Multiplication and accumulation
    wire [ACC_WIDTH-1:0]    mult_result = $signed(A_reg) * $signed(B_reg);
    wire [ACC_WIDTH-1:0]    acc_next = acc_in + mult_result;

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg     <= '0;
            B_reg     <= '0;
            A_valid_reg <= 1'b0;
            B_valid_reg <= 1'b0;
            acc_reg   <= '0;
        end else begin
            A_reg     <= A_next;
            B_reg     <= B_next;
            A_valid_reg <= A_valid_next;
            B_valid_reg <= B_valid_next;
            acc_reg   <= acc_next;
        end
    end

    // Output assignments (valid when both inputs valid)
    assign A_e        = A_reg;
    assign A_e_valid  = A_valid_reg;
    assign A_w_ready  = A_e_ready;  // Backpressure

    assign B_s        = B_reg;
    assign B_s_valid  = B_valid_reg;
    assign B_n_ready  = B_s_ready;  // Backpressure

    assign acc_out    = acc_reg;

endmodule
