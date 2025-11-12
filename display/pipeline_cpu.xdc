#时钟信号连接
set_property PACKAGE_PIN AC19 [get_ports clk]

#脉冲开关，用于输入作为复位信号，低电平有效
set_property PACKAGE_PIN Y3 [get_ports resetn]

#脉冲开关，用于输入作为单步执行的clk
set_property PACKAGE_PIN Y5 [get_ports btn_clk]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]
SET_PROPERTY IOSTANDARD LVCMOS33 [get_ports btn_clk]

#触摸屏引脚连接
set_property PACKAGE_PIN J25 [get_ports lcd_rst]
set_property PACKAGE_PIN H18 [get_ports lcd_cs]
set_property PACKAGE_PIN K16 [get_ports lcd_rs]
set_property PACKAGE_PIN L8 [get_ports lcd_wr]
set_property PACKAGE_PIN K8 [get_ports lcd_rd]
set_property PACKAGE_PIN J15 [get_ports lcd_bl_ctr]
set_property PACKAGE_PIN H9 [get_ports {lcd_data_io[0]}]
set_property PACKAGE_PIN K17 [get_ports {lcd_data_io[1]}]
set_property PACKAGE_PIN J20 [get_ports {lcd_data_io[2]}]
set_property PACKAGE_PIN M17 [get_ports {lcd_data_io[3]}]
set_property PACKAGE_PIN L17 [get_ports {lcd_data_io[4]}]
set_property PACKAGE_PIN L18 [get_ports {lcd_data_io[5]}]
set_property PACKAGE_PIN L15 [get_ports {lcd_data_io[6]}]
set_property PACKAGE_PIN M15 [get_ports {lcd_data_io[7]}]
set_property PACKAGE_PIN M16 [get_ports {lcd_data_io[8]}]
set_property PACKAGE_PIN L14 [get_ports {lcd_data_io[9]}]
set_property PACKAGE_PIN M14 [get_ports {lcd_data_io[10]}]
set_property PACKAGE_PIN F22 [get_ports {lcd_data_io[11]}]
set_property PACKAGE_PIN G22 [get_ports {lcd_data_io[12]}]
set_property PACKAGE_PIN G21 [get_ports {lcd_data_io[13]}]
set_property PACKAGE_PIN H24 [get_ports {lcd_data_io[14]}]
set_property PACKAGE_PIN J16 [get_ports {lcd_data_io[15]}]
set_property PACKAGE_PIN L19 [get_ports ct_int]
set_property PACKAGE_PIN J24 [get_ports ct_sda]
set_property PACKAGE_PIN H21 [get_ports ct_scl]
set_property PACKAGE_PIN G24 [get_ports ct_rstn]

set_property IOSTANDARD LVCMOS33 [get_ports lcd_rst]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_cs]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rs]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_wr]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rd]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_bl_ctr]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data_io[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports ct_int]
set_property IOSTANDARD LVCMOS33 [get_ports ct_sda]
set_property IOSTANDARD LVCMOS33 [get_ports ct_scl]
set_property IOSTANDARD LVCMOS33 [get_ports ct_rstn]

set_property IOSTANDARD LVCMOS33 [get_ports btn_clk]

# 时钟约束
# 主时钟约束 - 假设主时钟频率为100MHz
create_clock -period 20.000 -name clk [get_ports clk]

# 按钮时钟约束 - 假设按钮时钟频率为1MHz（用于单步执行）
create_clock -period 1000.000 -name btn_clk [get_ports btn_clk]

# 时钟域约束
set_clock_groups -asynchronous -group [get_clocks clk] -group [get_clocks btn_clk]

# 输入延迟约束（相对于主时钟）
set_input_delay -clock [get_clocks clk] -max 2.0 [get_ports resetn]
set_input_delay -clock [get_clocks clk] -min 0.5 [get_ports resetn]

# 输出延迟约束（相对于主时钟）
set_output_delay -clock [get_clocks clk] -max 2.0 [get_ports {lcd_data_io[*]}]
set_output_delay -clock [get_clocks clk] -min 0.5 [get_ports {lcd_data_io[*]}]
set_output_delay -clock [get_clocks clk] -max 2.0 [get_ports lcd_rst]
set_output_delay -clock [get_clocks clk] -min 0.5 [get_ports lcd_rst]
set_output_delay -clock [get_clocks clk] -max 2.0 [get_ports lcd_cs]
set_output_delay -clock [get_clocks clk] -min 0.5 [get_ports lcd_cs]
set_output_delay -clock [get_clocks clk] -max 2.0 [get_ports lcd_rs]
set_output_delay -clock [get_clocks clk] -min 0.5 [get_ports lcd_rs]
set_output_delay -clock [get_clocks clk] -max 2.0 [get_ports lcd_wr]
set_output_delay -clock [get_clocks clk] -min 0.5 [get_ports lcd_wr]
set_output_delay -clock [get_clocks clk] -max 2.0 [get_ports lcd_rd]
set_output_delay -clock [get_clocks clk] -min 0.5 [get_ports lcd_rd]
set_output_delay -clock [get_clocks clk] -max 2.0 [get_ports lcd_bl_ctr]
set_output_delay -clock [get_clocks clk] -min 0.5 [get_ports lcd_bl_ctr]
