`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: bypass_unit.v
//   > ����  : ��ˮ��CPU��·��ⵥԪ
//   > ����  : 
//   > ����  : 
//*************************************************************************



module bypass_unit(
    // ��ǰָ����Ϣ
    input [4:0] rs,                    // Դ�Ĵ���1��ַ
    input [4:0] rt,                    // Դ�Ĵ���2��ַ
    input [31:0] rs_value,             // Դ�Ĵ���1ԭʼֵ
    input [31:0] rt_value,             // Դ�Ĵ���2ԭʼֵ
    
    // ������ˮ����Ϣ
    input EXE_valid,                   // EXE����Ч
    input MEM_valid,                   // MEM����Ч
    input WB_valid,                    // WB����Ч
    
    input [4:0] EXE_wdest,             // EXE��д��Ŀ��Ĵ���
    input [4:0] MEM_wdest,             // MEM��д��Ŀ��Ĵ���
    input [4:0] WB_wdest,              // WB��д��Ŀ��Ĵ���
    
    input [31:0] EXE_result,           // EXE�����
    input [31:0] MEM_result,           // MEM�����
    input [31:0] WB_result,            // WB�����
    
    // ָ��������Ϣ���������⴦��
    input inst_load,                   // ��ǰָ��Loadָ��
    input inst_mult,                   // ��ǰָ��˷�ָ��
    input inst_mfhi,                   // ��ǰָ��MFHIָ��
    input inst_mflo,                   // ��ǰָ��MFLOָ��
    input inst_mfc0,                   // ��ǰָ��MFC0ָ��
    
    // EXE��ָ��������Ϣ������Load-Use��ؼ�⣩
    input EXE_inst_load,               // EXE��Loadָ��
    input EXE_inst_mult,               // EXE���˷�ָ��
    
    // ��·������
    output [31:0] bypassed_rs_value,   // ��·���rsֵ
    output [31:0] bypassed_rt_value,   // ��·���rtֵ
    
    // �����ź����
    output stall_required,             // ��Ҫ�����ź�
    output rs_bypass_valid,            // rs��·��Ч
    output rt_bypass_valid,            // rt��·��Ч
    output [1:0] rs_bypass_source,     // rs��·Դ (00:��, 01:EXE, 10:MEM, 11:WB)
    output [1:0] rt_bypass_source      // rt��·Դ (00:��, 01:EXE, 10:MEM, 11:WB)
);

// ��·����߼�
// ���ȼ���EXE > MEM > WB > �Ĵ�����

// RS�Ĵ�����·���
wire exe_bypass_rs = EXE_valid & (rs != 5'd0) & (rs == EXE_wdest);
wire mem_bypass_rs = MEM_valid & (rs != 5'd0) & (rs == MEM_wdest) & ~exe_bypass_rs;
wire wb_bypass_rs  = WB_valid & (rs != 5'd0) & (rs == WB_wdest) & ~exe_bypass_rs & ~mem_bypass_rs;

// RT�Ĵ�����·���
wire exe_bypass_rt = EXE_valid & (rt != 5'd0) & (rt == EXE_wdest);
wire mem_bypass_rt = MEM_valid & (rt != 5'd0) & (rt == MEM_wdest) & ~exe_bypass_rt;
wire wb_bypass_rt  = WB_valid & (rt != 5'd0) & (rt == WB_wdest) & ~exe_bypass_rt & ~mem_bypass_rt;

// ��·Դ����
assign rs_bypass_source = exe_bypass_rs ? 2'b01 :
                         mem_bypass_rs ? 2'b10 :
                         wb_bypass_rs  ? 2'b11 : 2'b00;
                         
assign rt_bypass_source = exe_bypass_rt ? 2'b01 :
                         mem_bypass_rt ? 2'b10 :
                         wb_bypass_rt  ? 2'b11 : 2'b00;

// ��·��Ч�ź�
assign rs_bypass_valid = exe_bypass_rs | mem_bypass_rs | wb_bypass_rs;
assign rt_bypass_valid = exe_bypass_rt | mem_bypass_rt | wb_bypass_rt;

// ��·����ѡ��
assign bypassed_rs_value = exe_bypass_rs ? EXE_result :
                          mem_bypass_rs ? MEM_result :
                          wb_bypass_rs  ? WB_result  : rs_value;

assign bypassed_rt_value = exe_bypass_rt ? EXE_result :
                          mem_bypass_rt ? MEM_result :
                          wb_bypass_rt  ? WB_result  : rt_value;

// ����������������
// Load-Use��أ�EXE��Loadָ��Ľ����Ҫ2�����ڲ��ܻ��
wire load_use_hazard_rs = exe_bypass_rs & EXE_inst_load;
wire load_use_hazard_rt = exe_bypass_rt & EXE_inst_load;

// �����ڲ�����أ�EXE���˷�ָ����Ҫ���������
wire mult_use_hazard_rs = exe_bypass_rs & EXE_inst_mult;
wire mult_use_hazard_rt = exe_bypass_rt & EXE_inst_mult;

// ��Ҫ���������
assign stall_required = load_use_hazard_rs | load_use_hazard_rt | 
                       mult_use_hazard_rs | mult_use_hazard_rt;


endmodule
