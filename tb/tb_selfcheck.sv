module tb_selfcheck;
  localparam int WIDTH = 32;
  localparam int DEPTH = 4;

  logic clk, rst_n, wr_en, rd_en;
  logic full, empty, wr_err, rd_err;
  logic [WIDTH-1:0] wr_data, rd_data;

  int checks;
  int errors;

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

  logic [WIDTH-1:0] data[$:DEPTH];

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
    repeat (200) begin
      @(posedge clk);
      wr_en   <= $urandom_range(0, 1);
      rd_en   <= $urandom_range(0, 1);
      wr_data <= $urandom();
    end
    @(posedge clk);
    $display("==================================");
    $display("TEST DONE: %0d checks, %0d errors", checks, errors);
    if (errors == 0) $display("RESULT: PASS");
    else begin
      $display("RESULT: FAIL (%0d mismatches)", errors);
    end
    $display("==================================");
    $finish;
  end

  always @(posedge clk) begin
    if (!empty) begin
      checks = checks + 1;
      if (rd_data !== data[0]) begin
        errors = errors + 1;
        $error("[%0t] MISMATCH: expected %h, got %h", $time, data[0], rd_data);
      end
    end

    if (wr_en && !full) begin
      data.push_back(wr_data);
    end

    if (rd_en && !empty) begin
      data.pop_front();
    end
  end

endmodule
