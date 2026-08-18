module axil_fifo #(
    parameter int WIDTH      = 32,
    parameter int ADDR_WIDTH = 4,
    parameter int DEPTH      = 4
) (
    input logic S_AXI_ACLK,
    input logic S_AXI_ARESETN,

    // AW channel
    input  logic [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  logic                  S_AXI_AWVALID,
    output logic                  S_AXI_AWREADY,

    // W channel
    input  logic [    WIDTH-1:0] S_AXI_WDATA,
    input  logic [(WIDTH/8)-1:0] S_AXI_WSTRB,
    input  logic                 S_AXI_WVALID,
    output logic                 S_AXI_WREADY,

    // B channel (Write Response)
    output logic [1:0] S_AXI_BRESP,
    output logic       S_AXI_BVALID,
    input  logic       S_AXI_BREADY,

    // AR channel (Read Address)
    input  logic [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  logic                  S_AXI_ARVALID,
    output logic                  S_AXI_ARREADY,

    // R channel (Read Data)
    output logic [WIDTH-1:0] S_AXI_RDATA,
    output logic [      1:0] S_AXI_RRESP,
    output logic             S_AXI_RVALID,
    input  logic             S_AXI_RREADY
);

  logic             fifo_wr_en;
  logic [WIDTH-1:0] fifo_wr_data;
  logic             fifo_rd_en;
  logic [WIDTH-1:0] fifo_rd_data;
  logic             fifo_full;
  logic             fifo_empty;
  logic             fifo_wr_err;
  logic             fifo_rd_err;

  typedef enum logic [1:0] {
    IDLE,
    WRITE,
    RESP
  } w_state_t;

  w_state_t wr_state, wr_state_next;

  logic [ADDR_WIDTH-1:0] awaddr_r;
  logic [WIDTH-1:0] w_data_r;

  always_comb begin
    case (wr_state)
      IDLE: begin
        if (S_AXI_AWVALID && S_AXI_WVALID) wr_state_next = WRITE;
        else wr_state_next = IDLE;
      end

      WRITE: begin
        wr_state_next = RESP;
      end

      RESP: begin
        if (S_AXI_BREADY) wr_state_next = IDLE;
        else wr_state_next = RESP;
      end

      default: wr_state_next = IDLE;
    endcase
  end

  fifo_sync #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) fifo_i (
      .clk    (S_AXI_ACLK),
      .rst_n  (S_AXI_ARESETN),
      .wr_en  (fifo_wr_en),
      .wr_data(fifo_wr_data),
      .rd_en  (fifo_rd_en),
      .rd_data(fifo_rd_data),
      .full   (fifo_full),
      .empty  (fifo_empty),
      .wr_err (fifo_wr_err),
      .rd_err (fifo_rd_err)
  );


endmodule
