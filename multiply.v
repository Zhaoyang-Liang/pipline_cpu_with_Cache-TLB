`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: multiply.v
//   > ����  : 32λ�з������˷�����������λ�ۼӷ�ʵ�֣�֧����ˮ��
//   > ����  : LOONGSON
//   > ����  : 2016-04-14
//*************************************************************************
module multiply(              // �˷���ģ��
    input         clk,        // ʱ���ź�
    input         mult_begin, // �˷���ʼ�ź�
    input  [31:0] mult_op1,   // �˷�������1
    input  [31:0] mult_op2,   // �˷�������2
    output [63:0] product,    // �˷����
    output        mult_end    // �˷������ź�
);

    reg mult_valid;
        // �����Ĵ���������һλ
    reg  [31:0] multiplier;
    // mult_endΪ1��ʾ�˷�������ɣ�multiplierΪ0��mult_validΪ1��
    assign mult_end = mult_valid & ~(|multiplier); 
    always @(posedge clk)
    begin
        if (!mult_begin || mult_end)
        begin
            mult_valid <= 1'b0; // δ��ʼ���ѽ�����mult_valid����
        end
        else
        begin
            mult_valid <= 1'b1; // ��ʼ�˷���mult_valid��λ
        end
    end

    // ����������ķ��������ֵ
    wire        op1_sign;      // ������1����λ
    wire        op2_sign;      // ������2����λ
    wire [31:0] op1_absolute;  // ������1����ֵ
    wire [31:0] op2_absolute;  // ������2����ֵ
    assign op1_sign = mult_op1[31];
    assign op2_sign = mult_op2[31];
    assign op1_absolute = op1_sign ? (~mult_op1+1) : mult_op1;
    assign op2_absolute = op2_sign ? (~mult_op2+1) : mult_op2;

    // �������Ĵ���������һλ
    reg  [63:0] multiplicand;
    always @ (posedge clk)
    begin
        if (mult_valid)
        begin    // �˷������У�����������һλ
            multiplicand <= {multiplicand[62:0],1'b0};
        end
        else if (mult_begin) 
        begin   // �˷���ʼ����ʼ������������32λΪop1����ֵ��
            multiplicand <= {32'd0,op1_absolute};
        end
    end


    always @ (posedge clk)
    begin
        if (mult_valid)
        begin   // �˷������У���������һλ
            multiplier <= {1'b0,multiplier[31:1]}; 
        end
        else if (mult_begin)
        begin   // �˷���ʼ����ʼ������Ϊop2����ֵ
            multiplier <= op2_absolute; 
        end
    end
    
    // ���ֻ��������ǰ�������λΪ1������ϱ������������0
    wire [63:0] partial_product;
    assign partial_product = multiplier[0] ? multiplicand : 64'd0;
    
    // �ۼӲ��ֻ����õ����ճ˻�
    reg [63:0] product_temp;
    always @ (posedge clk)
    begin
        if (mult_valid)
        begin
            product_temp <= product_temp + partial_product;
        end
        else if (mult_begin) 
        begin
            product_temp <= 64'd0;  // �˷���ʼ���ۼ�������
        end
    end 
     
    // ��¼�������
    reg product_sign;
    always @ (posedge clk)  // �˷������У���¼�������
    begin
        if (mult_valid)
        begin
              product_sign <= op1_sign ^ op2_sign;
        end
    end 
    // ������ճ˻��������Ϊ����ȡ����
    assign product = product_sign ? (~product_temp+1) : product_temp;
endmodule
