`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: top.v
//   > ����  : ��ˮ��CPU���߿�Ⱥ궨���ļ�
//   > ����  : 
//   > ����  : 
//*************************************************************************

// ���߿�Ⱥ궨��
// ����ͳһ����������ˮ�߼������ߵ�λ������ά�����޸�

// IF->ID����: {pc[31:0], inst[31:0]}
`define IF_ID_BUS_WIDTH     64

// ID->EXE����: {multiply, mthi, mtlo, alu_control[11:0], alu_operand1[31:0], alu_operand2[31:0], 
//               mem_control[3:0], store_data[31:0], mfhi, mflo, mtc0, mfc0, cp0r_addr[7:0], 
//               syscall, eret, rf_wen, rf_wdest[4:0], pc[31:0]}
// λ�����: 1+1+1+12+32+32+4+32+1+1+1+1+8+1+1+1+5+32 = 167
`define ID_EXE_BUS_WIDTH    167

// EXE->MEM����: {mem_control[3:0], store_data[31:0], exe_result[31:0], lo_result[31:0], 
//                hi_write, lo_write, mfhi, mflo, mtc0, mfc0, cp0r_addr[7:0], 
//                syscall, eret, rf_wen, rf_wdest[4:0], pc[31:0]}
// λ�����: 4+32+32+32+1+1+1+1+1+1+8+1+1+1+5+32 = 154
`define EXE_MEM_BUS_WIDTH   154

// MEM->WB����: {rf_wen, rf_wdest[4:0], mem_result[31:0], lo_result[31:0], 
//               hi_write, lo_write, mfhi, mflo, mtc0, mfc0, cp0r_addr[7:0], 
//               syscall, eret, pc[31:0]}
// λ�����: 1+5+32+32+1+1+1+1+1+1+8+1+1+32 = 118
`define MEM_WB_BUS_WIDTH    118

// ��ת����: {jbr_taken, jbr_target[31:0]}
// λ�����: 1+32 = 33
`define JBR_BUS_WIDTH       33

// �쳣����: {exc_valid, exc_pc[31:0]}
// λ�����: 1+32 = 33
`define EXC_BUS_WIDTH       33
