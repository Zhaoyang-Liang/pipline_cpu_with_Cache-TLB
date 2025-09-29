`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: multiply.v
//   > 描述  : 32位有符号数乘法器，采用移位累加法实现，支持流水线
//   > 作者  : LOONGSON
//   > 日期  : 2016-04-14
//*************************************************************************
module multiply(              // 乘法器模块
    input         clk,        // 时钟信号
    input         mult_begin, // 乘法开始信号
    input  [31:0] mult_op1,   // 乘法操作数1
    input  [31:0] mult_op2,   // 乘法操作数2
    output [63:0] product,    // 乘法结果
    output        mult_end    // 乘法结束信号
);

    reg mult_valid;
        // 乘数寄存器，右移一位
    reg  [31:0] multiplier;
    // mult_end为1表示乘法运算完成（multiplier为0且mult_valid为1）
    assign mult_end = mult_valid & ~(|multiplier); 
    always @(posedge clk)
    begin
        if (!mult_begin || mult_end)
        begin
            mult_valid <= 1'b0; // 未开始或已结束，mult_valid清零
        end
        else
        begin
            mult_valid <= 1'b1; // 开始乘法，mult_valid置位
        end
    end

    // 处理操作数的符号与绝对值
    wire        op1_sign;      // 操作数1符号位
    wire        op2_sign;      // 操作数2符号位
    wire [31:0] op1_absolute;  // 操作数1绝对值
    wire [31:0] op2_absolute;  // 操作数2绝对值
    assign op1_sign = mult_op1[31];
    assign op2_sign = mult_op2[31];
    assign op1_absolute = op1_sign ? (~mult_op1+1) : mult_op1;
    assign op2_absolute = op2_sign ? (~mult_op2+1) : mult_op2;

    // 被乘数寄存器，左移一位
    reg  [63:0] multiplicand;
    always @ (posedge clk)
    begin
        if (mult_valid)
        begin    // 乘法进行中，被乘数左移一位
            multiplicand <= {multiplicand[62:0],1'b0};
        end
        else if (mult_begin) 
        begin   // 乘法开始，初始化被乘数（低32位为op1绝对值）
            multiplicand <= {32'd0,op1_absolute};
        end
    end


    always @ (posedge clk)
    begin
        if (mult_valid)
        begin   // 乘法进行中，乘数右移一位
            multiplier <= {1'b0,multiplier[31:1]}; 
        end
        else if (mult_begin)
        begin   // 乘法开始，初始化乘数为op2绝对值
            multiplier <= op2_absolute; 
        end
    end
    
    // 部分积：如果当前乘数最低位为1，则加上被乘数，否则加0
    wire [63:0] partial_product;
    assign partial_product = multiplier[0] ? multiplicand : 64'd0;
    
    // 累加部分积，得到最终乘积
    reg [63:0] product_temp;
    always @ (posedge clk)
    begin
        if (mult_valid)
        begin
            product_temp <= product_temp + partial_product;
        end
        else if (mult_begin) 
        begin
            product_temp <= 64'd0;  // 乘法开始，累加器清零
        end
    end 
     
    // 记录结果符号
    reg product_sign;
    always @ (posedge clk)  // 乘法进行中，记录结果符号
    begin
        if (mult_valid)
        begin
              product_sign <= op1_sign ^ op2_sign;
        end
    end 
    // 输出最终乘积，若结果为负则取补码
    assign product = product_sign ? (~product_temp+1) : product_temp;
endmodule
