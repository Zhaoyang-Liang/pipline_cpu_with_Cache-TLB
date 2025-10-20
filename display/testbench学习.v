// ====================== 模块声明 ======================
module tb_module_name;  // Testbench 模块名（无端口）

// ====================== 信号声明 ======================
reg clk;       // 时钟信号（Testbench 内部生成）//reg clk, rst_n, din;     // 需要主动驱动的信号用reg
reg rst_n;     // 复位信号（低有效）
reg [7:0] din;  // DUT 输入（若直接连接，可声明为 wire）
wire [7:0] dout;// DUT 输出// // 只用于观测的信号用wire

// ====================== 实例化 DUT ======================
dut uut (           // 将 DUT 实例化为 uut（User Test Unit） //Design Under Test
    .clk(clk),     // 连接时钟
    .rst_n(rst_n), // 连接复位
    .din(din),     // 连接输入（若 Testbench 主动驱动 din，需改为 reg 类型）
    .dout(dout)    // 连接输出（观测用，保持 wire）
);

// ====================== 生成时钟 ======================
initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 周期 20ns（50MHz 时钟）
end

// ====================== 生成复位 ======================
initial begin
    rst_n = 0;          // 初始复位（低有效）
    #100;               // 保持复位 100ns
    rst_n = 1;          // 释放复位
    #2000;              // 测试持续 2000ns
    $finish;            // 结束仿真
end

// ====================== 驱动输入激励 ======================
initial begin
    // 等待复位释放后再发送数据
    @(posedge rst_n);   // 等待复位变高
    
    // 发送测试数据（示例：8 位计数器）
    repeat(10) begin    // 发送 10 个数据
        @(posedge clk); // 在时钟上升沿驱动
        din = $random;  // 随机生成 8 位数据（$random 是仿真函数）
    end
    
    #500;               // 等待一段时间
    $finish;            // 结束仿真
end

// ====================== 观测输出并验证 ======================
initial begin
    // 等待复位释放和数据稳定
    #300;
    
    // 循环检查输出（示例：假设 dout 应等于 din 延迟 2 个时钟周期）
    forever begin
        @(posedge clk);
        if (dout !== din) begin  // 比较输出（!== 是 Verilog 的非阻塞比较）
            $display("Error: Time=%t, din=%h, dout=%h", $time, din, dout);
            $finish;           // 出错时终止仿真
        end
    end
end

endmodule  // 结束 Testbench 模块