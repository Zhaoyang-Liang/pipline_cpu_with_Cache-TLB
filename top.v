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
`define ID_EXE_BUS_WIDTH    167
`define EXE_MEM_BUS_WIDTH   154
`define MEM_WB_BUS_WIDTH    118
`define JBR_BUS_WIDTH       33
`define EXC_BUS_WIDTH       33
