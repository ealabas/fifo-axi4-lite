import axi_vip_0_pkg::*;
import axi_vip_pkg::*;


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

  // ------------------ Stimulus ------------------
  initial begin
    axi_vip_0_mst_t master_agent;
    bit [31:0] write_data;
    bit [1:0]  write_resp;
    bit [31:0] read_data;
    bit [1:0]  read_resp;
    bit [31:0] status;
    bit [1:0]  status_resp;
    bit [31:0] empty_read_data;
    bit [1:0]  empty_read_resp;
    bit [31:0] status2;
    bit [1:0]  status2_resp;
    bit [31:0] temp_data;
    bit [1:0]  temp_resp;
    bit [31:0] full_data;
    bit [1:0]  full_resp;
    
    $display("Stimulus started at %0t", $time);
    
    // Reset sequence
    rst_n = 0;
    repeat (20) @(posedge clk);
    rst_n = 1;
    repeat (5) @(posedge clk);
    $display("Reset done at %0t", $time);
    
    // vip_i.inst.IF.set_xilinx_reset_check_to_warn();
    
    master_agent = new("master_agent", vip_i.inst.IF);
    
    $display("Agent created");

    // Start the master
    master_agent.start_master();
    
    $display("Master started");

    // Test 1: Write to FIFO_WR (address 0x00)
    write_data = 32'hDEAD_BEEF;
    master_agent.AXI4LITE_WRITE_BURST(32'h0000_0000, 0, write_data, write_resp);
    $display("[%0t] WRITE data=0x%h, resp=%0d", $time, write_data, write_resp);

    // Test 2: Read from FIFO_RD (address 0x04)
    master_agent.AXI4LITE_READ_BURST(32'h0000_0004, 0, read_data, read_resp);
    $display("[%0t] READ data=0x%h, resp=%0d", $time, read_data, read_resp);

    // Test 3: Read STATUS (address 0x08)
    master_agent.AXI4LITE_READ_BURST(32'h0000_0008, 0, status, status_resp);
    $display("[%0t] STATUS=0x%h, resp=%0d", $time, status, status_resp);

    // Test 4: Read from empty FIFO (address 0x04) should return 0,
    // and status should show empty flag set
    master_agent.AXI4LITE_READ_BURST(32'h0000_0004, 0, empty_read_data, empty_read_resp);
    $display("[%0t] READ from empty, data=0x%h, resp=%0d", $time, empty_read_data, empty_read_resp);

    // Read status after empty read
    master_agent.AXI4LITE_READ_BURST(32'h0000_0008, 0, status2, status2_resp);
    $display("[%0t] STATUS after empty, read=0x%h, resp=%0d", $time, status2, status2_resp);


    // Test 5: Write to full FIFO (DEPTH=4) to see SLVERR
    // First fill the FIFO completely
    for (int i = 0; i < 4; i++) begin
      bit [1:0] temp_resp;
      master_agent.AXI4LITE_WRITE_BURST(32'h0000_0000, 0, 32'hA000_0000 + i, temp_resp);
      $display("[%0t] Filling FIFO with data=0x%h, resp=%0d", $time, 32'hA000_0000 + i, temp_resp);
    end

    // Now try to write when full to see SLVERR
    master_agent.AXI4LITE_WRITE_BURST(32'h0000_0000, 0, 32'hFFFF_FFFF, full_resp);
    $display("[%0t] Write after full, resp=%0d", $time, full_resp);

    $finish;
  end

endmodule
