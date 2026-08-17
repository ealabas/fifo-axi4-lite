module fifo_sync #(
    parameter int WIDTH = 32,
    parameter int DEPTH = 4
) (
    input clk,
    input rst_n,
    input wr_en,
    input [WIDTH-1:0] wr_data,
    input rd_en,

    output [WIDTH-1:0] rd_data,

    output full,
    output empty,
    output wr_err,
    output rd_err
);
  localparam int AddrWidth = $clog2(DEPTH);
  localparam int PtrWidth = ADDR_WIDTH + 1;

  reg [PtrWidth-1:0] wr_ptr;
  reg [PtrWidth-1:0] rd_ptr;
  reg [WIDTH-1:0] arr[DEPTH];  // [DEPTH] = [0:DEPTH-1]
endmodule

