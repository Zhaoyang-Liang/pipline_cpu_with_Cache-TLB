`timescale 1ns / 1ps
`define STARTADDR 32'H00000000

module fetch(
    input             clk,
    input             resetn,
    input             IF_valid,
    input             next_fetch,      // pipeline 允许进入
    input      [32:0] jbr_bus,        // 跳转总线

    // ===== I-CACHE USER INTERFACE =====
    output reg        icache_req,     // 拉高 1 周期开始取指
    output reg [31:0] icache_addr,    // 取指地址 (PC)
    input             icache_ready,   // I$ 可接收新请求
    input             icache_resp_valid,
    input      [31:0] icache_inst,

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
    reg  [31:0] inst_reg;

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

    // 只有当前指令真正"取回并且被流水接受"时才更新 PC
    always @(posedge clk) begin
        if (!resetn)
            pc <= `STARTADDR;
        else if (next_fetch && IF_over)
            pc <= next_pc;
    end

    // 指令打一拍保存
    always @(posedge clk) begin
        if (!resetn)
            inst_reg <= 32'h0;
        else if (icache_resp_valid)
            inst_reg <= icache_inst;
    end

    //===================== I-Cache 请求 =====================
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
                if (IF_valid && icache_ready)
                    next_state = REQUEST;
                else
                    next_state = IDLE;
            end
            REQUEST: begin
                next_state = PENDING;
            end
            PENDING: begin
                if (icache_resp_valid)
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

    always @(posedge clk) begin
        if (!resetn) begin
            icache_req  <= 1'b0;
            icache_addr <= `STARTADDR;
        end else begin
            icache_req <= (current_state == REQUEST);
            if (current_state == REQUEST) begin
                icache_addr <= pc;
                $display("FETCH: I$ request PC=%h", pc);
            end
        end
    end

    // IF_over 控制
    always @(posedge clk) begin
        if (!resetn)
            IF_over <= 1'b0;
        else if (icache_resp_valid)
            IF_over <= 1'b1;
        else if (next_fetch)
            IF_over <= 1'b0;
    end

    always @(posedge clk) begin
        if (icache_resp_valid) begin
            $display("FETCH: I$ resp inst=%h", icache_inst);
        end
    end

    //===================== 输出 =====================
    assign IF_ID_bus = { pc, inst_reg };
    assign IF_pc     = pc;
    assign IF_inst   = inst_reg;

endmodule
