`timescale 1ns / 1ps
`define STARTADDR 32'H00000034

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
    assign seq_pc = { pc[31:2] + 1'b1, pc[1:0] };

    // PC 选择
    assign next_pc = exc_valid ? exc_pc :
                     jbr_taken ? jbr_target :
                     seq_pc;

    // **注意：只有当前指令真正“取回并且被流水接受”时才更新 PC**
    always @(posedge clk) begin
        if (!resetn)
            pc <= `STARTADDR;
        else if (next_fetch && axi_done)
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
    // 非常简单的状态机：保证任意时刻最多只挂起 1 个读事务
    reg started;        // 是否已经发过第一次读
    reg outstanding;    // 是否有读事务正在进行中

    always @(posedge clk) begin
        if (!resetn) begin
            axi_start   <= 1'b0;
            axi_addr    <= `STARTADDR;
            started     <= 1'b0;
            outstanding <= 1'b0;
        end
        else begin
            axi_start <= 1'b0;   // 默认拉低

            // 当前指令读完了
            if (axi_done)
                outstanding <= 1'b0;

            // 复位后第一次：直接按当前 pc 取一次指令
            if (!started && !outstanding && !axi_busy) begin
                axi_start   <= 1'b1;
                axi_addr    <= pc;         // 这里是 STARTADDR
                started     <= 1'b1;
                outstanding <= 1'b1;
            end
            // 后续：当前没有挂起事务时，再取下一条指令
            else if (started && !outstanding && !axi_busy && IF_valid) begin
                axi_start   <= 1'b1;
                axi_addr    <= pc;         // 注意：pc 已经在上一个 axi_done 时更新为下一条
                outstanding <= 1'b1;
            end
        end
    end

    //===================== IF_over 控制 ======================
    // AXI 读完成 -> IF 级完成
    always @(posedge clk) begin
        if (!resetn)
            IF_over <= 1'b0;
        else
            IF_over <= axi_done;
    end

    //===================== 输出 ======================
    assign IF_ID_bus = { pc, inst_reg };
    assign IF_pc     = pc;
    assign IF_inst   = inst_reg;   // 用打拍后的 inst_reg，波形不会老是变 0

endmodule
