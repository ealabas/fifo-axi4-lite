module fifo_sync #(
    parameter int WIDTH = 32,
    parameter int DEPTH = 4
) (
    input logic clk,
    input logic rst_n,
    input logic wr_en,
    input logic [WIDTH-1:0] wr_data,
    input logic rd_en,

    output logic [WIDTH-1:0] rd_data,

    output logic full,
    output logic empty,
    output logic wr_err,
    output logic rd_err
);
  localparam int AddrWidth = $clog2(DEPTH);
  localparam int PtrWidth = AddrWidth + 1;

  logic [PtrWidth-1:0] wr_ptr;
  logic [PtrWidth-1:0] rd_ptr;
  logic [WIDTH-1:0] arr[DEPTH];  // [DEPTH] = [0:DEPTH-1]

  assign empty = (wr_ptr == rd_ptr);
  assign full = (wr_ptr[PtrWidth-1] != rd_ptr[PtrWidth-1])
                 && (wr_ptr[PtrWidth-2:0] == rd_ptr[PtrWidth-2:0]);

  assign wr_err = wr_en && full;
  assign rd_err = rd_en && empty;

  always_comb begin
    if (empty) begin
      rd_data = '0;
    end else begin
      rd_data = arr[rd_ptr[AddrWidth-1:0]];
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
    end else begin
      if (wr_en && !full) begin
        arr[wr_ptr[AddrWidth-1:0]] <= wr_data;
        wr_ptr <= wr_ptr + 1;
      end
      if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

endmodule

