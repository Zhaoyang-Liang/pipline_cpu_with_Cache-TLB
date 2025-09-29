`timescale 1ns / 1ps

/**
 * ID->EXE����
 *     assign ID_EXE_bus = {multiply,mthi,mtlo,                   //EXE���õ���Ϣ,����
                         alu_control,alu_operand1,alu_operand2,//EXE���õ���Ϣ
                         mem_control,store_data,               //MEM���õ��ź�
                         mfhi,mflo,                            //WB���õ��ź�,����
                         mtc0,mfc0,cp0r_addr,syscall,eret,     //WB���õ��ź�,����
                         rf_wen, rf_wdest,                     //WB���õ��ź�
                         pc};        
    EXE->MEM����
    assign EXE_MEM_bus = {mem_control,store_data,          //load/store��Ϣ��store����
                          exe_result,                      //exe������
                          lo_result,                       //�˷���32λ���������
                          hi_write,lo_write,               //HI/LOдʹ�ܣ�����
                          mfhi,mflo,                       //WB���õ��ź�,����
                          mtc0,mfc0,cp0r_addr,syscall,eret,//WB���õ��ź�,����
                          rf_wen,rf_wdest,                 //WB���õ��ź�
                          pc};      
 */


module foreword(
    input clk,
    input resetn,
    input [4:0] rs,
    input [4:0] rt,

    input wire [4:0] MEM_wdest, //MEM��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    input wire [4:0] WB_wdest, //WB��Ҫд�ؼĴ����ѵ�Ŀ���ַ��

    output wire [1:0] forward_a,
    output wire [1:0] forward_b
);

// ǰ���߼������MEM��WB�׶��Ƿ���ָ��д�뵱ǰָ����Ҫ�ļĴ���
// ��Ҫ����������͵�д��ָ���������д��rd��ָ��
assign forward_a = (rs!=5'd0 && MEM_wdest != 5'd0 && MEM_wdest == rs) ? 2'b10 :  // MEM��ǰ��rs
                   (rs!=5'd0 && WB_wdest != 5'd0 && WB_wdest == rs) ? 2'b01 :   // WB��ǰ��rs
                   2'b00;
        // forward_a ���ڿ���rs ������������Ҫ��һ�����ڣ�MEM�׶Σ���ֵʱ����Ҫǰ��MEM��ֵ��forward �����ź�10�������Ҫǰ���������ڣ������ź�01

assign forward_b = (rt!=5'd0 && MEM_wdest != 5'd0 && MEM_wdest == rt) ? 2'b10 :  // MEM��ǰ��rt
                   (rt!=5'd0 && WB_wdest != 5'd0 && WB_wdest == rt) ? 2'b01 :   // WB��ǰ��rt
                   2'b00;

endmodule