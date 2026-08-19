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

  // Reset release counter 
  // hold READY low after reset
  logic [3:0] reset_cnt;
  logic       reset_released;

  always_ff @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      reset_cnt <= 0;
    end else if (reset_cnt < 4'hF) begin
      reset_cnt <= reset_cnt + 1;
    end
  end

  assign reset_released = (reset_cnt >= 4'h2); // Wait 2 cycles after reset

  // Write FSM
  typedef enum logic [1:0] {
    IDLE,
    WRITE,
    RESP
  } w_state_t;

  w_state_t wr_state, wr_state_next;

  logic [ADDR_WIDTH-1:0] awaddr_r;
  logic [WIDTH-1:0] w_data_r;
  logic wr_err_r;
  logic aw_done;
  logic w_done;

  // write seq logic
  always_ff @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      wr_state <= IDLE;
      awaddr_r <= 0;
      w_data_r <= 0;
      wr_err_r <= 0;
      aw_done  <= 0;
      w_done   <= 0;
    end else begin
      wr_state <= wr_state_next;

      if (wr_state == IDLE && reset_released && S_AXI_AWVALID && S_AXI_AWREADY) begin
        awaddr_r <= S_AXI_AWADDR;
        aw_done  <= 1;
      end

      if (wr_state == IDLE && reset_released && S_AXI_WVALID && S_AXI_WREADY) begin
        w_data_r <= S_AXI_WDATA;
        w_done   <= 1;
      end

      if (wr_state == RESP && S_AXI_BREADY) begin
        aw_done <= 0;
        w_done  <= 0;
      end

      if (wr_state == WRITE) wr_err_r <= fifo_wr_err;
    end
  end

  // write next state logic
  always_comb begin
    case (wr_state)
      IDLE: begin
        if (aw_done && w_done)
          wr_state_next = WRITE;
        else
          wr_state_next = IDLE;
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

  // READY signals only set to 1 after reset released
  assign S_AXI_AWREADY = (wr_state == IDLE) && reset_released;
  assign S_AXI_WREADY  = (wr_state == IDLE) && reset_released;

  // fifo outputs
  assign fifo_wr_en   = (wr_state == WRITE) && (awaddr_r[3:2] == 2'b00);
  assign fifo_wr_data = w_data_r;

  // B channel
  always_comb begin
    S_AXI_BVALID = (wr_state == RESP);
    S_AXI_BRESP  = wr_err_r ? 2'b10 : 2'b00;
  end

  // Read FSM
  typedef enum logic [1:0] {
    R_IDLE,
    R_READ
  } r_state_t;

  r_state_t rd_state, rd_state_next;

  logic [ADDR_WIDTH-1:0] araddr_r;
  logic rd_err_r;

  // read seq logic
  always_ff @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      rd_state <= R_IDLE;
      araddr_r <= 0;
      rd_err_r <= 0;
    end else begin
      rd_state <= rd_state_next;
      if (rd_state == R_IDLE && reset_released && S_AXI_ARVALID)
        araddr_r <= S_AXI_ARADDR;

      if (rd_state == R_READ && S_AXI_RREADY) begin
        if (araddr_r[3:2] == 2'b01)
          rd_err_r <= fifo_rd_err;
        else
          rd_err_r <= 0;
      end
    end
  end

  // read next state logic
  always_comb begin
    case (rd_state)
      R_IDLE: begin
        if (reset_released && S_AXI_ARVALID)
          rd_state_next = R_READ;
        else
          rd_state_next = R_IDLE;
      end
      R_READ: begin
        if (S_AXI_RREADY) rd_state_next = R_IDLE;
        else rd_state_next = R_READ;
      end
      default: rd_state_next = R_IDLE;
    endcase
  end

  // READY signal only set to 1 after reset released
  assign S_AXI_ARREADY = (rd_state == R_IDLE) && reset_released;
  assign S_AXI_RVALID  = (rd_state == R_READ);

  // fifo output selection logic
  assign fifo_rd_en = (rd_state == R_READ) && S_AXI_RREADY &&
                      (araddr_r[3:2] == 2'b01);

  always_comb begin
    case (araddr_r[3:2])
      2'b01:   S_AXI_RDATA = fifo_rd_data;
      2'b10:   S_AXI_RDATA = {28'b0, fifo_rd_err, fifo_wr_err, fifo_full, fifo_empty};
      default: S_AXI_RDATA = '0;
    endcase
  end

  always_comb begin
    S_AXI_RRESP = rd_err_r ? 2'b10 : 2'b00;
  end

  // FIFO instance
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