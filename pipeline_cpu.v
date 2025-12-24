`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: pipeline_cpu.v
//   > 描述  :五级流水CPU模块，共实现XX条指令
//   >        指令rom和数据ram均实例化xilinx IP得到，为同步读写
//   > 作者  : LOONGSON
//   > 日期  : 2016-04-14
//*************************************************************************

`define IF_ID_BUS_WIDTH     64
`define ID_EXE_BUS_WIDTH    168
`define EXE_MEM_BUS_WIDTH   155
`define MEM_WB_BUS_WIDTH    156
`define JBR_BUS_WIDTH       33
`define EXC_BUS_WIDTH       33


module pipeline_cpu(
    input clk,
    input resetn,

    // display
    input  [4:0] rf_addr,
    output [31:0] rf_data,
    output [31:0] IF_pc,
    output [31:0] IF_inst,
    output [31:0] ID_pc,
    output [31:0] EXE_pc,
    output [31:0] MEM_pc,
    output [31:0] WB_pc,

    // debug
    output [31:0] cpu_5_valid,
    output [31:0] HI_data,
    output [31:0] LO_data,
    output [31:0] CP0_STATUS,
    output [31:0] CP0_CAUSE,
    output [31:0] CP0_EPC,

    //==================================================
    // AXI MASTER (INSTR)
    //==================================================
    output [31:0] M_AXI_INSTR_AWADDR,
    output [7:0]  M_AXI_INSTR_AWLEN,
    output        M_AXI_INSTR_AWVALID,
    input         M_AXI_INSTR_AWREADY,

    output [31:0] M_AXI_INSTR_WDATA,
    output        M_AXI_INSTR_WVALID,
    output        M_AXI_INSTR_WLAST,
    input         M_AXI_INSTR_WREADY,

    input  [1:0]  M_AXI_INSTR_BRESP,
    input         M_AXI_INSTR_BVALID,
    output        M_AXI_INSTR_BREADY,

    output [31:0] M_AXI_INSTR_ARADDR,
    output [7:0]  M_AXI_INSTR_ARLEN,
    output        M_AXI_INSTR_ARVALID,
    input         M_AXI_INSTR_ARREADY,

    input  [31:0] M_AXI_INSTR_RDATA,
    input         M_AXI_INSTR_RLAST,
    input         M_AXI_INSTR_RVALID,
    output        M_AXI_INSTR_RREADY,

    output [2:0]  M_AXI_INSTR_AWSIZE,
    output [2:0]  M_AXI_INSTR_ARSIZE,

    //==================================================
    // AXI MASTER (DATA)
    //==================================================
    output [31:0] M_AXI_DATA_AWADDR,
    output [7:0]  M_AXI_DATA_AWLEN,
    output        M_AXI_DATA_AWVALID,
    input         M_AXI_DATA_AWREADY,

    output [31:0] M_AXI_DATA_WDATA,
    output        M_AXI_DATA_WVALID,
    output        M_AXI_DATA_WLAST,
    input         M_AXI_DATA_WREADY,

    input  [1:0]  M_AXI_DATA_BRESP,
    input         M_AXI_DATA_BVALID,
    output        M_AXI_DATA_BREADY,

    output [31:0] M_AXI_DATA_ARADDR,
    output [7:0]  M_AXI_DATA_ARLEN,
    output        M_AXI_DATA_ARVALID,
    input         M_AXI_DATA_ARREADY,

    input  [31:0] M_AXI_DATA_RDATA,
    input         M_AXI_DATA_RLAST,
    input         M_AXI_DATA_RVALID,
    output        M_AXI_DATA_RREADY,

    output [2:0]  M_AXI_DATA_AWSIZE,
    output [2:0]  M_AXI_DATA_ARSIZE
);

// FETCH AXI user signals
wire        icache_req;
wire [31:0] icache_addr;
wire        icache_ready;
wire        icache_resp_valid;
wire [31:0] icache_inst;
wire        icache_axi_start;
wire [31:0] icache_axi_addr;
wire [7:0]  icache_axi_len;


// MEM AXI user signals
wire        mem_axi_start;
wire        mem_axi_rw;       // 1=load, 0=store
wire [31:0] mem_axi_addr;
wire [31:0] mem_axi_wdata;
wire [7:0]  mem_axi_len;
wire        mem_axi_wvalid;
wire        mem_axi_wready;
// debug for data AXI
always @(posedge clk) begin
    if (mem_axi_start) begin
        $display("PIPE_AXI_DATA: start rw=%b addr=%h len=%0d", mem_axi_rw, mem_axi_addr, mem_axi_len);
    end
end
// --------------------------------
// AXI MASTER FOR INSTRUCTION FETCH
//-------------------------------------------------------
wire instr_user_busy;
wire instr_user_done;
wire instr_user_rvalid;
// debug for instr AXI
always @(posedge clk) begin
    if (icache_axi_start) begin
        $display("PIPE_AXI_INSTR: start addr=%h len=%0d", icache_axi_addr, icache_axi_len);
    end
end
wire [31:0] instr_user_rdata;

axi_full_master #(
    .C_M_TARGET_SLAVE_BASE_ADDR(32'h00000000)
) U_AXI_INSTR (
    .M_AXI_ACLK(clk),
    .M_AXI_ARESETN(resetn),

    // AXI 总线输出
    .M_AXI_AWID(),
    .M_AXI_AWADDR(M_AXI_INSTR_AWADDR),
    .M_AXI_AWLEN (M_AXI_INSTR_AWLEN),
    // .M_AXI_AWSIZE(),
    // .M_AXI_AWBURST(),
    .M_AXI_AWLOCK(),
    .M_AXI_AWCACHE(),
    .M_AXI_AWPROT(),
    .M_AXI_AWQOS(),
    .M_AXI_AWUSER(),
    .M_AXI_AWVALID(M_AXI_INSTR_AWVALID),
    .M_AXI_AWREADY(M_AXI_INSTR_AWREADY),

    .M_AXI_AWSIZE(M_AXI_INSTR_AWSIZE),
    .M_AXI_ARSIZE(M_AXI_INSTR_ARSIZE),

    .M_AXI_WDATA(M_AXI_INSTR_WDATA),
    .M_AXI_WSTRB(),
    .M_AXI_WLAST(M_AXI_INSTR_WLAST),
    .M_AXI_WUSER(),
    .M_AXI_WVALID(M_AXI_INSTR_WVALID),
    .M_AXI_WREADY(M_AXI_INSTR_WREADY),

    .M_AXI_BID(),
    .M_AXI_BRESP(M_AXI_INSTR_BRESP),
    .M_AXI_BUSER(),
    .M_AXI_BVALID(M_AXI_INSTR_BVALID),
    .M_AXI_BREADY(M_AXI_INSTR_BREADY),

    .M_AXI_ARID(),
    .M_AXI_ARADDR(M_AXI_INSTR_ARADDR),
    .M_AXI_ARLEN (M_AXI_INSTR_ARLEN),
    // .M_AXI_ARSIZE(),
    // .M_AXI_ARBURST(),
    .M_AXI_ARLOCK(),
    .M_AXI_ARCACHE(),
    .M_AXI_ARPROT(),
    .M_AXI_ARQOS(),
    .M_AXI_ARUSER(),
    .M_AXI_ARVALID(M_AXI_INSTR_ARVALID),
    .M_AXI_ARREADY(M_AXI_INSTR_ARREADY),

    .M_AXI_RID(),
    .M_AXI_RDATA(M_AXI_INSTR_RDATA),
    .M_AXI_RRESP(),
    .M_AXI_RLAST(M_AXI_INSTR_RLAST),
    .M_AXI_RUSER(),
    .M_AXI_RVALID(M_AXI_INSTR_RVALID),
    .M_AXI_RREADY(M_AXI_INSTR_RREADY),

    //---------------------------------------------------
    // USER 控制接口（Fetch 使用）
    //---------------------------------------------------
    .user_start   (icache_axi_start), 
    .user_rw      (1'b1),            // 固定为 read
    .user_addr    (icache_axi_addr),      // fetch.v 中的 PC
    .user_len     (icache_axi_len),            // 每次读1个指令

    .user_wdata   (32'd0),           // 不会用到
    .user_wvalid  (1'b0),
    .user_wready  (),

    .user_rdata   (instr_user_rdata),
    .user_rvalid  (instr_user_rvalid),
    .user_rready  (1'b1),

    .user_busy    (instr_user_busy),
    .user_done    (instr_user_done),
    .user_error   ()
);

//-------------------------------------------------------
// AXI MASTER FOR DATA LOAD/STORE
//-------------------------------------------------------
wire data_user_busy;
wire data_user_done;
wire [31:0] data_user_rdata;
wire data_user_rvalid;

axi_full_master #(
    .C_M_TARGET_SLAVE_BASE_ADDR(32'h00000000)
) U_AXI_DATA (
    .M_AXI_ACLK(clk),
    .M_AXI_ARESETN(resetn),

    // AXI 总线输出
    .M_AXI_AWID(),
    .M_AXI_AWADDR(M_AXI_DATA_AWADDR),
    .M_AXI_AWLEN (M_AXI_DATA_AWLEN),
    // .M_AXI_AWSIZE(),
    // .M_AXI_AWBURST(),
    .M_AXI_AWLOCK(),
    .M_AXI_AWCACHE(),
    .M_AXI_AWPROT(),
    .M_AXI_AWQOS(),
    .M_AXI_AWUSER(),
    .M_AXI_AWVALID(M_AXI_DATA_AWVALID),
    .M_AXI_AWREADY(M_AXI_DATA_AWREADY),

    .M_AXI_AWSIZE(M_AXI_DATA_AWSIZE),
    .M_AXI_ARSIZE(M_AXI_DATA_ARSIZE),

    .M_AXI_WDATA(M_AXI_DATA_WDATA),
    .M_AXI_WSTRB(),
    .M_AXI_WLAST(M_AXI_DATA_WLAST),
    .M_AXI_WUSER(),
    .M_AXI_WVALID(M_AXI_DATA_WVALID),
    .M_AXI_WREADY(M_AXI_DATA_WREADY),

    .M_AXI_BID(),
    .M_AXI_BRESP(M_AXI_DATA_BRESP),
    .M_AXI_BUSER(),
    .M_AXI_BVALID(M_AXI_DATA_BVALID),
    .M_AXI_BREADY(M_AXI_DATA_BREADY),

    .M_AXI_ARID(),
    .M_AXI_ARADDR(M_AXI_DATA_ARADDR),
    .M_AXI_ARLEN (M_AXI_DATA_ARLEN),
    // .M_AXI_ARSIZE(),
    // .M_AXI_ARBURST(),
    .M_AXI_ARLOCK(),
    .M_AXI_ARCACHE(),
    .M_AXI_ARPROT(),
    .M_AXI_ARQOS(),
    .M_AXI_ARUSER(),
    .M_AXI_ARVALID(M_AXI_DATA_ARVALID),
    .M_AXI_ARREADY(M_AXI_DATA_ARREADY),

    .M_AXI_RID(),
    .M_AXI_RDATA(M_AXI_DATA_RDATA),
    .M_AXI_RRESP(),
    .M_AXI_RLAST(M_AXI_DATA_RLAST),
    .M_AXI_RUSER(),
    .M_AXI_RVALID(M_AXI_DATA_RVALID),
    .M_AXI_RREADY(M_AXI_DATA_RREADY),

    //---------------------------------------------------
    // USER 接口 (mem 使用)
    //---------------------------------------------------
    .user_start   (mem_axi_start),
    .user_rw      (mem_axi_rw),        // 0 = store, 1 = load
    .user_addr    (mem_axi_addr),
    .user_len     (mem_axi_len),

    .user_wdata   (mem_axi_wdata),
    .user_wvalid  (mem_axi_wvalid),
    .user_wready  (mem_axi_wready),

    .user_rdata   (data_user_rdata),
    .user_rvalid  (data_user_rvalid),
    .user_rready  (1'b1),

    .user_busy    (data_user_busy),
    .user_done    (data_user_done),
    .user_error   ()
);



//------------------------{5级流水控制信号}begin-------------------------//
    //5模块的valid信号
    reg IF_valid;
    reg ID_valid;
    reg EXE_valid;
    reg MEM_valid;
    reg WB_valid;
    //5模块执行完成信号,来自各模块的输出
    wire IF_over;
    wire ID_over;
    wire EXE_over;
    wire MEM_over;
    wire WB_over;
    //5模块允许下一级指令进入
    wire IF_allow_in;
    wire ID_allow_in;
    wire EXE_allow_in;
    wire MEM_allow_in;
    wire WB_allow_in;
    
    // syscall和eret到达写回级时会发出cancel信号，
    wire cancel;    // 取消已经取出的正在其他流水级执行的指令
    
    //各级允许进入信号:本级无效，或本级执行完成且下级允许进入
    assign IF_allow_in  = (IF_over & ID_allow_in) | cancel;
    assign ID_allow_in  = ~ID_valid  | (ID_over  & EXE_allow_in);
    assign EXE_allow_in = ~EXE_valid | (EXE_over & MEM_allow_in);
    assign MEM_allow_in = ~MEM_valid | (MEM_over & WB_allow_in );
    assign WB_allow_in  = ~WB_valid  | WB_over;
   
    //IF_valid，在复位后，一直有效
   always @(posedge clk)
    begin
        if (!resetn)
        begin
            IF_valid <= 1'b0;
        end
        else
        begin
            IF_valid <= 1'b1;
        end
    end
    
    //ID_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            ID_valid <= 1'b0;
        end
        else if (ID_allow_in)
        begin
            ID_valid <= IF_over;
        end
    end
    
    //EXE_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            EXE_valid <= 1'b0;
        end
        else if (EXE_allow_in)
        begin
            EXE_valid <= ID_over;
        end
    end
    
    //MEM_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            MEM_valid <= 1'b0;
        end
        else if (MEM_allow_in)
        begin
            MEM_valid <= EXE_over;
        end
    end
    
    //WB_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            WB_valid <= 1'b0;
        end
        else if (WB_allow_in)
        begin
            WB_valid <= MEM_over;
        end
    end
    
    //展示5级的valid信号
    assign cpu_5_valid = {12'd0         ,{4{IF_valid }},{4{ID_valid}},
                          {4{EXE_valid}},{4{MEM_valid}},{4{WB_valid}}};
//-------------------------{5级流水控制信号}end--------------------------//

//--------------------------{5级间的总线}begin---------------------------//
    wire [ 63:0] IF_ID_bus;   // IF->ID级总线
    wire [167:0] ID_EXE_bus;  // ID->EXE级总线
    wire [154:0] EXE_MEM_bus; // EXE->MEM级总线
    wire [155:0] MEM_WB_bus;  // MEM->WB级总线
    
    //锁存以上总线信号
    reg [ 63:0] IF_ID_bus_r;
    reg [167:0] ID_EXE_bus_r;
    reg [154:0] EXE_MEM_bus_r;
    reg [155:0] MEM_WB_bus_r;
    
    //IF到ID的锁存信号
    always @(posedge clk)
    begin
        if(IF_over && ID_allow_in)
        begin
            IF_ID_bus_r <= IF_ID_bus;
        end
    end
    //ID到EXE的锁存信号
    always @(posedge clk)
    begin
        if(ID_over && EXE_allow_in)
        begin
            ID_EXE_bus_r <= ID_EXE_bus;
        end
    end
    //EXE到MEM的锁存信号
    always @(posedge clk)
    begin
        if(EXE_over && MEM_allow_in)
        begin
            EXE_MEM_bus_r <= EXE_MEM_bus;
        end
    end    
    //MEM到WB的锁存信号
    always @(posedge clk)
    begin
        if(MEM_over && WB_allow_in)
        begin
            MEM_WB_bus_r <= MEM_WB_bus;
        end
    end
//---------------------------{5级间的总线}end----------------------------//

//------------------------{旁路相关信号}begin---------------------------//

    // 旁路数据信号
    wire [31:0] EXE_result;    // EXE级结果
    wire [31:0] MEM_result;    // MEM级结果  
    wire [31:0] WB_result;     // WB级结果
    
    // 旁路控制信号
    wire [4:0] EXE_wdest;      // EXE级写回目标寄存器
    wire [4:0] MEM_wdest;      // MEM级写回目标寄存器
    wire [4:0] WB_wdest;       // WB级写回目标寄存器
    
    // EXE级指令类型信息
    wire EXE_inst_load;        // EXE级Load指令
    wire EXE_inst_mult;        // EXE级乘法指令
    
//------------------------{旁路相关信号}end----------------------------//

//--------------------------{其他交互信号}begin--------------------------//
    //跳转总线
    wire [ 32:0] jbr_bus;    

    //IF与inst_rom交互
    // wire [31:0] inst_addr;
    // wire [31:0] inst;

    //ID与EXE、MEM、WB交互
    wire [ 4:0] EXE_wdest;
    wire [ 4:0] MEM_wdest;
    wire [ 4:0] WB_wdest;
    
    //MEM与data_ram交互    
    // wire [ 3:0] dm_wen;
    // wire [31:0] dm_addr;
    // wire [31:0] dm_wdata;
    // wire [31:0] dm_rdata;

    //ID与regfile交互
    wire [ 4:0] rs;
    wire [ 4:0] rt;   
    wire [31:0] rs_value;
    wire [31:0] rt_value;
    
    //WB与regfile交互
    wire        rf_wen;
    wire [ 4:0] rf_wdest;
    wire [31:0] rf_wdata;    
    
    //WB与IF间的交互信号
    wire [ 32:0] exc_bus;
//---------------------------{其他交互信号}end---------------------------//

//-------------------------{各模块实例化}begin---------------------------//
    wire next_fetch; //即将运行取指模块，需要先锁存PC值
    //IF允许进入时，即锁存PC值，取下一条指令
    assign next_fetch = IF_allow_in;
    fetch IF_module(             // 取指级
        .clk       (clk       ),  // I, 1
        .resetn    (resetn    ),  // I, 1
        .IF_valid  (IF_valid  ),  // I, 1
        .next_fetch(next_fetch),  // I, 1
        // .inst      (inst      ),  // I, 32
        .jbr_bus   (jbr_bus   ),  // I, 33
        // .inst_addr (inst_addr ),  // O, 32
        .IF_over   (IF_over   ),  // O, 1
        .IF_ID_bus (IF_ID_bus ),  // O, 64

        .icache_req   (icache_req),
        .icache_addr  (icache_addr),
        .icache_ready (icache_ready),
        .icache_resp_valid (icache_resp_valid),
        .icache_inst  (icache_inst),
        
        //5级流水新增接口
        .exc_bus   (exc_bus   ),  // I, 32
        
        //展示PC和取出的指令
        .IF_pc     (IF_pc     ),  // O, 32
        .IF_inst   (IF_inst   )   // O, 32
    );
    icache_simple ICache_module(
        .clk        (clk),
        .resetn     (resetn),
        .req_valid  (icache_req),
        .req_addr   (icache_addr),
        .req_ready  (icache_ready),
        .resp_valid (icache_resp_valid),
        .resp_inst  (icache_inst),
        .axi_start  (icache_axi_start),
        .axi_addr   (icache_axi_addr),
        .axi_len    (icache_axi_len),
        .axi_rdata  (instr_user_rdata),
        .axi_rvalid (instr_user_rvalid),
        .axi_done   (instr_user_done),
        .axi_busy   (instr_user_busy)
    );


    // inst = axi_rdata;
    // IF_over = axi_done;

    decode ID_module(               // 译码级
        .clk        (clk        ),  // I, 1
        .ID_valid   (ID_valid   ),  // I, 1
        .IF_ID_bus_r(IF_ID_bus_r),  // I, 64
        .rs_value   (rs_value   ),  // I, 32
        .rt_value   (rt_value   ),  // I, 32
        .rs         (rs         ),  // O, 5
        .rt         (rt         ),  // O, 5
        .jbr_bus    (jbr_bus    ),  // O, 33
//        .inst_jbr   (inst_jbr   ),  // O, 1
        .ID_over    (ID_over    ),  // O, 1
        .ID_EXE_bus (ID_EXE_bus ),  // O, 167
        
        //5级流水新增
        .IF_over     (IF_over     ),// I, 1
        .EXE_wdest   (EXE_wdest   ),// I, 5
        .MEM_wdest   (MEM_wdest   ),// I, 5
        .WB_wdest    (WB_wdest    ),// I, 5

        // 旁路：
        .EXE_result(EXE_result),  // I, 32
        .MEM_result(MEM_result),  // I, 32
        .WB_result(WB_result),    // I, 32

        .EXE_valid(EXE_valid),    // I, 1
        .MEM_valid(MEM_valid),    // I, 1
        .WB_valid(WB_valid),      // I, 1
        
        // EXE级指令类型信息
        .EXE_inst_load(EXE_inst_load),  // I, 1
        .EXE_inst_mult(EXE_inst_mult),  // I, 1
        
        //展示PC
        .ID_pc       (ID_pc       ) // O, 32
    ); 

    exe EXE_module(                   // 执行级
        .EXE_valid   (EXE_valid   ),  // I, 1
        .ID_EXE_bus_r(ID_EXE_bus_r),  // I, 167
        .EXE_over    (EXE_over    ),  // O, 1 
        .EXE_MEM_bus (EXE_MEM_bus ),  // O, 154
        
        //5级流水新增
        .clk         (clk         ),  // I, 1
        .EXE_wdest   (EXE_wdest   ),  // O, 5

        // 旁路结果输出：
        .EXE_result(EXE_result),  // O, 32
        
        // EXE级指令类型信息输出
        .EXE_inst_load(EXE_inst_load),  // O, 1
        .EXE_inst_mult(EXE_inst_mult),  // O, 1
        
        //展示PC
        .EXE_pc      (EXE_pc      )   // O, 32
    );

    mem MEM_module(                     // 访存级
        .clk          (clk          ),  // I, 1 
        .MEM_valid    (MEM_valid    ),  // I, 1
        .EXE_MEM_bus_r(EXE_MEM_bus_r),  // I, 155
        // .dm_rdata     (dm_rdata     ),  // I, 32
        // .dm_addr      (dm_addr      ),  // O, 32
        // .dm_wen       (dm_wen       ),  // O, 4 
        // .dm_wdata     (dm_wdata     ),  // O, 32
        .MEM_over     (MEM_over     ),  // O, 1
        .MEM_WB_bus   (MEM_WB_bus   ),  // O, 156
        
        //5级流水新增接口
        .MEM_allow_in (MEM_allow_in ),  // I, 1
        .MEM_wdest    (MEM_wdest    ),  // O, 5

        // 新增旁路数据输出
        .MEM_result(MEM_result),  // O, 32
        
        .axi_start   (mem_axi_start),
        .axi_rw      (mem_axi_rw),
        .axi_addr    (mem_axi_addr),
        .axi_len     (mem_axi_len),
        .axi_wdata   (mem_axi_wdata),

        .axi_rdata   (data_user_rdata),
        .axi_rvalid  (data_user_rvalid),
        .axi_done    (data_user_done),
        .axi_busy    (data_user_busy),
        .axi_wvalid  (mem_axi_wvalid),
        .axi_wready  (mem_axi_wready),

        //展示PC
        .MEM_pc       (MEM_pc       )   // O, 32
    );          
 
    wb WB_module(                     // 写回级
        .WB_valid    (WB_valid    ),  // I, 1
        .MEM_WB_bus_r(MEM_WB_bus_r),  // I, 156
        .rf_wen      (rf_wen      ),  // O, 1
        .rf_wdest    (rf_wdest    ),  // O, 5
        .rf_wdata    (rf_wdata    ),  // O, 32
          .WB_over     (WB_over     ),  // O, 1
        
        //5级流水新增接口
        .clk         (clk         ),  // I, 1
      .resetn      (resetn      ),  // I, 1
        .exc_bus     (exc_bus     ),  // O, 32
        .WB_wdest    (WB_wdest    ),  // O, 5
        .cancel      (cancel      ),  // O, 1
        
        // 新增旁路数据输出
        .WB_result(WB_result),  // O, 32
        
        //展示PC和HI/LO值
        .WB_pc       (WB_pc       ),  // O, 32
        .HI_data     (HI_data     ),  // O, 32
        .LO_data     (LO_data     ),  // O, 32
        // 导出CP0寄存器
        .cp0_status  (CP0_STATUS  ),  // O, 32
        .cp0_cause   (CP0_CAUSE   ),  // O, 32
        .cp0_epc     (CP0_EPC     )   // O, 32
    );

    // inst_rom inst_rom_module(         // 指令存储器
    //     .clka       (clk           ),  // I, 1 ,时钟
    //     .addra      (inst_addr[9:2]),  // I, 8 ,指令地址
    //     .douta      (inst          )   // O, 32,指令
    // );

    regfile rf_module(        // 寄存器堆模块
        .clk    (clk      ),  // I, 1
        .wen    (rf_wen   ),  // I, 1
        .raddr1 (rs       ),  // I, 5
        .raddr2 (rt       ),  // I, 5
        .waddr  (rf_wdest ),  // I, 5
        .wdata  (rf_wdata ),  // I, 32
        .rdata1 (rs_value ),  // O, 32
        .rdata2 (rt_value ),  // O, 32

        //display rf
        .test_addr(rf_addr),  // I, 5
        .test_data(rf_data)   // O, 32
    );
    
    // data_ram data_ram_module(   // 数据存储模块
    //     .clka   (clk         ),  // I, 1,  时钟
    //     .wea    (dm_wen      ),  // I, 1,  写使能
    //     .addra  (dm_addr[9:2]),  // I, 8,  读地址
    //     .dina   (dm_wdata    ),  // I, 32, 写数据
    //     .douta  (dm_rdata    ),  // O, 32, 读数据

    //     //display mem
    //     .clkb   (clk          ),  // I, 1,  时钟
    //     .web    (4'd0         ),  // 不使用端口2的写功能
    //     .addrb  (mem_addr[9:2]),  // I, 8,  读地址
    //     .doutb  (mem_data     ),  // I, 32, 写数据
    //     .dinb   (32'd0        )   // 不使用端口2的写功能
    // );
//--------------------------{各模块实例化}end----------------------------//
endmodule
