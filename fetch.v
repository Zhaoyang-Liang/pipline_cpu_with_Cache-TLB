`timescale 1ns / 1ps
`define STARTADDR 32'H00000000

module fetch(
    input             clk,
    input             resetn,
    input             IF_valid,
    input             next_fetch,      // pipeline 允许进入
    input      [32:0] jbr_bus,        // 跳转总线

    // ===== AXI USER INTERFACE =====
    output reg        axi_start,      // 拉高 1 周期开始 AXI read
    output reg [31:0] axi_addr,       // AXI 读地址 (PC)
    input             axi_done,       // AXI 事务结束 = inst 有效
    input      [31:0] axi_rdata,      // AXI 读出的指令
    input             axi_busy,       // AXI 正在执行

    //===============================
    // pipeline 输出
    //===============================
    output reg        IF_over,        // 完成
    output     [63:0] IF_ID_bus,      // {PC , INST}

    // 异常
    input      [32:0] exc_bus,

    // debug
    output     [31:0] IF_pc,
    output     [31:0] IF_inst
);

    //===================== PC 逻辑 =======================
    reg  [31:0] pc;
    reg  [31:0] inst_reg;   // 把指令打一拍保存，避免 AXI 总线空闲时变 0

    wire [31:0] next_pc;
    wire [31:0] seq_pc;

    // 跳转
    wire        jbr_taken;
    wire [31:0] jbr_target;
    assign {jbr_taken, jbr_target} = jbr_bus;

    // 异常
    wire        exc_valid;
    wire [31:0] exc_pc;
    assign {exc_valid, exc_pc} = exc_bus;

    // PC + 4
    assign seq_pc = pc + 32'd4;

    // PC 选择
    assign next_pc = exc_valid ? exc_pc :
                     jbr_taken ? jbr_target :
                     seq_pc;

    // **注意：只有当前指令真正"取回并且被流水接受"时才更新 PC**
    always @(posedge clk) begin
        if (!resetn)
            pc <= `STARTADDR;
        // 只有“上一条指令已取回(=IF_over)”且流水线允许进入(next_fetch)
        // 时才更新 PC，避免 axi_done 脉冲与 next_fetch 错位导致 PC 卡住
        else if (next_fetch && IF_over)
            pc <= next_pc;
    end

    // 指令打一拍保存（AXI 总线空闲时 IF_inst 不会乱跳）
    always @(posedge clk) begin
        if (!resetn)
            inst_reg <= 32'h0;
        else if (axi_done)
            inst_reg <= axi_rdata;
    end

    //===================== AXI 读事务触发 ======================
    // 使用传统parameter定义状态机
    parameter [1:0] IDLE = 2'b00,
                  REQUEST = 2'b01,
                  PENDING = 2'b10,
                  DONE = 2'b11;

    reg [1:0] current_state, next_state;

    always @(posedge clk) begin
        if (!resetn)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        case(current_state)
            IDLE: begin
                if (IF_valid && !axi_busy)
                    next_state = REQUEST;
                else
                    next_state = IDLE;
            end
            REQUEST: begin
                next_state = PENDING;  // 发出请求后立即进入PENDING状态
            end
            PENDING: begin
                if (axi_done)
                    next_state = DONE;
                else
                    next_state = PENDING;
            end
            DONE: begin
                if (next_fetch)
                    next_state = IDLE;
                else
                    next_state = DONE;
            end
            default: next_state = IDLE;
        endcase
    end

    // AXI 控制信号
    always @(posedge clk) begin
        if (!resetn) begin
            axi_start <= 1'b0;
            axi_addr  <= `STARTADDR;
        end
        else begin
            // 在 REQUEST 状态发出 1 拍脉冲，并锁存当前 PC 为 AXI 地址
            axi_start <= (current_state == REQUEST);
            if (current_state == REQUEST) begin
                axi_addr <= pc;
                $display("Time=%0t FETCH: Requesting PC=%h", $time, pc);
            end
        end
    end

    //===================== IF_over 控制 ======================
    // IF_over 变为握手机制：axi_done 置位，next_fetch 拉低表示下级已接收
    always @(posedge clk) begin
        if (!resetn)
            IF_over <= 1'b0;
        else if (axi_done)
            IF_over <= 1'b1;          // 指令已取回
        else if (next_fetch)
            IF_over <= 1'b0;          // 下级已接收，准备下一条
    end

    //===================== 输出 ======================
    assign IF_ID_bus = { pc, inst_reg };
    assign IF_pc     = pc;
    assign IF_inst   = inst_reg;   // 用打拍后的 inst_reg，波形不会老是变 0

endmodule