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
integer j;


// 初始化RAM，从地址0开始存放指令
initial begin
    for(j = 0; j < C_S_RAM_DEPTH; j = j + 1) begin
        case(j)
            0:  ram[j] = 32'h24010001;
            1:  ram[j] = 32'h00011100;
            2:  ram[j] = 32'h00411821;
            3:  ram[j] = 32'h00022082;
            4:  ram[j] = 32'h28990005;
            5:  ram[j] = 32'h0721000E;
            6:  ram[j] = 32'h00642823;
            7:  ram[j] = 32'hAC050014;
            8:  ram[j] = 32'h00A23027;
            9:  ram[j] = 32'h00C33825;
            10: ram[j] = 32'h00E64026;
            11: ram[j] = 32'h11030002;
            12: ram[j] = 32'hAC08001C;
            13: ram[j] = 32'h0022482A;
            14: ram[j] = 32'h8C0A001C;
            15: ram[j] = 32'h15450002;
            16: ram[j] = 32'h00415824;
            17: ram[j] = 32'hAC0B001C;
            18: ram[j] = 32'h0C000026;
            19: ram[j] = 32'hAC040010;
            20: ram[j] = 32'h3C0C000C;
            21: ram[j] = 32'h004CD007;
            22: ram[j] = 32'h275B0044;
            default: ram[j] = 32'h00000000; // nop
        endcase
    end
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
// 处理BID宽度为0的情况
generate
  if (C_S_AXI_ID_WIDTH > 0) begin
    assign S_AXI_BID = wr_id_reg;
  end else begin
    assign S_AXI_BID = 1'b0;
  end
endgenerate

assign S_AXI_BRESP  = 2'b00;                 // OKAY

// 处理BUSER宽度为0的情况
generate
  if (C_S_AXI_BUSER_WIDTH > 0) begin
    assign S_AXI_BUSER = {C_S_AXI_BUSER_WIDTH{1'b0}};
  end else begin
    assign S_AXI_BUSER = 1'b0;
  end
endgenerate

assign S_AXI_BVALID = bvalid_reg;

/********************** 读通道：READY/数据 ***************************/
assign S_AXI_ARREADY = ~rd_active;  // 没有读事务时可以接 AR

// 处理RID宽度为0的情况
generate
  if (C_S_AXI_ID_WIDTH > 0) begin
    assign S_AXI_RID = rd_id_reg;
  end else begin
    assign S_AXI_RID = 1'b0;
  end
endgenerate

assign S_AXI_RDATA  = rdata_reg;
assign S_AXI_RRESP  = 2'b00;                 // OKAY
assign S_AXI_RLAST  = rlast_reg;

// 处理RUSER宽度为0的情况
generate
  if (C_S_AXI_RUSER_WIDTH > 0) begin
    assign S_AXI_RUSER = {C_S_AXI_RUSER_WIDTH{1'b0}};
  end else begin
    assign S_AXI_RUSER = 1'b0;
  end
endgenerate

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
            idx = (S_AXI_AWADDR >> 2) & (C_S_RAM_DEPTH - 1);

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
            idx_r = (S_AXI_ARADDR >> 2) & (C_S_RAM_DEPTH - 1);
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