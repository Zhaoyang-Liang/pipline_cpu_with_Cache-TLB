// ====================== ģ������ ======================
module tb_module_name;  // Testbench ģ�������޶˿ڣ�

// ====================== �ź����� ======================
reg clk;       // ʱ���źţ�Testbench �ڲ����ɣ�//reg clk, rst_n, din;     // ��Ҫ�����������ź���reg
reg rst_n;     // ��λ�źţ�����Ч��
reg [7:0] din;  // DUT ���루��ֱ�����ӣ�������Ϊ wire��
wire [7:0] dout;// DUT ���// // ֻ���ڹ۲���ź���wire

// ====================== ʵ���� DUT ======================
dut uut (           // �� DUT ʵ����Ϊ uut��User Test Unit�� //Design Under Test
    .clk(clk),     // ����ʱ��
    .rst_n(rst_n), // ���Ӹ�λ
    .din(din),     // �������루�� Testbench �������� din�����Ϊ reg ���ͣ�
    .dout(dout)    // ����������۲��ã����� wire��
);

// ====================== ����ʱ�� ======================
initial begin
    clk = 0;
    forever #10 clk = ~clk;  // ���� 20ns��50MHz ʱ�ӣ�
end

// ====================== ���ɸ�λ ======================
initial begin
    rst_n = 0;          // ��ʼ��λ������Ч��
    #100;               // ���ָ�λ 100ns
    rst_n = 1;          // �ͷŸ�λ
    #2000;              // ���Գ��� 2000ns
    $finish;            // ��������
end

// ====================== �������뼤�� ======================
initial begin
    // �ȴ���λ�ͷź��ٷ�������
    @(posedge rst_n);   // �ȴ���λ���
    
    // ���Ͳ������ݣ�ʾ����8 λ��������
    repeat(10) begin    // ���� 10 ������
        @(posedge clk); // ��ʱ������������
        din = $random;  // ������� 8 λ���ݣ�$random �Ƿ��溯����
    end
    
    #500;               // �ȴ�һ��ʱ��
    $finish;            // ��������
end

// ====================== �۲��������֤ ======================
initial begin
    // �ȴ���λ�ͷź������ȶ�
    #300;
    
    // ѭ����������ʾ�������� dout Ӧ���� din �ӳ� 2 ��ʱ�����ڣ�
    forever begin
        @(posedge clk);
        if (dout !== din) begin  // �Ƚ������!== �� Verilog �ķ������Ƚϣ�
            $display("Error: Time=%t, din=%h, dout=%h", $time, din, dout);
            $finish;           // ����ʱ��ֹ����
        end
    end
end

endmodule  // ���� Testbench ģ��