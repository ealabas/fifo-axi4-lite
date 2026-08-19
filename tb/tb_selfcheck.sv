module tb_selfcheck;
  localparam int WIDTH = 32;
  localparam int DEPTH = 4;

  logic clk, rst_n, wr_en, rd_en;
  logic full, empty, wr_err, rd_err;
  logic [WIDTH-1:0] wr_data, rd_data;

  int checks;
  int errors;
  int burst_wr_cnt;
  int burst_rd_cnt;

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

    $display("Coverage = %.2f%%", cg_inst.get_coverage());
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

    if (wr_en && !full && !rd_en) burst_wr_cnt <= burst_wr_cnt + 1;
    else burst_wr_cnt <= 0;

    if (rd_en && !empty && !wr_en) burst_rd_cnt <= burst_rd_cnt + 1;
    else burst_rd_cnt <= 0;
  end

  // functional coverage
  covergroup fifo_cg @(posedge clk);
    cp_full: coverpoint full;
    cp_empty: coverpoint empty;
    cp_wr: coverpoint wr_en;
    cp_rd: coverpoint rd_en;

    x_wr_rd: cross cp_wr, cp_rd;
    x_full_wr: cross cp_full, cp_wr;
    x_empty_rd: cross cp_empty, cp_rd;

    cp_occupancy: coverpoint data.size() {
      bins level_0 = {0};
      bins level_1 = {1};
      bins level_2 = {2};
      bins level_3 = {3};
      bins level_4 = {4};
    }

    cp_wr_wrap: coverpoint dut.wr_ptr[2] {bins no_wrap = {0}; bins wrap = {1};}

    cp_rd_wrap: coverpoint dut.rd_ptr[2] {bins no_wrap = {0}; bins wrap = {1};}

    cp_wr_burst: coverpoint burst_wr_cnt {
      bins no_burst = {0, 1}; bins burst_2 = {2}; bins burst_3 = {3}; bins burst_4 = {4};
    }

    cp_rd_burst: coverpoint burst_rd_cnt {
      bins no_burst = {0, 1}; bins burst_2 = {2}; bins burst_3 = {3}; bins burst_4 = {4};
    }

    x_full_wr_rd: cross cp_full, cp_wr, cp_rd{
      bins full_write_read = binsof(cp_full) intersect {1} &&
        binsof(cp_wr) intersect {1} && binsof(cp_rd) intersect {
        1
      };
    }

  endgroup

  fifo_cg cg_inst = new();

endmodule
