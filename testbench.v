`timescale 1ns / 1ps

module tb;

    reg clk;
    reg resetn;

    reg [4:0] rf_addr;

    wire [31:0] rf_data;
    wire [31:0] IF_pc, IF_inst;
    wire [31:0] ID_pc, EXE_pc, MEM_pc, WB_pc;
    wire [31:0] cpu_5_valid;
    wire [31:0] HI_data, LO_data;
    wire [31:0] CP0_STATUS, CP0_CAUSE, CP0_EPC;

    //====================================================
    //  AXI wires (instruction channel)
    //====================================================
    wire [31:0] M_AXI_INSTR_AWADDR;
    wire [7:0]  M_AXI_INSTR_AWLEN;
    wire        M_AXI_INSTR_AWVALID;
    wire        M_AXI_INSTR_AWREADY;

    wire [31:0] M_AXI_INSTR_WDATA;
    wire        M_AXI_INSTR_WVALID;
    wire        M_AXI_INSTR_WLAST;
    wire        M_AXI_INSTR_WREADY;

    wire [1:0]  M_AXI_INSTR_BRESP;
    wire        M_AXI_INSTR_BVALID;
    wire        M_AXI_INSTR_BREADY;

    wire [31:0] M_AXI_INSTR_ARADDR;
    wire [7:0]  M_AXI_INSTR_ARLEN;
    wire        M_AXI_INSTR_ARVALID;
    wire        M_AXI_INSTR_ARREADY;

    wire [31:0] M_AXI_INSTR_RDATA;
    wire        M_AXI_INSTR_RLAST;
    wire        M_AXI_INSTR_RVALID;
    wire        M_AXI_INSTR_RREADY;

    //====================================================
    //  AXI wires (data channel)
    //====================================================
    wire [31:0] M_AXI_DATA_AWADDR;
    wire [7:0]  M_AXI_DATA_AWLEN;
    wire        M_AXI_DATA_AWVALID;
    wire        M_AXI_DATA_AWREADY;

    wire [31:0] M_AXI_DATA_WDATA;
    wire        M_AXI_DATA_WVALID;
    wire        M_AXI_DATA_WLAST;
    wire        M_AXI_DATA_WREADY;

    wire [1:0]  M_AXI_DATA_BRESP;
    wire        M_AXI_DATA_BVALID;
    wire        M_AXI_DATA_BREADY;

    wire [31:0] M_AXI_DATA_ARADDR;
    wire [7:0]  M_AXI_DATA_ARLEN;
    wire        M_AXI_DATA_ARVALID;
    wire        M_AXI_DATA_ARREADY;

    wire [31:0] M_AXI_DATA_RDATA;
    wire        M_AXI_DATA_RLAST;
    wire        M_AXI_DATA_RVALID;
    wire        M_AXI_DATA_RREADY;


    //===============================================================
    //                   DUT: pipeline_cpu
    //===============================================================
    pipeline_cpu uut (
        .clk(clk),
        .resetn(resetn),
        .rf_addr(rf_addr),
        .rf_data(rf_data),

        .IF_pc(IF_pc), .IF_inst(IF_inst),
        .ID_pc(ID_pc), .EXE_pc(EXE_pc),
        .MEM_pc(MEM_pc), .WB_pc(WB_pc),

        .cpu_5_valid(cpu_5_valid),
        .HI_data(HI_data),
        .LO_data(LO_data),
        .CP0_STATUS(CP0_STATUS),
        .CP0_CAUSE(CP0_CAUSE),
        .CP0_EPC(CP0_EPC),

        // AXI instruction master
        .M_AXI_INSTR_AWADDR (M_AXI_INSTR_AWADDR),
        .M_AXI_INSTR_AWLEN  (M_AXI_INSTR_AWLEN),
        .M_AXI_INSTR_AWVALID(M_AXI_INSTR_AWVALID),
        .M_AXI_INSTR_AWREADY(M_AXI_INSTR_AWREADY),

        .M_AXI_INSTR_WDATA  (M_AXI_INSTR_WDATA),
        .M_AXI_INSTR_WVALID (M_AXI_INSTR_WVALID),
        .M_AXI_INSTR_WLAST  (M_AXI_INSTR_WLAST),
        .M_AXI_INSTR_WREADY (M_AXI_INSTR_WREADY),

        .M_AXI_INSTR_BRESP  (M_AXI_INSTR_BRESP),
        .M_AXI_INSTR_BVALID (M_AXI_INSTR_BVALID),
        .M_AXI_INSTR_BREADY (M_AXI_INSTR_BREADY),

        .M_AXI_INSTR_ARADDR (M_AXI_INSTR_ARADDR),
        .M_AXI_INSTR_ARLEN  (M_AXI_INSTR_ARLEN),
        .M_AXI_INSTR_ARVALID(M_AXI_INSTR_ARVALID),
        .M_AXI_INSTR_ARREADY(M_AXI_INSTR_ARREADY),

        .M_AXI_INSTR_RDATA  (M_AXI_INSTR_RDATA),
        .M_AXI_INSTR_RLAST  (M_AXI_INSTR_RLAST),
        .M_AXI_INSTR_RVALID (M_AXI_INSTR_RVALID),
        .M_AXI_INSTR_RREADY (M_AXI_INSTR_RREADY),

        // AXI data master
        .M_AXI_DATA_AWADDR (M_AXI_DATA_AWADDR),
        .M_AXI_DATA_AWLEN  (M_AXI_DATA_AWLEN),
        .M_AXI_DATA_AWVALID(M_AXI_DATA_AWVALID),
        .M_AXI_DATA_AWREADY(M_AXI_DATA_AWREADY),

        .M_AXI_DATA_WDATA  (M_AXI_DATA_WDATA),
        .M_AXI_DATA_WVALID (M_AXI_DATA_WVALID),
        .M_AXI_DATA_WLAST  (M_AXI_DATA_WLAST),
        .M_AXI_DATA_WREADY (M_AXI_DATA_WREADY),

        .M_AXI_DATA_BRESP  (M_AXI_DATA_BRESP),
        .M_AXI_DATA_BVALID (M_AXI_DATA_BVALID),
        .M_AXI_DATA_BREADY (M_AXI_DATA_BREADY),

        .M_AXI_DATA_ARADDR (M_AXI_DATA_ARADDR),
        .M_AXI_DATA_ARLEN  (M_AXI_DATA_ARLEN),
        .M_AXI_DATA_ARVALID(M_AXI_DATA_ARVALID),
        .M_AXI_DATA_ARREADY(M_AXI_DATA_ARREADY),

        .M_AXI_DATA_RDATA  (M_AXI_DATA_RDATA),
        .M_AXI_DATA_RLAST  (M_AXI_DATA_RLAST),
        .M_AXI_DATA_RVALID (M_AXI_DATA_RVALID),
        .M_AXI_DATA_RREADY (M_AXI_DATA_RREADY)
    );


    //======================================================================
    //  AXI Slave for Instruction Memory (Simplified)
    //======================================================================
    axi_slave_module #(
        .C_S_AXI_ID_WIDTH    (1),
        .C_S_AXI_DATA_WIDTH  (32),
        .C_S_AXI_ADDR_WIDTH  (32),
        .C_S_AXI_AWUSER_WIDTH(0),
        .C_S_AXI_ARUSER_WIDTH(0),
        .C_S_AXI_WUSER_WIDTH (0),
        .C_S_AXI_RUSER_WIDTH (0),
        .C_S_AXI_BUSER_WIDTH (0),
        .C_S_RAM_DEPTH       (256)
    ) instr_ram (
        .S_AXI_ACLK     (clk),
        .S_AXI_ARESETN  (resetn),

        .S_AXI_AWID     (1'b0),
        .S_AXI_AWADDR   (M_AXI_INSTR_AWADDR),
        .S_AXI_AWLEN    (M_AXI_INSTR_AWLEN),
        .S_AXI_AWSIZE   (3'd2),
        .S_AXI_AWBURST  (2'b01),
        .S_AXI_AWLOCK   (1'b0),
        .S_AXI_AWCACHE  (4'b0010),
        .S_AXI_AWPROT   (3'b000),
        .S_AXI_AWQOS    (4'b0000),
        .S_AXI_AWREGION (4'b0000),
        .S_AXI_AWUSER   (1'b0),
        .S_AXI_AWVALID  (M_AXI_INSTR_AWVALID),
        .S_AXI_AWREADY  (M_AXI_INSTR_AWREADY),

        .S_AXI_WDATA    (M_AXI_INSTR_WDATA),
        .S_AXI_WSTRB    (4'b1111),
        .S_AXI_WLAST    (M_AXI_INSTR_WLAST),
        .S_AXI_WUSER    (1'b0),
        .S_AXI_WVALID   (M_AXI_INSTR_WVALID),
        .S_AXI_WREADY   (M_AXI_INSTR_WREADY),

        .S_AXI_BID      (),
        .S_AXI_BRESP    (M_AXI_INSTR_BRESP),
        .S_AXI_BUSER    (),
        .S_AXI_BVALID   (M_AXI_INSTR_BVALID),
        .S_AXI_BREADY   (M_AXI_INSTR_BREADY),

        .S_AXI_ARID     (1'b0),
        .S_AXI_ARADDR   (M_AXI_INSTR_ARADDR),
        .S_AXI_ARLEN    (M_AXI_INSTR_ARLEN),
        .S_AXI_ARSIZE   (3'd2),
        .S_AXI_ARBURST  (2'b01),
        .S_AXI_ARLOCK   (1'b0),
        .S_AXI_ARCACHE  (4'b0010),
        .S_AXI_ARPROT   (3'b000),
        .S_AXI_ARQOS    (4'b0000),
        .S_AXI_ARREGION (4'b0000),
        .S_AXI_ARUSER   (1'b0),
        .S_AXI_ARVALID  (M_AXI_INSTR_ARVALID),
        .S_AXI_ARREADY  (M_AXI_INSTR_ARREADY),

        .S_AXI_RID      (),
        .S_AXI_RDATA    (M_AXI_INSTR_RDATA),
        .S_AXI_RRESP    (),
        .S_AXI_RLAST    (M_AXI_INSTR_RLAST),
        .S_AXI_RUSER    (),
        .S_AXI_RVALID   (M_AXI_INSTR_RVALID),
        .S_AXI_RREADY   (M_AXI_INSTR_RREADY)
    );


    //======================================================================
    //  AXI Slave for Data Memory (Simplified)
    //======================================================================
    axi_slave_module #(
        .C_S_AXI_ID_WIDTH    (1),
        .C_S_AXI_DATA_WIDTH  (32),
        .C_S_AXI_ADDR_WIDTH  (32),
        .C_S_AXI_AWUSER_WIDTH(0),
        .C_S_AXI_ARUSER_WIDTH(0),
        .C_S_AXI_WUSER_WIDTH (0),
        .C_S_AXI_RUSER_WIDTH (0),
        .C_S_AXI_BUSER_WIDTH (0),
        .C_S_RAM_DEPTH       (256)
    ) data_ram (
        .S_AXI_ACLK     (clk),
        .S_AXI_ARESETN  (resetn),

        .S_AXI_AWID     (1'b0),
        .S_AXI_AWADDR   (M_AXI_DATA_AWADDR),
        .S_AXI_AWLEN    (M_AXI_DATA_AWLEN),
        .S_AXI_AWSIZE   (3'd2),
        .S_AXI_AWBURST  (2'b01),
        .S_AXI_AWLOCK   (1'b0),
        .S_AXI_AWCACHE  (4'b0010),
        .S_AXI_AWPROT   (3'b000),
        .S_AXI_AWQOS    (4'b0000),
        .S_AXI_AWREGION (4'b0000),
        .S_AXI_AWUSER   (1'b0),
        .S_AXI_AWVALID  (M_AXI_DATA_AWVALID),
        .S_AXI_AWREADY  (M_AXI_DATA_AWREADY),

        .S_AXI_WDATA    (M_AXI_DATA_WDATA),
        .S_AXI_WSTRB    (4'b1111),
        .S_AXI_WLAST    (M_AXI_DATA_WLAST),
        .S_AXI_WUSER    (1'b0),
        .S_AXI_WVALID   (M_AXI_DATA_WVALID),
        .S_AXI_WREADY   (M_AXI_DATA_WREADY),

        .S_AXI_BID      (),
        .S_AXI_BRESP    (M_AXI_DATA_BRESP),
        .S_AXI_BUSER    (),
        .S_AXI_BVALID   (M_AXI_DATA_BVALID),
        .S_AXI_BREADY   (M_AXI_DATA_BREADY),

        .S_AXI_ARID     (1'b0),
        .S_AXI_ARADDR   (M_AXI_DATA_ARADDR),
        .S_AXI_ARLEN    (M_AXI_DATA_ARLEN),
        .S_AXI_ARSIZE   (3'd2),
        .S_AXI_ARBURST  (2'b01),
        .S_AXI_ARLOCK   (1'b0),
        .S_AXI_ARCACHE  (4'b0010),
        .S_AXI_ARPROT   (3'b000),
        .S_AXI_ARQOS    (4'b0000),
        .S_AXI_ARREGION (4'b0000),
        .S_AXI_ARUSER   (1'b0),
        .S_AXI_ARVALID  (M_AXI_DATA_ARVALID),
        .S_AXI_ARREADY  (M_AXI_DATA_ARREADY),

        .S_AXI_RID      (),
        .S_AXI_RDATA    (M_AXI_DATA_RDATA),
        .S_AXI_RRESP    (),
        .S_AXI_RLAST    (M_AXI_DATA_RLAST),
        .S_AXI_RUSER    (),
        .S_AXI_RVALID   (M_AXI_DATA_RVALID),
        .S_AXI_RREADY   (M_AXI_DATA_RREADY)
    );


    //======================================================================
    //  Testbench Logic
    //======================================================================
    initial begin
        clk = 0;
        resetn = 0;
        rf_addr = 0;

        // Wait a bit before releasing reset
        #100;
        resetn = 1;
        
        $display("Time=%0t: Reset released", $time);
        $display("Initial PC: %h", IF_pc);
        $display("Initial Inst: %h", IF_inst);
        
        // Run simulation for 5000 time units to see more instructions
        #5000;
        
        // Check final state
        $display("\n======== Simulation Summary ========");
        $display("Final PC: %h", IF_pc);
        $display("Final Inst: %h", IF_inst);
        $display("Pipeline Status: IF=%b ID=%b EXE=%b MEM=%b WB=%b", 
                 uut.IF_valid, uut.ID_valid, uut.EXE_valid, uut.MEM_valid, uut.WB_valid);
        $display("====================================\n");
        
        // End simulation
        $finish;
    end

    always #5 clk = ~clk;

    // Monitor important signals
    initial begin
        $monitor("Time=%0t | PC=%h Inst=%h | IF_v=%b IF_over=%b IF_allow=%b | ID_v=%b ID_over=%b ID_allow=%b | EXE_v=%b EXE_allow=%b | MEM_v=%b MEM_allow=%b | WB_v=%b WB_allow=%b | axi_start=%b axi_done=%b axi_busy=%b | fetch_state=%d", 
                 $time, IF_pc, IF_inst, 
                 uut.IF_valid, uut.IF_over, uut.IF_allow_in,
                 uut.ID_valid, uut.ID_over, uut.ID_allow_in,
                 uut.EXE_valid, uut.EXE_allow_in,
                 uut.MEM_valid, uut.MEM_allow_in,
                 uut.WB_valid, uut.WB_allow_in,
                 uut.IF_module.axi_start, uut.IF_module.axi_done, uut.IF_module.axi_busy,
                 uut.IF_module.current_state);
    end

endmodule