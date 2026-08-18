`timescale 1ns / 1ps
//==========================================================================
//  Synchronous FIFO
//  Parameterizable depth and width
//==========================================================================
module fifo_sync #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH      = 8
) (
    input  wire                   clk,
    input  wire                   rst_n,
    // Write port
    input  wire [DATA_WIDTH-1:0]  din,
    input  wire                   wr_en,
    output wire                   full,
    // Read port
    output wire [DATA_WIDTH-1:0]  dout,
    input  wire                   rd_en,
    output wire                   empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg [ADDR_WIDTH:0]   wptr;  // Extra bit for full/empty detection
    reg [ADDR_WIDTH:0]   rptr;

    // Combinatorial flags
    assign full  = (wptr == {~rptr[ADDR_WIDTH], rptr[ADDR_WIDTH-1:0]});
    assign empty = (wptr == rptr);

    // Data output
    assign dout  = mem[rptr[ADDR_WIDTH-1:0]];

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= '0;
        end else if (wr_en && !full) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= din;
            wptr <= wptr + 1'b1;
        end
    end

    // Read logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr <= '0;
        end else if (rd_en && !empty) begin
            rptr <= rptr + 1'b1;
        end
    end

endmodule
