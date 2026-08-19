/*
module tb_top;
  localparam int WIDTH = 32;
  localparam int DEPTH = 4;

  logic clk, rst_n, wr_en, rd_en;
  logic full, empty, wr_err, rd_err;
  logic [WIDTH-1:0] wr_data, rd_data;

  fifo_sync #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .wr_en(wr_en),
      .wr_data(wr_data),
      .rd_en(rd_en),
      .rd_data(rd_data),
      .full(full),
      .empty(empty),
      .wr_err(wr_err),
      .rd_err(rd_err)
  );

  initial begin
    clk = 0;
  end

  always #5 clk = ~clk;

  initial begin
    rst_n   = 0;
    wr_en   = 0;
    rd_en   = 0;
    wr_data = 0;
    #20 rst_n = 1;
    @(posedge clk);
    wr_en   <= 1;
    wr_data <= 10;
    @(posedge clk);
    wr_data <= 20;
    @(posedge clk);
    wr_data <= 30;
    @(posedge clk);
    wr_data <= 40;
    @(posedge clk);
    wr_data <= 50;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    wr_en <= 0;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    rd_en <= 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    rd_en <= 0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    $finish;
  end

endmodule
*/

