module axi_full_master #(
    parameter  C_M_TARGET_SLAVE_BASE_ADDR = 32'h0000_0000,
    parameter integer C_M_AXI_ID_WIDTH    = 1,
    parameter integer C_M_AXI_ADDR_WIDTH  = 32,
    parameter integer C_M_AXI_DATA_WIDTH  = 32,
    parameter integer C_M_AXI_AWUSER_WIDTH= 0,
    parameter integer C_M_AXI_ARUSER_WIDTH= 0,
    parameter integer C_M_AXI_WUSER_WIDTH = 0,
    parameter integer C_M_AXI_RUSER_WIDTH = 0,
    parameter integer C_M_AXI_BUSER_WIDTH = 0
)(
    // AXI 时钟 & 复位
    input  wire                          M_AXI_ACLK,
    input  wire                          M_AXI_ARESETN,

    // ================= AXI 写地址通道 =================
    output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    output wire [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
    output wire [7:0]                    M_AXI_AWLEN,
    output wire [2:0]                    M_AXI_AWSIZE,
    output wire [1:0]                    M_AXI_AWBURST,
    output wire                          M_AXI_AWLOCK,
    output wire [3:0]                    M_AXI_AWCACHE,
    output wire [2:0]                    M_AXI_AWPROT,
    output wire [3:0]                    M_AXI_AWQOS,
    output wire [C_M_AXI_AWUSER_WIDTH-1:0] M_AXI_AWUSER,
    output reg                           M_AXI_AWVALID,
    input  wire                          M_AXI_AWREADY,

    // ================= AXI 写数据通道 =================
    output wire [C_M_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output wire                          M_AXI_WLAST,
    output wire [C_M_AXI_WUSER_WIDTH-1:0] M_AXI_WUSER,
    output wire                          M_AXI_WVALID,
    input  wire                          M_AXI_WREADY,

    // ================= AXI 写响应通道 =================
    input  wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
    input  wire [1 : 0]                  M_AXI_BRESP,
    input  wire [C_M_AXI_BUSER_WIDTH-1:0] M_AXI_BUSER,
    input  wire                          M_AXI_BVALID,
    output wire                          M_AXI_BREADY,

    // ================= AXI 读地址通道 =================
    output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    output wire [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output wire [7:0]                    M_AXI_ARLEN,
    output wire [2:0]                    M_AXI_ARSIZE,
    output wire [1:0]                    M_AXI_ARBURST,
    output wire                          M_AXI_ARLOCK,
    output wire [3:0]                    M_AXI_ARCACHE,
    output wire [2:0]                    M_AXI_ARPROT,
    output wire [3:0]                    M_AXI_ARQOS,
    output wire [C_M_AXI_ARUSER_WIDTH-1:0] M_AXI_ARUSER,
    output reg                           M_AXI_ARVALID,
    input  wire                          M_AXI_ARREADY,

    // ================= AXI 读数据通道 =================
    input  wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    input  wire [C_M_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
    input  wire [1 : 0]                  M_AXI_RRESP,
    input  wire                          M_AXI_RLAST,
    input  wire [C_M_AXI_RUSER_WIDTH-1:0] M_AXI_RUSER,
    input  wire                          M_AXI_RVALID,
    output wire                          M_AXI_RREADY,

    // ================= 用户接口 =================
    input  wire                          user_start,   // 拉高 1 个周期开始一次操作
    input  wire                          user_rw,      // 0 = 写, 1 = 读
    input  wire [C_M_AXI_ADDR_WIDTH-1:0] user_addr,    // 起始地址 (offset)
    input  wire [7:0]                    user_len,     // burst 长度 (1~256)

    // 写数据（用户提供）
    input  wire [C_M_AXI_DATA_WIDTH-1:0] user_wdata,
    input  wire                          user_wvalid,
    output wire                          user_wready,

    // 读数据（提供给用户）
    output wire [C_M_AXI_DATA_WIDTH-1:0] user_rdata,
    output wire                          user_rvalid,
    input  wire                          user_rready,

    // 状态信号
    output wire                          user_busy,
    output wire                          user_done,
    output wire                          user_error
);

/**********************工具函数: 计算 AWSIZE 等***************************/
function integer clogb2;
    input integer number;
    integer i;
begin
    clogb2 = 0;
    for (i = number-1; i > 0; i = i >> 1)
        clogb2 = clogb2 + 1;
end
endfunction

/**********************状态机定义*************************/
localparam ST_IDLE  = 3'd0;
localparam ST_AW    = 3'd1;
localparam ST_W     = 3'd2;
localparam ST_B     = 3'd3;
localparam ST_AR    = 3'd4;
localparam ST_R     = 3'd5;
localparam ST_DONE  = 3'd6;

reg [2:0] state, next_state;

/**********************内部寄存器*************************/
// 事务参数寄存
reg [C_M_AXI_ADDR_WIDTH-1:0] addr_reg;
reg [7:0]                     len_reg;    // 实际 beat 数（>=1）
reg                           rw_reg;     // 0=写  1=读

// 读/写数据 beat 计数
reg [7:0]                     beat_cnt;

// 错误标志
reg                           error_reg;

// done 脉冲
reg                           done_reg;

/**********************AXI 固定参数*************************/
// 为USER信号创建条件赋值，处理宽度为0的情况
generate
  if (C_M_AXI_AWUSER_WIDTH > 0) begin : gen_awuser
    assign M_AXI_AWUSER = {C_M_AXI_AWUSER_WIDTH{1'b0}};
  end else begin
    assign M_AXI_AWUSER = 1'b0;  // 用于宽度为0的情况
  end
endgenerate

generate
  if (C_M_AXI_WUSER_WIDTH > 0) begin : gen_wuser
    assign M_AXI_WUSER = {C_M_AXI_WUSER_WIDTH{1'b0}};
  end else begin
    assign M_AXI_WUSER = 1'b0;  // 用于宽度为0的情况
  end
endgenerate

generate
  if (C_M_AXI_ARUSER_WIDTH > 0) begin : gen_aruser
    assign M_AXI_ARUSER = {C_M_AXI_ARUSER_WIDTH{1'b0}};
  end else begin
    assign M_AXI_ARUSER = 1'b0;  // 用于宽度为0的情况
  end
endgenerate

generate
  if (C_M_AXI_BUSER_WIDTH > 0) begin : gen_buser
    assign M_AXI_BUSER = {C_M_AXI_BUSER_WIDTH{1'b0}};
  end else begin
    assign M_AXI_BUSER = 1'b0;  // 用于宽度为0的情况
  end
endgenerate

generate
  if (C_M_AXI_RUSER_WIDTH > 0) begin : gen_ruser
    assign M_AXI_RUSER = {C_M_AXI_RUSER_WIDTH{1'b0}};
  end else begin
    assign M_AXI_RUSER = 1'b0;  // 用于宽度为0的情况
  end
endgenerate

assign M_AXI_AWID    = {C_M_AXI_ID_WIDTH{1'b0}};
assign M_AXI_AWBURST = 2'b01;          // INCR
assign M_AXI_AWLOCK  = 1'b0;
assign M_AXI_AWCACHE = 4'b0010;
assign M_AXI_AWPROT  = 3'b000;
assign M_AXI_AWQOS   = 4'b0000;

assign M_AXI_ARID    = {C_M_AXI_ID_WIDTH{1'b0}};
assign M_AXI_ARBURST = 2'b01;          // INCR
assign M_AXI_ARLOCK  = 1'b0;
assign M_AXI_ARCACHE = 4'b0010;
assign M_AXI_ARPROT  = 3'b000;
assign M_AXI_ARQOS   = 4'b0000;

assign M_AXI_AWSIZE  = clogb2(C_M_AXI_DATA_WIDTH/8);
assign M_AXI_ARSIZE  = clogb2(C_M_AXI_DATA_WIDTH/8);

// 处理STRB宽度为0的情况
generate
  if (C_M_AXI_DATA_WIDTH/8 > 0) begin
    assign M_AXI_WSTRB = {(C_M_AXI_DATA_WIDTH/8){1'b1}};
  end else begin
    assign M_AXI_WSTRB = 1'b1;  // 至少1位
  end
endgenerate

assign M_AXI_BREADY  = (state == ST_B);   // 只在等待响应阶段拉高

assign M_AXI_RREADY  = (state == ST_R) && user_rready;

/**********************地址与长度*************************/
assign M_AXI_AWADDR = addr_reg + C_M_TARGET_SLAVE_BASE_ADDR;
assign M_AXI_ARADDR = addr_reg + C_M_TARGET_SLAVE_BASE_ADDR;

// AXI AWLEN/ARLEN = beat 数 - 1
assign M_AXI_AWLEN  = len_reg - 1'b1;
assign M_AXI_ARLEN  = len_reg - 1'b1;

/**********************写数据直通用户接口*************************/
assign M_AXI_WDATA  = user_wdata;
assign M_AXI_WVALID = (state == ST_W) && user_wvalid;

// 当前 beat 是否为最后一拍
wire last_beat = (beat_cnt == len_reg - 1);

// WLAST 只在最后一个有效拍为 1
assign M_AXI_WLAST  = (state == ST_W) && user_wvalid && last_beat;

// 用户侧写 ready：只有在写数据阶段并且从机 ready 时有效
assign user_wready  = (state == ST_W) && M_AXI_WREADY;

/**********************读数据直通用户接口*************************/
assign user_rdata  = M_AXI_RDATA;
assign user_rvalid = (state == ST_R) && M_AXI_RVALID;

/**********************用户状态信号*************************/
assign user_busy  = (state != ST_IDLE);
assign user_done  = done_reg;
assign user_error = error_reg;

/**********************状态机：顺序逻辑*************************/
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        state       <= ST_IDLE;
        addr_reg    <= {C_M_AXI_ADDR_WIDTH{1'b0}};
        len_reg     <= 8'd1;
        rw_reg      <= 1'b0;
        beat_cnt    <= 8'd0;
        error_reg   <= 1'b0;
        done_reg    <= 1'b0;
        M_AXI_AWVALID <= 1'b0;
        M_AXI_ARVALID <= 1'b0;
    end else begin
        state    <= next_state;
        done_reg <= 1'b0;     // 默认拉低，DONE 状态下再拉高 1 个周期

        case (state)
            ST_IDLE: begin
                M_AXI_AWVALID <= 1'b0;
                M_AXI_ARVALID <= 1'b0;
                beat_cnt      <= 8'd0;
                error_reg     <= 1'b0;

                if (user_start) begin
                    addr_reg <= user_addr;
                    // 防止 user_len 为 0
                    len_reg  <= (user_len == 8'd0) ? 8'd1 : user_len;
                    rw_reg   <= user_rw;
                    $display("Time=%0t AXI_MASTER: user_start, user_addr=%h, user_rw=%b", 
                             $time, user_addr, user_rw);
                end
            end

            // 写地址阶段
            ST_AW: begin
                // 拉高 AWVALID，直到握手成功
                if (!M_AXI_AWVALID)
                    M_AXI_AWVALID <= 1'b1;

                if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                    M_AXI_AWVALID <= 1'b0;
                    beat_cnt      <= 8'd0;
                end
            end

            // 写数据阶段
            ST_W: begin
                if (M_AXI_WVALID && M_AXI_WREADY) begin
                    // 每发送一个 beat 就 +1
                    beat_cnt <= beat_cnt + 1'b1;
                end
            end

            // 写响应阶段
            ST_B: begin
                if (M_AXI_BVALID && M_AXI_BREADY) begin
                    if (M_AXI_BRESP != 2'b00)
                        error_reg <= 1'b1;  // 记录错误
                end
            end

            // 读地址阶段
            ST_AR: begin
                if (!M_AXI_ARVALID) begin
                    M_AXI_ARVALID <= 1'b1;
                    $display("Time=%0t AXI_MASTER: Setting ARVALID=1, ARADDR=%h, addr_reg=%h", 
                             $time, M_AXI_ARADDR, addr_reg);
                end

                if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                    M_AXI_ARVALID <= 1'b0;
                    $display("Time=%0t AXI_MASTER: AR handshake complete, ARADDR=%h", 
                             $time, M_AXI_ARADDR);
                end
            end

            // 读数据阶段
            ST_R: begin
                if (M_AXI_RVALID && M_AXI_RREADY) begin
                    if (M_AXI_RRESP != 2'b00)
                        error_reg <= 1'b1;  // 记录错误
                    beat_cnt <= beat_cnt + 1'b1;
                end
            end

            ST_DONE: begin
                done_reg <= 1'b1;   // DONE 脉冲
            end

            default: ;
        endcase
    end
end

/**********************状态机：组合逻辑*************************/
always @(*) begin
    next_state = state;
    case (state)
        ST_IDLE: begin
            if (user_start) begin
                if (user_rw == 1'b0)
                    next_state = ST_AW;   // 写事务
                else
                    next_state = ST_AR;   // 读事务
            end
        end

        // 写事务状态跳转
        ST_AW: begin
            if (M_AXI_AWVALID && M_AXI_AWREADY)
                next_state = ST_W;
        end

        ST_W: begin
            if (M_AXI_WVALID && M_AXI_WREADY && last_beat)
                next_state = ST_B;
        end

        ST_B: begin
            if (M_AXI_BVALID && M_AXI_BREADY)
                next_state = ST_DONE;
        end

        // 读事务状态跳转
        ST_AR: begin
            if (M_AXI_ARVALID && M_AXI_ARREADY)
                next_state = ST_R;
        end

        ST_R: begin
            if (M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST)
                next_state = ST_DONE;
        end

        ST_DONE: begin
            next_state = ST_IDLE;
        end

        default: next_state = ST_IDLE;
    endcase
end

endmodule