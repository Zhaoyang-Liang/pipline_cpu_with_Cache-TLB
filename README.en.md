# Pipeline CPU on FPGA 

切换语言 / Switch the language:
- 中文：[README.zh-CN.md](README.zh-CN.md)


## Notes
- No plagiarism — for learning and reference only.
- Use the method at the bottom "Import Method" to import the project.
- This version does not require Vivado IP cores.
- Reports (except the final one) are on branch `bagao` (not `baogao`).
- If this helps, a star is appreciated.

## Overview
A 5-stage pipelined, MIPS-like CPU written in Verilog. Key modules include:
- The 5 pipeline stages: `fetch / decode / exe / mem / wb`
- Core functional units: `regfile`, `alu`, `multiply`, `cp0`, etc.
- Top-level `top` integrates CPU + AXI + peripherals for FPGA synthesis/debug

## Project Layout (tree)
```text
.
├── .vscode
│   └── settings.json
├── AXI
│   ├── AXI_FULL_M_module.v
│   └── axi_slave_module.v
├── CPU设计图.jpg （Architecture Diagram）
├── README.md
├── adder.v
├── alu.v
├── bypass_unit.v
├── cp0.v
├── data_ram.v
├── dcache_simple.v
├── decode.v
├── display
│   ├── lcd_module.dcp
│   ├── pipeline_cpu.xdc
│   └── pipeline_cpu_display.v
├── exe.v
├── fetch.v
├── icache_simple.v
├── inst_rom.v
├── mem.v
├── multiply.v
├── pipeline_cpu.v
├── regfile.v
├── testbench.v
├── tlb_simple.v
├── top.v
├── wb.v
└── 最终实验报告 （Final Report）
    ├── img （Images）
    ├── simkai.ttf （Font）
    ├── style （Style）
    ├── 梁朝阳 2311561.pdf （PDF）
    └── 梁朝阳 2311561.tex （LaTeX）
```

## Architecture
![CPU设计图.jpg](CPU设计图.jpg)

## Features
- [x] 5-stage pipelined CPU
- [x] Forwarding (bypass) unit
- [x] Exception & interrupt framework (with `cp0`)
- [x] AXI bus interface (see `AXI/`)
- [x] TLB
- [x] I-cache & D-cache

## Milestones

### bypass
Implemented forwarding/bypass to reduce stalls caused by data hazards.

### interrupt
Added a basic exception/interrupt handling framework (with `cp0`).

### AXI
Provided AXI bus interface modules for FPGA peripherals/memory (in `AXI/`).

### TLB & cache
Implemented TLB and caches.


## Import Method

I found a big problem is that I previously kept all the historical code, which led many people to not know what to import, so many people couldn't run it, but the code itself is not a problem (or the problem is not big, if you find any bugs, please contact me directly). I have now deleted all the historical code, so you only need to import the following:

1. Import the following images in Vivado for reference:

 ![所需文件.png](最终实验报告/img/所需文件.png)

Then run the simulation:

 ![只能跑仿真.png](最终实验报告/img/只能跑仿真.png)


Example of simulation results, the X in front is normal:

 ![结果.png](最终实验报告/img/结果.png)

---

Copyright (c) 2025 Zhaoyang-Liang. All rights reserved.

Mail：budongjishubu@gmail.com
Class of 2023, Cryptography Science, Nankai University