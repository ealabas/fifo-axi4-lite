module fifo_sync_sva #(
    // parameter repeat is necessary
    parameter int WIDTH = 32,
    parameter int DEPTH = 4
) (
    input logic             clk,
    input logic             rst_n,
    input logic             wr_en,
    input logic [WIDTH-1:0] wr_data,
    input logic             rd_en,
    input logic [WIDTH-1:0] rd_data,
    input logic             full,
    input logic             empty,
    input logic             wr_err,
    input logic             rd_err,

    // internal signals
    input logic [PtrWidth-1:0] wr_ptr,
    input logic [PtrWidth-1:0] rd_ptr
);

  localparam int AddrWidth = $clog2(DEPTH);
  localparam int PtrWidth = AddrWidth + 1;

  // wr_err combinational
  assert property (@(posedge clk) disable iff (!rst_n) wr_err == (wr_en && full));

  // rd_err combinational
  assert property (@(posedge clk) disable iff (!rst_n) rd_err == (rd_en && empty));

  // full and empty can not be high at the same time
  assert property (@(posedge clk) disable iff (!rst_n) !(full && empty));

  // wr_ptr should not change if you try to write on full fifo
  assert property (@(posedge clk) disable iff (!rst_n) (wr_en && full) |=> (wr_ptr == $past(
      wr_ptr
  )));

  // rd_ptr should not change if you try to read on empty fifo
  assert property (@(posedge clk) disable iff (!rst_n) (rd_en && empty) |=> (rd_ptr == $past(
      rd_ptr
  )));

  // TO-DO: wr_ptr should increment only one assertion to check wrap

  // FWFT assertion
  assert property (@(posedge clk) disable iff (!rst_n) (wr_en && empty) |=> (rd_data == $past(
      wr_data
  )));

endmodule

bind fifo_sync fifo_sync_sva #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
) sva_i (
    .clk    (clk),
    .rst_n  (rst_n),
    .wr_en  (wr_en),
    .wr_data(wr_data),
    .rd_en  (rd_en),
    .rd_data(rd_data),
    .full   (full),
    .empty  (empty),
    .wr_err (wr_err),
    .rd_err (rd_err),
    .wr_ptr (wr_ptr),
    .rd_ptr (rd_ptr)
);
