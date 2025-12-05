module axi_slave_module#
(
    parameter                                   C_S_AXI_ID_WIDTH      = 1,
    parameter                                   C_S_AXI_DATA_WIDTH    = 32,
    parameter                                   C_S_AXI_ADDR_WIDTH    = 32,
    parameter                                   C_S_AXI_AWUSER_WIDTH  = 0,
    parameter                                   C_S_AXI_ARUSER_WIDTH  = 0,
    parameter                                   C_S_AXI_WUSER_WIDTH   = 0,
    parameter                                   C_S_AXI_RUSER_WIDTH   = 0,
    parameter                                   C_S_AXI_BUSER_WIDTH   = 0,

    // RAM 深度（单位：word），必须是 2 的幂
    parameter                                   C_S_RAM_DEPTH         = 256
)
(
    input  wire                                 S_AXI_ACLK      ,
    input  wire                                 S_AXI_ARESETN   ,

    input  wire [C_S_AXI_ID_WIDTH-1 : 0]        S_AXI_AWID      ,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]      S_AXI_AWADDR    ,
    input  wire [7 : 0]                         S_AXI_AWLEN     ,
    input  wire [2 : 0]                         S_AXI_AWSIZE    ,
    input  wire [1 : 0]                         S_AXI_AWBURST   ,
    input  wire                                 S_AXI_AWLOCK    ,
    input  wire [3 : 0]                         S_AXI_AWCACHE   ,
    input  wire [2 : 0]                         S_AXI_AWPROT    ,
    input  wire [3 : 0]                         S_AXI_AWQOS     ,
    input  wire [3 : 0]                         S_AXI_AWREGION  ,
    input  wire [C_S_AXI_AWUSER_WIDTH-1 : 0]    S_AXI_AWUSER    ,
    input  wire                                 S_AXI_AWVALID   ,
    output wire                                 S_AXI_AWREADY   ,

    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]      S_AXI_WDATA     ,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]  S_AXI_WSTRB     ,
    input  wire                                 S_AXI_WLAST     ,
    input  wire [C_S_AXI_WUSER_WIDTH-1 : 0]     S_AXI_WUSER     ,
    input  wire                                 S_AXI_WVALID    ,
    output wire                                 S_AXI_WREADY    ,

    output wire [C_S_AXI_ID_WIDTH-1 : 0]        S_AXI_BID       ,
    output wire [1 : 0]                         S_AXI_BRESP     ,
    output wire [C_S_AXI_BUSER_WIDTH-1 : 0]     S_AXI_BUSER     ,
    output wire                                 S_AXI_BVALID    ,
    input  wire                                 S_AXI_BREADY    ,

    input  wire [C_S_AXI_ID_WIDTH-1 : 0]        S_AXI_ARID      ,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]      S_AXI_ARADDR    ,
    input  wire [7 : 0]                         S_AXI_ARLEN     ,
    input  wire [2 : 0]                         S_AXI_ARSIZE    ,
    input  wire [1 : 0]                         S_AXI_ARBURST   ,
    input  wire                                 S_AXI_ARLOCK    ,
    input  wire [3 : 0]                         S_AXI_ARCACHE   ,
    input  wire [2 : 0]                         S_AXI_ARPROT    ,
    input  wire [3 : 0]                         S_AXI_ARQOS     ,
    input  wire [3 : 0]                         S_AXI_ARREGION  ,
    input  wire [C_S_AXI_ARUSER_WIDTH-1 : 0]    S_AXI_ARUSER    ,
    input  wire                                 S_AXI_ARVALID   ,
    output wire                                 S_AXI_ARREADY   ,

    output wire [C_S_AXI_ID_WIDTH-1 : 0]        S_AXI_RID       ,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]      S_AXI_RDATA     ,
    output wire [1 : 0]                         S_AXI_RRESP     ,
    output wire                                 S_AXI_RLAST     ,
    output wire [C_S_AXI_RUSER_WIDTH-1 : 0]     S_AXI_RUSER     ,
    output wire                                 S_AXI_RVALID    ,
    input  wire                                 S_AXI_RREADY    
);

/********************** 工具函数 ***************************/
function integer clogb2;
    input integer number;
    integer i;
begin
    clogb2 = 0;
    for (i = number-1; i > 0; i = i >> 1)
        clogb2 = clogb2 + 1;
end
endfunction

localparam integer ADDR_LSB        = clogb2(C_S_AXI_DATA_WIDTH/8);    // 字节地址 → 字地址
localparam integer RAM_ADDR_WIDTH  = clogb2(C_S_RAM_DEPTH);

/********************** RAM ***************************/
reg [C_S_AXI_DATA_WIDTH-1:0] ram [0:C_S_RAM_DEPTH-1];

/********************** 通用整数索引 ***************************/
integer i;
integer idx;
integer idx_r;

initial begin
    ram[0]  = 32'hAC010000;
    ram[1]  = 32'hAC020004;
    ram[2]  = 32'hAC030008;
    ram[3]  = 32'hAC04000C;
    ram[4]  = 32'hAC050010;
    ram[5]  = 32'hAC060018;
    ram[6]  = 32'hAC070070;
    ram[7]  = 32'hAC190074;
    ram[8]  = 32'hAC0D0078;
    ram[9]  = 32'h40017000;
    ram[10] = 32'h24210004;
    ram[11] = 32'h40817000;
    ram[12] = 32'h42000018;
    ram[13] = 32'h24010001;
    ram[14] = 32'h00000000;
    ram[15] = 32'h00011100;
    ram[16] = 32'h00411821;
    ram[17] = 32'h00022082;
    ram[18] = 32'h28990005;
    ram[19] = 32'h0721000E;
    ram[20] = 32'h00642823;
    ram[21] = 32'hAC050014;
    ram[22] = 32'h00A23027;
    ram[23] = 32'h00C33825;
    ram[24] = 32'h00E64026;
    ram[25] = 32'h11030002;
    ram[26] = 32'hAC08001C;
    ram[27] = 32'h0022482A;
    ram[28] = 32'h8C0A001C;
    ram[29] = 32'h15450002;
    ram[30] = 32'h00415824;
    ram[31] = 32'hAC0B001C;
    ram[32] = 32'h0C000026;
    ram[33] = 32'hAC040010;
    ram[34] = 32'h3C0C000C;
    ram[35] = 32'h004CD007;
    ram[36] = 32'h275B0044;
    ram[37] = 32'h0360F809;
    ram[38] = 32'h24010008;
    ram[39] = 32'hA07A0005;
    ram[40] = 32'h0143682B;
    ram[41] = 32'h1DA00002;
    ram[42] = 32'h00867004;
    ram[43] = 32'h000E7883;
    ram[44] = 32'h002F8006;
    ram[45] = 32'h1A000007;
    ram[46] = 32'h002F8007;
    ram[47] = 32'h06000006;
    ram[48] = 32'h001A5900;
    ram[49] = 32'h8D5C0003;
    ram[50] = 32'h179D0007;
    ram[51] = 32'hA0AF0008;
    ram[52] = 32'h80B20008;
    ram[53] = 32'h90B30008;
    ram[54] = 32'h2DF8FFFF;
    ram[55] = 32'h0185E825;
    ram[56] = 32'h01600008;
    ram[57] = 32'h31F4FFFF;
    ram[58] = 32'h35F5FFFF;
    ram[59] = 32'h39F6FFFF;
    ram[60] = 32'h019D0018;
    ram[61] = 32'h0000B812;
    ram[62] = 32'h0000F010;
    ram[63] = 32'h03400013;
    ram[64] = 32'h03600011;
    ram[65] = 32'h40807000;
    ram[66] = 32'h0000000C;
    ram[67] = 32'h40027000;
    ram[68] = 32'h40036800;
    ram[69] = 32'h40046000;
    ram[70] = 32'h24010020;
    ram[71] = 32'h01EE882A;
    ram[72] = 32'h3C111234;
    ram[73] = 32'h26315678;
    ram[74] = 32'hAC310000;
    ram[75] = 32'h00118900;
    ram[76] = 32'h1E20FFFD;
    ram[77] = 32'h24210004;
    ram[78] = 32'h2402003C;
    ram[79] = 32'h8C31FFE4;
    ram[80] = 32'h00118902;
    ram[81] = 32'hAC510000;
    ram[82] = 32'h1620FFFD;
    ram[83] = 32'h24420004;
    ram[84] = 32'h24060044;
    ram[85] = 32'h24070064;
    ram[86] = 32'h8C23FFE4;
    ram[87] = 32'h8C44FFFC;
    ram[88] = 32'h00642825;
    ram[89] = 32'hA0E50000;
    ram[90] = 32'h24E70001;
    ram[91] = 32'h24210004;
    ram[92] = 32'h1446FFF9;
    ram[93] = 32'h2442FFFC;
    ram[94] = 32'h24090064;
    ram[95] = 32'h91290003;
    ram[96] = 32'h240D0068;
    ram[97] = 32'h8DAD0000;
    ram[98] = 32'h00094E00;
    ram[99] = 32'h39AD0009;
    ram[100]= 32'hACED0001;
    ram[101]= 32'h8C010000;
    ram[102]= 32'h8C020004;
    ram[103]= 32'h8C030008;
    ram[104]= 32'h8C04000C;
    ram[105]= 32'h8C050010;
    ram[106]= 32'h8C060018;
    ram[107]= 32'h8C070070;
    ram[108]= 32'h8C190074;
    ram[109]= 32'h8C0D0078;
    ram[110]= 32'h0800000D;
end


/********************** 写通道寄存器 *************************/
// 写事务状态
reg                          wr_active;
reg [C_S_AXI_ID_WIDTH-1:0]   wr_id_reg;
reg [C_S_AXI_ADDR_WIDTH-1:0] wr_addr_reg;
reg [7:0]                    wr_len_reg;   // AXI LEN, 表示 beats-1
reg [2:0]                    wr_size_reg;
reg [1:0]                    wr_burst_reg;
reg [7:0]                    wr_cnt;       // 已经写了多少 beat

reg                          bvalid_reg;

/********************** 读通道寄存器 *************************/
reg                          rd_active;
reg [C_S_AXI_ID_WIDTH-1:0]   rd_id_reg;
reg [C_S_AXI_ADDR_WIDTH-1:0] rd_addr_reg;
reg [7:0]                    rd_len_reg;
reg [2:0]                    rd_size_reg;
reg [1:0]                    rd_burst_reg;
reg [7:0]                    rd_cnt;

reg [C_S_AXI_DATA_WIDTH-1:0] rdata_reg;
reg                          rvalid_reg;
reg                          rlast_reg;

/********************** 组合：握手信号 ***************************/
wire aw_hs = S_AXI_AWVALID & S_AXI_AWREADY;
wire w_hs  = S_AXI_WVALID  & S_AXI_WREADY;
wire b_hs  = S_AXI_BVALID  & S_AXI_BREADY;
wire ar_hs = S_AXI_ARVALID & S_AXI_ARREADY;
wire r_hs  = S_AXI_RVALID  & S_AXI_RREADY;

wire rst = ~S_AXI_ARESETN;

 /********************** 地址递增函数（支持 FIXED/INCR/WRAP） ***************************/
function [C_S_AXI_ADDR_WIDTH-1:0] axi_next_addr;
    input [C_S_AXI_ADDR_WIDTH-1:0] addr;
    input [1:0]                    burst;
    input [2:0]                    size;
    input [7:0]                    len;   // AXI LEN (beats-1)

    // Verilog-2001 要求：函数内的声明写在 begin 之前
    integer increment;
    integer burst_bytes;
    reg [C_S_AXI_ADDR_WIDTH-1:0] base;
    reg [C_S_AXI_ADDR_WIDTH-1:0] wrap_mask;
begin
    increment   = (1 << size);              // 每拍字节数
    burst_bytes = increment * (len + 1);    // 整个 burst 字节数

    case (burst)
        2'b00: begin // FIXED
            axi_next_addr = addr;
        end

        2'b01: begin // INCR
            axi_next_addr = addr + increment;
        end

        2'b10: begin // WRAP
            // 按 AXI 规范：地址在一个 burst boundary 内回绕
            base      = addr & ~(burst_bytes-1);
            wrap_mask = burst_bytes - 1;
            axi_next_addr = base | ((addr + increment) & wrap_mask);
        end

        default: begin // 其他保守处理成 INCR
            axi_next_addr = addr + increment;
        end
    endcase
end
endfunction

/********************** 写通道：READY 信号 ***************************/
assign S_AXI_AWREADY = ~wr_active;   // 只要没有写事务在跑，就可以接新的 AW
assign S_AXI_WREADY  = wr_active;    // 当前有写事务，随时可以接数据

/********************** 写通道：响应 ***************************/
assign S_AXI_BID    = wr_id_reg;
assign S_AXI_BRESP  = 2'b00;                 // OKAY
assign S_AXI_BUSER  = {C_S_AXI_BUSER_WIDTH{1'b0}};
assign S_AXI_BVALID = bvalid_reg;

/********************** 读通道：READY/数据 ***************************/
assign S_AXI_ARREADY = ~rd_active;  // 没有读事务时可以接 AR

assign S_AXI_RID    = rd_id_reg;
assign S_AXI_RDATA  = rdata_reg;
assign S_AXI_RRESP  = 2'b00;                 // OKAY
assign S_AXI_RLAST  = rlast_reg;
assign S_AXI_RUSER  = {C_S_AXI_RUSER_WIDTH{1'b0}};
assign S_AXI_RVALID = rvalid_reg;

/********************** 写通道时序逻辑 ***************************/
always @(posedge S_AXI_ACLK) begin
    if (rst) begin
        wr_active   <= 1'b0;
        wr_id_reg   <= {C_S_AXI_ID_WIDTH{1'b0}};
        wr_addr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        wr_len_reg  <= 8'd0;
        wr_size_reg <= 3'd0;
        wr_burst_reg<= 2'd0;
        wr_cnt      <= 8'd0;
        bvalid_reg  <= 1'b0;
    end else begin
        // 接收写地址
        if (aw_hs) begin
            wr_active   <= 1'b1;
            wr_id_reg   <= S_AXI_AWID;
            wr_addr_reg <= S_AXI_AWADDR;
            wr_len_reg  <= S_AXI_AWLEN;
            wr_size_reg <= S_AXI_AWSIZE;
            wr_burst_reg<= S_AXI_AWBURST;
            wr_cnt      <= 8'd0;
        end

        // 写数据 & 写 RAM
        if (wr_active && w_hs) begin
            // 当前地址转换为 RAM 索引（word 地址）
            // 注意防止越界：简单模 RAM_DEPTH
            // word_addr = wr_addr_reg[ADDR_LSB +: RAM_ADDR_WIDTH];
            idx = wr_addr_reg[ADDR_LSB +: RAM_ADDR_WIDTH];

            // 处理 WSTRB
            for (i = 0; i < C_S_AXI_DATA_WIDTH/8; i = i + 1) begin
                if (S_AXI_WSTRB[i]) begin
                    ram[idx][8*i +: 8] <= S_AXI_WDATA[8*i +: 8];
                end
            end

            // 更新计数器
            wr_cnt <= wr_cnt + 1'b1;

            // 计算下一拍地址
            wr_addr_reg <= axi_next_addr(wr_addr_reg,
                                         wr_burst_reg,
                                         wr_size_reg,
                                         wr_len_reg);
        end

        // 最后一拍后产生 BVALID
        if (wr_active && w_hs && S_AXI_WLAST) begin
            bvalid_reg <= 1'b1;
            wr_active  <= 1'b0;
        end

        // B 通道握手后清除 BVALID
        if (b_hs) begin
            bvalid_reg <= 1'b0;
        end
    end
end

/********************** 读通道时序逻辑 ***************************/
always @(posedge S_AXI_ACLK) begin
    if (rst) begin
        rd_active   <= 1'b0;
        rd_id_reg   <= {C_S_AXI_ID_WIDTH{1'b0}};
        rd_addr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        rd_len_reg  <= 8'd0;
        rd_size_reg <= 3'd0;
        rd_burst_reg<= 2'd0;
        rd_cnt      <= 8'd0;
        rdata_reg   <= {C_S_AXI_DATA_WIDTH{1'b0}};
        rvalid_reg  <= 1'b0;
        rlast_reg   <= 1'b0;
    end else begin
        // 接收读地址
        if (ar_hs) begin
            rd_active   <= 1'b1;
            rd_id_reg   <= S_AXI_ARID;
            rd_addr_reg <= S_AXI_ARADDR;
            rd_len_reg  <= S_AXI_ARLEN;
            rd_size_reg <= S_AXI_ARSIZE;
            rd_burst_reg<= S_AXI_ARBURST;
            rd_cnt      <= 8'd0;
        end

        // 读数据产生逻辑：
        // 当：没有有效数据 或者 当前 beat 已被接受(r_hs)，且仍然有读事务
        if (rd_active && (!rvalid_reg || r_hs)) begin
            // 从 RAM 读取当前地址
            idx_r = rd_addr_reg[ADDR_LSB +: RAM_ADDR_WIDTH];

            rdata_reg <= ram[idx_r];
            rvalid_reg<= 1'b1;
            rlast_reg <= (rd_cnt == rd_len_reg);

            // 更新计数和地址
            rd_cnt <= rd_cnt + 1'b1;
            rd_addr_reg <= axi_next_addr(rd_addr_reg,
                                         rd_burst_reg,
                                         rd_size_reg,
                                         rd_len_reg);

            // 如果这是最后一个 beat 且被握手，就结束事务
            if (rd_cnt == rd_len_reg && r_hs) begin
                rd_active  <= 1'b0;
                rvalid_reg <= 1'b0;
                rlast_reg  <= 1'b0;
            end
        end

        // 最后一拍握手后清 RVALID（上面就会处理）
        if (!rd_active && r_hs) begin
            rvalid_reg <= 1'b0;
            rlast_reg  <= 1'b0;
        end
    end
end

endmodule
