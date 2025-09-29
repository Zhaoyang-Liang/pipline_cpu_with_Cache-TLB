`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: exe.v
//   > ����  :�弶��ˮCPU��ִ��ģ��
//   > ����  : LOONGSON
//   > ����  : 2016-04-14
//*************************************************************************
module exe(                         // ִ�м�
    input              EXE_valid,   // ִ�м���Ч�ź�
    input      [177:0] ID_EXE_bus_r,// ID->EXE����
    output             EXE_over,    // EXEģ��ִ�����
    output     [154:0] EXE_MEM_bus, // EXE->MEM����
    
     //5����ˮ����
     input             clk,       // ʱ��
     input             resetn,    // ��λ�ź�
     output     [  4:0] EXE_wdest,   // EXE��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
 
    //չʾPC
    output     [ 31:0] EXE_pc,

    // ǰ��ר���ź�
    input wire [4:0] MEM_to_EXEforeword_wdest, //MEM��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    input wire [4:0] WB_to_EXEforeword_wdest, //WB��Ҫд�ؼĴ����ѵ�Ŀ���ַ��

    input wire [31:0] MEM_to_EXEforeword_wdata, //MEM��Ҫд�ؼĴ����ѵ�����
    input wire [31:0] WB_to_EXEforeword_wdata //WB��Ҫд�ؼĴ����ѵ�����
);
//-----{ID->EXE����}begin
    //EXE��Ҫ�õ�����Ϣ
    wire multiply;            //�˷�
    wire mthi;             //MTHI
    wire mtlo;             //MTLO
    wire [11:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;

    //�ô���Ҫ�õ���load/store��Ϣ
    wire [3:0] mem_control;  //MEM��Ҫʹ�õĿ����ź�
    wire [31:0] store_data;  //store�����Ĵ������

    //д����Ҫ�õ�����Ϣ
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall��eret��д�ؼ�������Ĳ��� 
    wire       eret;
    wire       rf_wen;    //д�صļĴ���дʹ��
    wire [4:0] rf_wdest;  //д�ص�Ŀ�ļĴ���

    //pc
    wire [31:0] pc;

    //Դ�Ĵ���
    wire [4:0] rs;
    wire [4:0] rt;

    assign {multiply,
            mthi,
            mtlo,
            alu_control,
            alu_operand1,
            alu_operand2,
            mem_control,
            store_data,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            eret,
            rf_wen,
            rf_wdest,
            pc,
            rs,rt          } = ID_EXE_bus_r;
//-----{ID->EXE����}end



//-----{forward}begin
    wire [1:0] forward_a;
    wire [1:0] forward_b;
    foreword foreword_module(
        .clk(clk),
        .resetn(resetn),
        .rs(rs),
        .rt(rt),
        .MEM_wdest(MEM_to_EXEforeword_wdest),
        .WB_wdest(WB_to_EXEforeword_wdest),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // ǰ�ƺ��ALU������
    wire [31:0] alu_operand1_forwarded;
    wire [31:0] alu_operand2_forwarded;
    
    assign alu_operand1_forwarded = forward_a == 2'b10 ? MEM_to_EXEforeword_wdata :
                                   forward_a == 2'b01 ? WB_to_EXEforeword_wdata :
                                   alu_operand1;
    assign alu_operand2_forwarded = forward_b == 2'b10 ? MEM_to_EXEforeword_wdata :
                                   forward_b == 2'b01 ? WB_to_EXEforeword_wdata :
                                   alu_operand2;
//-----{forward}end

//-----{ALU}begin
    wire [31:0] alu_result;

    alu alu_module(
        .alu_control  (alu_control ),  // I, 12, ALU�����ź�
        .alu_src1     (alu_operand1_forwarded),  // I, 32, ALU������1��ǰ�ƺ�
        .alu_src2     (alu_operand2_forwarded),  // I, 32, ALU������2��ǰ�ƺ�
        .alu_result   (alu_result  )   // O, 32, ALU���
    );
//-----{ALU}end

//-----{�˷���}begin
    wire        mult_begin; 
    wire [63:0] product; 
    wire        mult_end;
    
    assign mult_begin = multiply & EXE_valid;
    multiply multiply_module (
        .clk       (clk       ),
        .mult_begin(mult_begin  ),
        .mult_op1  (alu_operand1_forwarded), 
        .mult_op2  (alu_operand2_forwarded),
        .product   (product   ),
        .mult_end  (mult_end  )
    );
//-----{�˷���}end

//-----{EXEִ�����}begin
    //����ALU����������1�Ŀ���ɣ�
    //�����ڳ˷���������Ҫ�������
    assign EXE_over = EXE_valid & (~multiply | mult_end);
//-----{EXEִ�����}end

//-----{EXEģ���destֵ}begin
   //ֻ����EXEģ����Чʱ����д��Ŀ�ļĴ����Ų�������
    assign EXE_wdest = rf_wdest & {5{EXE_valid}};
//-----{EXEģ���destֵ}end

//-----{EXE->MEM����}begin
    wire [31:0] exe_result;   //��exe����ȷ��������д�ؽ��
    wire [31:0] lo_result;
    wire        hi_write;
    wire        lo_write;
    //Ҫд��HI��ֵ����exe_result�����MULT��MTHIָ��,
    //Ҫд��LO��ֵ����lo_result�����MULT��MTLOָ��,
    assign exe_result = mthi     ? alu_operand1_forwarded :
                        mtc0     ? alu_operand2_forwarded : 
                        multiply ? product[63:32] : alu_result;
    assign lo_result  = mtlo ? alu_operand1_forwarded : product[31:0];
    assign hi_write   = multiply | mthi;
    assign lo_write   = multiply | mtlo;
    
    assign EXE_MEM_bus = {mem_control,store_data,          //load/store��Ϣ��store����
                          exe_result,                      //exe������
                          lo_result,                       //�˷���32λ���������
                          hi_write,lo_write,               //HI/LOдʹ�ܣ�����
                          mfhi,mflo,                       //WB���õ��ź�,����
                          mtc0,mfc0,cp0r_addr,syscall,eret,//WB���õ��ź�,����
                          rf_wen,rf_wdest,                 //WB���õ��ź�
                          pc  //PC
                          };                           
//-----{EXE->MEM����}end

//-----{չʾEXEģ���PCֵ}begin
    assign EXE_pc = pc;
//-----{չʾEXEģ���PCֵ}end
endmodule
