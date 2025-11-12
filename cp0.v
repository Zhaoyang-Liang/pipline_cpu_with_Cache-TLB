`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: cp0.v
//   > 描述  :协处理器0（CP0）模块，用于系统控制和异常处理
//   > 作者  : 
//   > 日期  : 
//*************************************************************************

`define EXC_ENTER_ADDR 32'd0     // Exception入口地址，此处实现的Exception只有SYSCALL

module cp0(
    input             clk,       // 时钟
    input             resetn,    // 复位信号，低电平有效
    
    // 来自WB级的控制信号
    input             mtc0,      // MTC0指令标识
    input             mfc0,      // MFC0指令标识
    input      [ 7:0] cp0r_addr, // CP0寄存器地址 {寄存器号[4:0], 选择域[2:0]}
    input      [31:0] wdata,     // 写入CP0的数据（来自mem_result）
    
    // 异常相关信号
    input             syscall,   // SYSCALL指令标识
    input             eret,      // ERET指令标识
    input      [31:0] pc,        // 当前PC值（用于保存到EPC）
    input             wb_valid,  // WB级有效信号
    input             wb_over,   // WB级完成信号

    // 统一异常总线（来自WB的最终裁决）
    input             ex_valid_i,        // 异常有效
    input      [ 4:0] ex_code_i,         // 异常编码
    input             ex_bd_i,           // 延迟槽异常
    input      [31:0] ex_pc_i,           // 发生异常的PC（若bd=1，为分支PC）
    input             badvaddr_valid_i,  // 错误地址有效
    input      [31:0] badvaddr_i,        // 错误地址
    
    // CP0寄存器读数据输出
    output     [31:0] cp0r_rdata,// CP0寄存器读数据（用于MFC0）
    
    // 异常处理输出
    output            cancel,    // 取消流水线信号
    output            exc_valid, // 异常有效信号
    output     [31:0] exc_pc,    // 异常入口地址或ERET返回地址
    
    // 寄存器值输出（用于异常处理）
    output     [31:0] cp0r_status,// STATUS寄存器值
    output     [31:0] cp0r_cause, // CAUSE寄存器值
    output     [31:0] cp0r_epc,   // EPC寄存器值
    
    // 中断输出
    output            c0_int      // 中断有效信号
);

// 地址解码（reg_num[4:0], sel[2:0]）
wire [4:0] cp0_reg_num = cp0r_addr[7:3];
wire [2:0] cp0_sel     = cp0r_addr[2:0];
wire sel_status = (cp0_reg_num==5'd12) && (cp0_sel==3'd0);
wire sel_cause  = (cp0_reg_num==5'd13) && (cp0_sel==3'd0);
wire sel_epc    = (cp0_reg_num==5'd14) && (cp0_sel==3'd0);
wire sel_count  = (cp0_reg_num==5'd9)  && (cp0_sel==3'd0);   // COUNT寄存器
wire sel_compare= (cp0_reg_num==5'd11) && (cp0_sel==3'd0);   // COMPARE寄存器
wire sel_badvaddr = (cp0_reg_num==5'd8) && (cp0_sel==3'd0);  // BADVADDR寄存器

// CP0寄存器：status/cause/epc/badvaddr/count/compare
reg [31:0] status;
reg [31:0] cause;
reg [31:0] epc;
reg [31:0] badvaddr;
reg [31:0] count;      // COUNT寄存器（定时器计数）
reg [31:0] compare;    // COMPARE寄存器（定时器比较值）

// STATUS寄存器位域
wire status_ie;        // bit 0: 全局中断使能
wire status_exl;       // bit 1: 异常级别
wire [7:0] status_im;  // bit 15:8: 中断屏蔽位

// CAUSE寄存器位域
wire cause_bd;         // bit 31: 延迟槽标志
wire cause_ti;         // bit 30: 定时器中断标志
wire [7:0] cause_ip;   // bit 15:8: 中断挂起位
wire [4:0] cause_excode; // bit 6:2: 异常编码

// 定时器相关信号
reg time_tick;         // 定时器时钟分频（每两个时钟周期翻转一次）
wire count_eq_compare; // COUNT == COMPARE
reg cause_ti_reg;     // 定时器中断标志寄存器

// STATUS和CAUSE寄存器位域赋值
assign status_ie  = status[0];
assign status_exl = status[1];
assign status_im  = status[15:8];

assign cause_bd     = cause[31];
assign cause_ti     = cause[30];
assign cause_ip     = cause[15:8];
assign cause_excode = cause[6:2];

// 读口 output: cp0r_status, cp0r_cause, cp0r_epc
assign cp0r_status = status;
assign cp0r_cause  = cause;
assign cp0r_epc    = epc;

// COUNT == COMPARE检测
assign count_eq_compare = (count == compare);

// 写允许信号
wire status_wen;
wire cause_wen;
wire epc_wen;
wire count_wen;
wire compare_wen;
wire badvaddr_wen;
wire mtc0_wr;  // MTC0写使能（排除异常时写入）

assign mtc0_wr      = mtc0 && wb_valid && !ex_valid_i; // 异常时不写入
assign status_wen   = mtc0_wr && sel_status;
assign cause_wen    = mtc0_wr && sel_cause;
assign epc_wen      = mtc0_wr && sel_epc;
assign count_wen    = mtc0_wr && sel_count;
assign compare_wen  = mtc0_wr && sel_compare;
assign badvaddr_wen = mtc0_wr && sel_badvaddr;

// STATUS寄存器写掩码（支持IE、EXL、IM位）
wire [31:0] STATUS_WMASK;
assign STATUS_WMASK = 32'h0000_8103; // bit 0(IE), bit 1(EXL), bit 15:8(IM)

// CAUSE寄存器写掩码（支持IP[1:0]位）
wire [31:0] CAUSE_WMASK;
assign CAUSE_WMASK = 32'h0000_0300;  // bit 9:8(IP[1:0])

// 定时器时钟分频（每两个时钟周期翻转一次，降低计数频率）
always @(posedge clk) begin
    if (!resetn) begin
        time_tick <= 1'b0;
    end else begin
        time_tick <= ~time_tick;
    end
end

// COUNT寄存器：可写，或每两个时钟周期自增
always @(posedge clk) begin
    if (!resetn) begin
        count <= 32'd0;
    end else begin
        if (count_wen) begin
            count <= wdata;
        end else if (time_tick) begin
            count <= count + 1'b1;
        end
    end
end

// COMPARE寄存器：可写，写入时清除定时器中断
always @(posedge clk) begin
    if (!resetn) begin
        compare <= 32'd0;
    end else begin
        if (compare_wen) begin
            compare <= wdata;
        end
    end
end

// 定时器中断标志（cause_ti_reg）
always @(posedge clk) begin
    if (!resetn) begin
        cause_ti_reg <= 1'b0;
    end else begin
        if (compare_wen) begin
            cause_ti_reg <= 1'b0;  // 写入COMPARE时清除
        end else if (count_eq_compare) begin
            cause_ti_reg <= 1'b1;   // COUNT == COMPARE时置位
        end
    end
end

// CP0寄存器主逻辑
always @(posedge clk) begin
    if (!resetn) begin
        status <= 32'd0;
        cause  <= 32'd0;
        epc    <= 32'd0;
        badvaddr <= 32'd0;
    end else begin
        // MTC0写入
        if (status_wen) begin
            status <= (status & ~STATUS_WMASK) | (wdata & STATUS_WMASK);
        end
        if (cause_wen) begin
            cause <= (cause & ~CAUSE_WMASK) | (wdata & CAUSE_WMASK);
        end
        if (epc_wen) begin
            epc <= wdata;
        end
        if (badvaddr_wen) begin
            badvaddr <= wdata;
        end

        // 统一异常处理：所有异常都通过ex_valid_i传递
        // 注意：当为延迟槽异常时，EPC需写分支指令PC（即 ex_pc_i），返回时可由软件决定是否+4
        if (ex_valid_i && wb_valid) begin
            status[1] <= 1'b1;                     // EXL
            cause[31] <= ex_bd_i;                  // BD
            cause[6:2] <= ex_code_i;               // ExcCode
            epc <= ex_bd_i ? ex_pc_i : ex_pc_i;   // 这里写入分支PC或出错PC
            if (badvaddr_valid_i) begin
                badvaddr <= badvaddr_i;
            end
        end
        
        // ERET指令：清除EXL位
        if (eret && wb_valid) begin
            status[1] <= 1'b0;   // 清EXL
        end
        
        // CAUSE寄存器位域更新（持续更新，不受异常处理影响）
        // cause[30]: TI位（定时器中断标志）
        if (!ex_valid_i || !wb_valid) begin
            cause[30] <= cause_ti_reg;
        end
        
        // cause[15:8]: IP位（中断挂起位）
        // IP[7] = TI（定时器中断）
        // IP[6:2] = 外部中断（暂未实现，保留为0）
        // IP[1:0] = 软件可写（由MTC0控制）
        if (!ex_valid_i || !wb_valid) begin
            cause[15:8] <= {cause_ti_reg, 5'd0, cause[9:8]};
        end
    end
end

// MFC0读
assign cp0r_rdata = sel_status  ? status   :
                    sel_cause   ? cause    :
                    sel_epc     ? epc      :
                    sel_count   ? count    :
                    sel_compare ? compare  :
                    sel_badvaddr? badvaddr : 32'd0;

// 中断检测逻辑
// 中断条件：有中断挂起 && 对应中断使能 && 全局中断使能 && 不在异常级别
assign c0_int = |(cause_ip[7:0] & status_im[7:0]) & status_ie & !status_exl;

// 异常/返回对外信号（包含中断）
// 注意：所有异常（包括syscall/break）都通过ex_valid_i传递，所以这里只需要检查ex_valid_i
assign cancel    = (ex_valid_i | eret | c0_int) && wb_over;
assign exc_valid = (ex_valid_i | eret | c0_int) && wb_valid;
assign exc_pc    = eret ? epc : `EXC_ENTER_ADDR;

endmodule
