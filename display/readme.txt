好的，逐文件用途简述如下（按目录列）：

- adder.v：32 位加/减子模块，被 ALU 复用实现加、减、比较。
- alu.v：算术逻辑单元，支持加减、与或异或、取反、移位、SLT/SLTU、LUI。
- data_ram.v：数据存储器（Xilinx BRAM 包装，支持字节写），CPU 的数据 RAM。
- inst_rom.v：指令存储器（Xilinx BRAM 包装，加载 `inst_rom.mif`）。
- decode.v：ID 译码阶段，指令解析、控制信号生成、分支/跳转决定、冒险停顿判断，打包到 ID→EXE 总线。
- exe.v：EXE 执行阶段，ALU 运算、乘法控制（与 `multiply.v`），生成 HI/LO 写使能和 exe 结果，打包到 EXE→MEM 总线。
- mem.v：MEM 访存阶段，LW/LB/LBU/SW/SB 实际读写与字节对齐/符号扩展，形成写回数据，打包到 MEM→WB 总线。
- wb.v：WB 写回阶段，写寄存器堆；管理 HI/LO；最小 CP0（STATUS/CAUSE/EPC）、异常入口（SYSCALL/ERET）、向 IF 发异常 PC 与流水冲刷。
- fetch.v：IF 取指阶段，PC 生成（顺序/分支/异常），从指令 ROM 读出指令，打包到 IF→ID 总线。
- multiply.v：乘法器（多周期），提供 `product` 与结束信号给 EXE。
- regfile.v：32×32 寄存器堆，异步读双口、同步写单口，带测试读取口。
- pipeline_cpu.v：CPU 顶层，5 级流水握手控制（valid/over/allow_in）、级间寄存、异常/冲刷、实例化 ROM/RAM/寄存器堆与各级。
- pipeline_cpu_display.v：顶层演示与外设连接，按钮门控时钟、LCD 显示各阶段 PC、寄存器窗口、内存监视、HI/LO、valid 等。
- pipeline_cpu.xdc：FPGA 约束文件（引脚/时序等）。
- tb.v 或 testbench.v：仿真测试平台，生成时钟复位、实例化 `pipeline_cpu` 做基础仿真。
- pipeline_inst/inst_rom.mif、inst_pipeline.coe：指令存储的初始化文件与 COE；文档说明测试程序。
- inst_rom.mif（根目录）：另一份指令 ROM 初始化文件。
- data_ram.ngc、inst_rom.ngc：综合生成的网表/核心文件（IP 产物，供实现用）。
- pipeline_cpu_display.v 中还依赖 `lcd_module`（未在本目录，通常为外设驱动模块）。

需要我再画个模块依赖关系图，或标出级间总线各字段含义对照吗？