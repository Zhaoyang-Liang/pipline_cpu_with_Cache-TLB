`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: bypass_unit.v
//   > 描述  : 流水线CPU旁路检测单元
//   > 作者  : 
//   > 日期  : 
//*************************************************************************



module bypass_unit(
    // 当前指令信息
    input [4:0] rs,                    // 源寄存器1地址
    input [4:0] rt,                    // 源寄存器2地址
    input [31:0] rs_value,             // 源寄存器1原始值
    input [31:0] rt_value,             // 源寄存器2原始值
    
    // 后续流水级信息
    input EXE_valid,                   // EXE级有效
    input MEM_valid,                   // MEM级有效
    input WB_valid,                    // WB级有效
    
    input [4:0] EXE_wdest,             // EXE级写回目标寄存器
    input [4:0] MEM_wdest,             // MEM级写回目标寄存器
    input [4:0] WB_wdest,              // WB级写回目标寄存器
    
    input [31:0] EXE_result,           // EXE级结果
    input [31:0] MEM_result,           // MEM级结果
    input [31:0] WB_result,            // WB级结果
    
    // 指令类型信息（用于特殊处理）
    input inst_load,                   // 当前指令Load指令
    input inst_mult,                   // 当前指令乘法指令
    input inst_mfhi,                   // 当前指令MFHI指令
    input inst_mflo,                   // 当前指令MFLO指令
    input inst_mfc0,                   // 当前指令MFC0指令
    
    // EXE级指令类型信息（用于Load-Use相关检测）
    input EXE_inst_load,               // EXE级Load指令
    input EXE_inst_mult,               // EXE级乘法指令
    
    // 旁路结果输出
    output [31:0] bypassed_rs_value,   // 旁路后的rs值
    output [31:0] bypassed_rt_value,   // 旁路后的rt值
    
    // 控制信号输出
    output stall_required,             // 需要阻塞信号
    output rs_bypass_valid,            // rs旁路有效
    output rt_bypass_valid,            // rt旁路有效
    output [1:0] rs_bypass_source,     // rs旁路源 (00:无, 01:EXE, 10:MEM, 11:WB)
    output [1:0] rt_bypass_source      // rt旁路源 (00:无, 01:EXE, 10:MEM, 11:WB)
);

// 旁路检测逻辑
// 优先级：EXE > MEM > WB > 寄存器堆

// RS寄存器旁路检测
wire exe_bypass_rs = EXE_valid & (rs != 5'd0) & (rs == EXE_wdest);
wire mem_bypass_rs = MEM_valid & (rs != 5'd0) & (rs == MEM_wdest) & ~exe_bypass_rs;
wire wb_bypass_rs  = WB_valid & (rs != 5'd0) & (rs == WB_wdest) & ~exe_bypass_rs & ~mem_bypass_rs;

// RT寄存器旁路检测
wire exe_bypass_rt = EXE_valid & (rt != 5'd0) & (rt == EXE_wdest);
wire mem_bypass_rt = MEM_valid & (rt != 5'd0) & (rt == MEM_wdest) & ~exe_bypass_rt;
wire wb_bypass_rt  = WB_valid & (rt != 5'd0) & (rt == WB_wdest) & ~exe_bypass_rt & ~mem_bypass_rt;

// 旁路源编码
assign rs_bypass_source = exe_bypass_rs ? 2'b01 :
                         mem_bypass_rs ? 2'b10 :
                         wb_bypass_rs  ? 2'b11 : 2'b00;
                         
assign rt_bypass_source = exe_bypass_rt ? 2'b01 :
                         mem_bypass_rt ? 2'b10 :
                         wb_bypass_rt  ? 2'b11 : 2'b00;

// 旁路有效信号
assign rs_bypass_valid = exe_bypass_rs | mem_bypass_rs | wb_bypass_rs;
assign rt_bypass_valid = exe_bypass_rt | mem_bypass_rt | wb_bypass_rt;

// 旁路数据选择
assign bypassed_rs_value = exe_bypass_rs ? EXE_result :
                          mem_bypass_rs ? MEM_result :
                          wb_bypass_rs  ? WB_result  : rs_value;

assign bypassed_rt_value = exe_bypass_rt ? EXE_result :
                          mem_bypass_rt ? MEM_result :
                          wb_bypass_rt  ? WB_result  : rt_value;

// 特殊情况的阻塞检测
// Load-Use相关：EXE级Load指令的结果需要2个周期才能获得
wire load_use_hazard_rs = exe_bypass_rs & EXE_inst_load;
wire load_use_hazard_rt = exe_bypass_rt & EXE_inst_load;

// 多周期操作相关：EXE级乘法指令需要多周期完成
wire mult_use_hazard_rs = exe_bypass_rs & EXE_inst_mult;
wire mult_use_hazard_rt = exe_bypass_rt & EXE_inst_mult;

// 需要阻塞的情况
assign stall_required = load_use_hazard_rs | load_use_hazard_rt | 
                       mult_use_hazard_rs | mult_use_hazard_rt;


endmodule
