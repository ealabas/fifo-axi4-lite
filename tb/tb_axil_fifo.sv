import axi_vip_pkg::*;
import axi_vip_0_pkg::*;

module tb_axil_fifo;
  bit clk = 0;
  bit rst_n = 0;

  logic [31:0] awaddr;
  logic [2:0] awprot;
  logic awvalid, awready;
  logic [31:0] wdata;
  logic [ 3:0] wstrb;
  logic wvalid, wready;
  logic [1:0] bresp;
  logic bvalid, bready;
  logic [31:0] araddr;
  logic [ 2:0] arprot;
  logic arvalid, arready;
  logic [31:0] rdata;
  logic [ 1:0] rresp;
  logic rvalid, rready;

  axi_vip_0 vip_i (
      .aclk         (clk),      // input wire aclk
      .aresetn      (rst_n),    // input wire aresetn
      .m_axi_awaddr (awaddr),   // output wire [31 : 0] m_axi_awaddr
      .m_axi_awprot (awprot),   // output wire [2 : 0] m_axi_awprot
      .m_axi_awvalid(awvalid),  // output wire m_axi_awvalid
      .m_axi_awready(awready),  // input wire m_axi_awready
      .m_axi_wdata  (wdata),    // output wire [31 : 0] m_axi_wdata
      .m_axi_wstrb  (wstrb),    // output wire [3 : 0] m_axi_wstrb
      .m_axi_wvalid (wvalid),   // output wire m_axi_wvalid
      .m_axi_wready (wready),   // input wire m_axi_wready
      .m_axi_bresp  (bresp),    // input wire [1 : 0] m_axi_bresp
      .m_axi_bvalid (bvalid),   // input wire m_axi_bvalid
      .m_axi_bready (bready),   // output wire m_axi_bready
      .m_axi_araddr (araddr),   // output wire [31 : 0] m_axi_araddr
      .m_axi_arprot (arprot),   // output wire [2 : 0] m_axi_arprot
      .m_axi_arvalid(arvalid),  // output wire m_axi_arvalid
      .m_axi_arready(arready),  // input wire m_axi_arready
      .m_axi_rdata  (rdata),    // input wire [31 : 0] m_axi_rdata
      .m_axi_rresp  (rresp),    // input wire [1 : 0] m_axi_rresp
      .m_axi_rvalid (rvalid),   // input wire m_axi_rvalid
      .m_axi_rready (rready)    // output wire m_axi_rready
  );

  axil_fifo #(
      .WIDTH(32),
      .ADDR_WIDTH(32),
      .DEPTH(4)
  ) dut (
      .S_AXI_ACLK(clk),
      .S_AXI_ARESETN(rst_n),
      .S_AXI_AWADDR(awaddr),
      .S_AXI_AWVALID(awvalid),
      .S_AXI_AWREADY(awready),
      .S_AXI_WDATA(wdata),
      .S_AXI_WSTRB(wstrb),
      .S_AXI_WVALID(wvalid),
      .S_AXI_WREADY(wready),
      .S_AXI_BRESP(bresp),
      .S_AXI_BVALID(bvalid),
      .S_AXI_BREADY(bready),
      .S_AXI_ARADDR(araddr),
      .S_AXI_ARVALID(arvalid),
      .S_AXI_ARREADY(arready),
      .S_AXI_RDATA(rdata),
      .S_AXI_RRESP(rresp),
      .S_AXI_RVALID(rvalid),
      .S_AXI_RREADY(rready)
  );

  always #5 clk = ~clk;

endmodule
