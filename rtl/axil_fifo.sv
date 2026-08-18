module axil_fifo #(
    parameter int WIDTH      = 32,
    parameter int ADDR_WIDTH = 4
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
endmodule
