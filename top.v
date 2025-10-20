`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: top.v
//   > 描述  : 流水线CPU总线宽度宏定义文件
//   > 作者  : 
//   > 日期  : 
//*************************************************************************

// 总线宽度宏定义
// 用于统一管理所有流水线级间总线的位宽，便于维护和修改

// IF->ID总线: {pc[31:0], inst[31:0]}
`define IF_ID_BUS_WIDTH     64

// ID->EXE总线: {multiply, mthi, mtlo, alu_control[11:0], alu_operand1[31:0], alu_operand2[31:0], 
//               mem_control[3:0], store_data[31:0], mfhi, mflo, mtc0, mfc0, cp0r_addr[7:0], 
//               syscall, eret, rf_wen, rf_wdest[4:0], pc[31:0]}
// 位宽计算: 1+1+1+12+32+32+4+32+1+1+1+1+8+1+1+1+5+32 = 167
`define ID_EXE_BUS_WIDTH    167

// EXE->MEM总线: {mem_control[3:0], store_data[31:0], exe_result[31:0], lo_result[31:0], 
//                hi_write, lo_write, mfhi, mflo, mtc0, mfc0, cp0r_addr[7:0], 
//                syscall, eret, rf_wen, rf_wdest[4:0], pc[31:0]}
// 位宽计算: 4+32+32+32+1+1+1+1+1+1+8+1+1+1+5+32 = 154
`define EXE_MEM_BUS_WIDTH   154

// MEM->WB总线: {rf_wen, rf_wdest[4:0], mem_result[31:0], lo_result[31:0], 
//               hi_write, lo_write, mfhi, mflo, mtc0, mfc0, cp0r_addr[7:0], 
//               syscall, eret, pc[31:0]}
// 位宽计算: 1+5+32+32+1+1+1+1+1+1+8+1+1+32 = 118
`define MEM_WB_BUS_WIDTH    118

// 跳转总线: {jbr_taken, jbr_target[31:0]}
// 位宽计算: 1+32 = 33
`define JBR_BUS_WIDTH       33

// 异常总线: {exc_valid, exc_pc[31:0]}
// 位宽计算: 1+32 = 33
`define EXC_BUS_WIDTH       33
