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
`define ID_EXE_BUS_WIDTH    167
`define EXE_MEM_BUS_WIDTH   154
`define MEM_WB_BUS_WIDTH    118
`define JBR_BUS_WIDTH       33
`define EXC_BUS_WIDTH       33
