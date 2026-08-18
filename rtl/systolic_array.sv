`timescale 1ns / 1ps
//==========================================================================
//  Configurable N x N Systolic Array for Matrix Multiplication
//  Computes: C = A * B
//  Dataflow: 
//    A matrix flows west-to-each through rows
//    B matrix flows north-to-south through columns
//    Each PE computes: accum += A * B
//==========================================================================
module systolic_array #(
    parameter N             = 4,   // Array dimension (N x N)
    parameter DATA_WIDTH    = 16,  // Input data width
    parameter ACC_WIDTH     = 32   // Accumulator width
) (
    input  wire                   clk,
    input  wire                   rst_n,
    // Input matrix A (row-major, fed row-by-row from west)
    input  wire [DATA_WIDTH-1:0]  A_in [0:N-1],  // One per row
    input  wire                   A_valid [0:N-1],
    output wire                   A_ready [0:N-1],
    // Input matrix B (column-major, fed column-by-column from north)
    input  wire [DATA_WIDTH-1:0]  B_in [0:N-1],  // One per column
    input  wire                   B_valid [0:N-1],
    output wire                   B_ready [0:N-1],
    // Output matrix C (row-major, read row-by-row from south)
    output wire [ACC_WIDTH-1:0]   C_out [0:N-1],
    output wire                   C_valid [0:N-1],
    input  wire                   C_ready [0:N-1]
);

    // Generate N x N array of PEs
    genvar i, j;
    wire [DATA_WIDTH-1:0]   A_w [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0]   A_e [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0]   B_n [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0]   B_s [0:N-1][0:N-1];
    wire                    A_w_valid [0:N-1][0:N-1];
    wire                    A_e_valid [0:N-1][0:N-1];
    wire                    B_n_valid [0:N-1][0:N-1];
    wire                    B_s_valid [0:N-1][0:N-1];
    wire                    A_w_ready [0:N-1][0:N-1];
    wire                    A_e_ready [0:N-1][0:N-1];
    wire                    B_n_ready [0:N-1][0:N-1];
    wire                    B_s_ready [0:N-1][0:N-1];
    wire [ACC_WIDTH-1:0]    acc_in [0:N-1][0:N-1];
    wire [ACC_WIDTH-1:0]    acc_out [0:N-1][0:N-1];

    // Connect inputs to west/north edges
    generate
        for (i = 0; i < N; i++) begin : row_gen
            // West edge: A_in feeds into column 0
            assign A_w[i][0]     = A_in[i];
            assign A_w_valid[i][0] = A_valid[i];
            assign A_ready[i]    = A_e_ready[i][0];  // Propagate ready signal east

            // North edge: B_in feeds into row 0
            assign B_n[0][i]     = B_in[i];
            assign B_n_valid[0][i] = B_valid[i];
            assign B_ready[i]    = B_s_ready[N-1][i];  // Propagate ready signal south
        end
    endgenerate

    // Instantiate PEs
    generate
        for (i = 0; i < N; i++) begin : row_loop
            for (j = 0; j < N; j++) begin : col_loop
                // West and North connections
                assign A_w[i][j] = (j == 0) ? A_in[i] : A_e[i][j-1];
                assign A_w_valid[i][j] = (j == 0) ? A_valid[i] : A_e_valid[i][j-1];
                assign A_e_ready[i][j] = (j == N-1) ? 1'b0 : A_w_ready[i][j+1];  // Last column sinks

                assign B_n[i][j] = (i == 0) ? B_in[j] : B_s[i-1][j];
                assign B_n_valid[i][j] = (i == 0) ? B_valid[j] : B_s_valid[i-1][j];
                assign B_s_ready[i][j] = (i == N-1) ? 1'b0 : B_n_ready[i+1][j];  // Last row sinks

                // Accumulator connections: first column gets zero, others get from west PE
                assign acc_in[i][j] = (j == 0) ? '0 : acc_out[i][j-1];

                // Instantiate PE
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .A_w(A_w[i][j]),
                    .A_w_valid(A_w_valid[i][j]),
                    .A_w_ready(A_w_ready[i][j]),
                    .B_n(B_n[i][j]),
                    .B_n_valid(B_n_valid[i][j]),
                    .B_n_ready(B_n_ready[i][j]),
                    .A_e(A_e[i][j]),
                    .A_e_valid(A_e_valid[i][j]),
                    .A_e_ready(A_e_ready[i][j]),
                    .B_s(B_s[i][j]),
                    .B_s_valid(B_s_valid[i][j]),
                    .B_s_ready(B_s_ready[i][j]),
                    .acc_in(acc_in[i][j]),
                    .acc_out(acc_out[i][j])
                );
            end
        end
    endgenerate

    // Connect outputs from south/east edges
    generate
        for (i = 0; i < N; i++) begin : output_row
            // South edge: C_out reads from last row
            assign C_out[i]     = acc_out[N-1][i];
            assign C_valid[i]   = B_s_valid[N-1][i];  // Valid when B data exits south
            // North ready already handled in B_s_ready above

            // East edge: A data exits after last column (not used for output, but for timing)
            // A_e_ready[i][N-1] is left unconnected (sinks)
        end
    endgenerate

endmodule
