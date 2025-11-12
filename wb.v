`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: wb.v
//   > 描述  :五级流水CPU的写回模块
//   > 作者  : LOONGSON
//   > 日期  : 2016-04-14
//*************************************************************************
module wb(                       // 写回级
    input          WB_valid,     // 写回级有效
    input  [152:0] MEM_WB_bus_r, // MEM->WB总线
    output         rf_wen,       // 寄存器写使能
    output [  4:0] rf_wdest,     // 寄存器写地址
    output [ 31:0] rf_wdata,     // 寄存器写数据
    output         WB_over,      // WB模块执行完成

     //5级流水新增接口
    input             clk,       // 时钟
    input             resetn,    // 复位信号，低电平有效
    output [ 32:0] exc_bus,      // Exception pc总线
    output [  4:0] WB_wdest,     // WB级要写回寄存器堆的目标地址号
    output         cancel,       // syscall和eret到达写回级时会发出cancel信号，
                                  // 取消已经取出的正在其他流水级执行的指令
 
    // 新增旁路数据输出
    output     [ 31:0] WB_result,   // WB级结果，用于旁路

     //展示PC和HI/LO值
    output [ 31:0] WB_pc,
    output [ 31:0] HI_data,
    output [ 31:0] LO_data,

    // 观察CP0寄存器（用于调试/显示）
    output [ 31:0] cp0_status,
    output [ 31:0] cp0_cause,
    output [ 31:0] cp0_epc
);
//-----{MEM->WB总线}begin    
    //MEM传来的result
    wire [31:0] mem_result;
    //HI/LO数据
    wire [31:0] lo_result;
    wire        hi_write;
    wire        lo_write;
    
    //寄存器堆写使能和写地址
    wire wen;
    wire [4:0] wdest;
    
    //写回需要用到的信息
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall和eret在写回级有特殊的操作 
    wire       eret;
    
    //pc
    wire [31:0] pc;    
    wire        mem_ex_adel_wb;
    wire        mem_ex_ades_wb;
    wire [31:0] mem_badvaddr_wb;
    wire        brk_wb;
    assign {wen,
            wdest,
            mem_result,
            lo_result,
            hi_write,
            lo_write,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            brk_wb,
            eret,
            mem_ex_adel_wb,
            mem_ex_ades_wb,
            mem_badvaddr_wb,
            pc} = MEM_WB_bus_r;
//-----{MEM->WB总线}end

//-----{HI/LO寄存器}begin
    //HI用于存放乘法结果的高32位
    //LO用于存放乘法结果的低32位
    reg [31:0] hi;
    reg [31:0] lo;
    
    //要写入HI的数据存放在mem_result里
    always @(posedge clk)
    begin
        if (hi_write)
        begin
            hi <= mem_result;
        end
    end
    //要写入LO的数据存放在lo_result里
    always @(posedge clk)
    begin
        if (lo_write)
        begin
            lo <= lo_result;
        end
    end
//-----{HI/LO寄存器}end


// //-----{cp0寄存器}begin
// // cp0寄存器即是协处理器0寄存器
// // 由于目前设计的CPU并不完备，所用到的cp0寄存器也很少
// // 故暂时只实现STATUS(12.0),CAUSE(13.0),EPC(14.0)这三个
// // 每个CP0寄存器都是使用5位的cp0号
//    wire [31:0] cp0r_status;
//    wire [31:0] cp0r_cause;
//    wire [31:0] cp0r_epc;
   
//    //写使能
//    wire status_wen;
//    //wire cause_wen;
//    wire epc_wen;
//    assign status_wen = mtc0 & (cp0r_addr=={5'd12,3'd0});
//    assign epc_wen    = mtc0 & (cp0r_addr=={5'd14,3'd0});
   
//    //cp0寄存器读
//    wire [31:0] cp0r_rdata;
//    assign cp0r_rdata = (cp0r_addr=={5'd12,3'd0}) ? cp0r_status :
//                        (cp0r_addr=={5'd13,3'd0}) ? cp0r_cause  :
//                        (cp0r_addr=={5'd14,3'd0}) ? cp0r_epc : 32'd0;
   
//    //STATUS寄存器
//    //目前只实现STATUS[1]位，即EXL域
//    //EXL域为软件可读写，故需要statu_wen
//    reg status_exl_r;
//    assign cp0r_status = {30'd0,status_exl_r,1'b0};
//    always @(posedge clk)
//    begin
//        if (!resetn || eret)
//        begin
//            status_exl_r <= 1'b0;
//        end
//        else if (syscall)
//        begin
//            status_exl_r <= 1'b1;
//        end
//        else if (status_wen)
//        begin
//            status_exl_r <= mem_result[1];
//        end
//    end
   
//    //CAUSE寄存器
//    //目前只实现CAUSE[6:2]位，即ExcCode域,存放Exception编码
//    //ExcCode域为软件只读，不可写，故不需要cause_wen
//    reg [4:0] cause_exc_code_r;
//    assign cp0r_cause = {25'd0,cause_exc_code_r,2'd0};
//    always @(posedge clk)
//    begin
//        if (syscall)
//        begin
//            cause_exc_code_r <= 5'd8;
//        end
//    end
   
//    //EPC寄存器
//    //存放产生例外的地址
//    //EPC整个域为软件可读写的，故需要epc_wen
//    reg [31:0] epc_r;
//    assign cp0r_epc = epc_r;
//    always @(posedge clk)
//    begin
//        if (syscall)
//        begin
//            epc_r <= pc;
//        end
//        else if (epc_wen)
//        begin
//            epc_r <= mem_result;
//        end
//    end
   
//    //syscall和eret发出的cancel信号
//    assign cancel = (syscall | eret) & WB_over;
// //-----{cp0寄存器}begin

//-----{CP0模块实例化}begin-----
   // CP0寄存器读数据
   wire [31:0] cp0r_rdata;
   // CP0寄存器值（用于异常处理）
   wire [31:0] cp0r_status;
   wire [31:0] cp0r_cause;
   wire [31:0] cp0r_epc;
   // CP0输出的异常处理信号
   wire        cp0_cancel;
   wire        cp0_exc_valid;
   wire [31:0] cp0_exc_pc;
   wire        cp0_int;      // CP0中断信号
   
   // 统一异常总线信号声明（先声明再使用）
   wire        wb_ex_valid;
   wire [4:0]  wb_ex_code;
   wire        wb_ex_bd;
   wire [31:0] wb_ex_pc;
   wire        wb_badvaddr_valid;
   wire [31:0] wb_badvaddr;
   
   // 异常仲裁逻辑（优先级：中断 > 地址错 > BREAK > SYSCALL）
   // 注意：中断由CP0模块检测，通过c0_int信号传递
   // 由于cp0_int在CP0实例化后才可用，这里先计算非中断异常，然后在CP0实例化后合并中断
   assign wb_badvaddr_valid   = (mem_ex_adel_wb | mem_ex_ades_wb);
   assign wb_badvaddr         = mem_badvaddr_wb;
   
   // 非中断异常（地址错、BREAK、SYSCALL）
   wire        wb_ex_valid_no_int;
   wire [4:0]  wb_ex_code_no_int;
   assign wb_ex_valid_no_int  = (mem_ex_adel_wb | mem_ex_ades_wb | brk_wb | syscall) ? WB_valid : 1'b0;
   assign wb_ex_code_no_int    = mem_ex_adel_wb ? 5'd4 :
                                mem_ex_ades_wb ? 5'd5 :
                                brk_wb ? 5'd9 :
                                5'd8; // SYSCALL
   
   cp0 cp0_module(
       .clk         (clk         ),  // I, 1
       .resetn      (resetn      ),  // I, 1
       .mtc0        (mtc0        ),  // I, 1
       .mfc0        (mfc0        ),  // I, 1
       .cp0r_addr   (cp0r_addr   ),  // I, 8
       .wdata       (mem_result  ),  // I, 32
       .syscall     (syscall     ),  // I, 1
       .eret        (eret        ),  // I, 1
       .pc          (pc          ),  // I, 32
       .wb_valid    (WB_valid    ),  // I, 1
       .wb_over     (WB_over     ),  // I, 1
       // 统一异常总线
       .ex_valid_i        (wb_ex_valid       ), // I, 1
       .ex_code_i         (wb_ex_code        ), // I, 5
       .ex_bd_i           (wb_ex_bd          ), // I, 1
       .ex_pc_i           (wb_ex_pc          ), // I, 32
       .badvaddr_valid_i  (wb_badvaddr_valid ), // I, 1
       .badvaddr_i        (wb_badvaddr       ), // I, 32
       .cp0r_rdata  (cp0r_rdata  ),  // O, 32
       .cancel      (cp0_cancel  ),  // O, 1
       .exc_valid   (cp0_exc_valid), // O, 1
       .exc_pc      (cp0_exc_pc  ),  // O, 32
       .cp0r_status (cp0r_status ),  // O, 32
       .cp0r_cause  (cp0r_cause  ),  // O, 32
       .cp0r_epc    (cp0r_epc    ),  // O, 32
       .c0_int      (cp0_int     )   // O, 1  // 中断信号
   );
   
   // 将CP0的cancel信号连接到WB的cancel输出
   assign cancel = cp0_cancel;
   
   // 最终异常仲裁（包含中断，中断优先级最高）
   // 注意：cp0_int现在已可用（CP0模块已实例化）
   // wb_ex_valid_no_int已经包含了WB_valid，所以这里只需要或上cp0_int的情况
   assign wb_ex_valid = (cp0_int && WB_valid) | wb_ex_valid_no_int;
   assign wb_ex_code  = cp0_int ? 5'd0 : wb_ex_code_no_int;  // 中断异常码为0
   assign wb_ex_bd    = 1'b0;       // 延迟槽后续接入
   assign wb_ex_pc    = pc;         // 异常PC（地址错与syscall均取当前pc）
//-----{CP0模块实例化}end-----

//-----{WB执行完成}begin
    //WB模块所有操作都可在一拍内完成
    //故WB_valid即是WB_over信号
    assign WB_over = WB_valid;
//-----{WB执行完成}end

//-----{WB->regfile信号}begin
    assign rf_wen   = wen & WB_over;
    assign rf_wdest = wdest;
    assign rf_wdata = mfhi ? hi :
                      mflo ? lo :
                      mfc0 ? cp0r_rdata : mem_result;

    assign WB_result = rf_wdata;  // ! 旁路输出
//-----{WB->regfile信号}end


//-----{Exception pc信号}begin-----
    // 异常总线：{异常有效信号, 异常PC地址}
    // 异常处理逻辑已封装在CP0模块中
    assign exc_bus = {cp0_exc_valid, cp0_exc_pc};
//-----{Exception pc信号}end-----

//-----{WB模块的dest值}begin
   //只有在WB模块有效时，其写回目的寄存器号才有意义
    assign WB_wdest = rf_wdest & {5{WB_valid}};
//-----{WB模块的dest值}end

//-----{展示WB模块的PC值和HI/LO寄存器的值}begin
    assign WB_pc = pc;
    assign HI_data = hi;
    assign LO_data = lo;
//-----{展示WB模块的PC值和HI/LO寄存器的值}end

//-----{导出CP0寄存器用于观察}begin
    assign cp0_status = cp0r_status;
    assign cp0_cause  = cp0r_cause;
    assign cp0_epc    = cp0r_epc;
//-----{导出CP0寄存器用于观察}end
endmodule

