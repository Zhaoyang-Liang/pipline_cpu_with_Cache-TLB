`timescale 1ns / 1ps

/**
 * ID->EXE总线
 *     assign ID_EXE_bus = {multiply,mthi,mtlo,                   //EXE需用的信息,新增
                         alu_control,alu_operand1,alu_operand2,//EXE需用的信息
                         mem_control,store_data,               //MEM需用的信号
                         mfhi,mflo,                            //WB需用的信号,新增
                         mtc0,mfc0,cp0r_addr,syscall,eret,     //WB需用的信号,新增
                         rf_wen, rf_wdest,                     //WB需用的信号
                         pc};        
    EXE->MEM总线
    assign EXE_MEM_bus = {mem_control,store_data,          //load/store信息和store数据
                          exe_result,                      //exe运算结果
                          lo_result,                       //乘法低32位结果，新增
                          hi_write,lo_write,               //HI/LO写使能，新增
                          mfhi,mflo,                       //WB需用的信号,新增
                          mtc0,mfc0,cp0r_addr,syscall,eret,//WB需用的信号,新增
                          rf_wen,rf_wdest,                 //WB需用的信号
                          pc};      
 */


module foreword(
    input clk,
    input resetn,
    input [4:0] rs,
    input [4:0] rt,

    input wire [4:0] MEM_wdest, //MEM级要写回寄存器堆的目标地址号
    input wire [4:0] WB_wdest, //WB级要写回寄存器堆的目标地址号

    output wire [1:0] forward_a,
    output wire [1:0] forward_b
);

// 前推逻辑：检查MEM和WB阶段是否有指令写入当前指令需要的寄存器
// 需要检查所有类型的写入指令，不仅仅是写入rd的指令
assign forward_a = (rs!=5'd0 && MEM_wdest != 5'd0 && MEM_wdest == rs) ? 2'b10 :  // MEM级前推rs
                   (rs!=5'd0 && WB_wdest != 5'd0 && WB_wdest == rs) ? 2'b01 :   // WB级前推rs
                   2'b00;
        // forward_a 用于控制rs 操作数，当需要上一个周期（MEM阶段）的值时，需要前推MEM的值，forward 给出信号10；如果需要前推两个周期，给出信号01

assign forward_b = (rt!=5'd0 && MEM_wdest != 5'd0 && MEM_wdest == rt) ? 2'b10 :  // MEM级前推rt
                   (rt!=5'd0 && WB_wdest != 5'd0 && WB_wdest == rt) ? 2'b01 :   // WB级前推rt
                   2'b00;

endmodule