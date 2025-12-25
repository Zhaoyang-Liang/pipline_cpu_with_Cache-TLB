# Pipeline CPU on FPGA（中文）

## 声明
- 一定不要抄袭啊孩子们
- 目前版本无需 Vivado IP 核
- 除了最终实验报告，其余报告在 `bagao` 分支（不是 `baogao` 分支）
- 帮忙点个 star（如果可以）

## 项目简介
一个基于 Verilog 的五级流水 MIPS-like CPU，主要模块包括：
- `fetch / decode / exe / mem / wb` 五级流水
- `regfile`、`alu`、`multiply`、`cp0` 等基础功能部件
- 顶层 `top` 负责把 CPU、AXI 接口、外设等连接在一起，方便在 FPGA 上综合和调试

## 项目文件组成（tree）
```text
.
├── .vscode
│   └── settings.json
├── AXI
│   ├── AXI_FULL_M_module.v
│   └── axi_slave_module.v
├── CPU设计图.jpg
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
└── 最终实验报告
    ├── img
    ├── simkai.ttf
    ├── style
    ├── 梁朝阳 2311561.pdf
    └── 梁朝阳 2311561.tex
```

## CPU 架构图
![CPU设计图.jpg](CPU设计图.jpg)

## 功能模块概览
- [x] 五级流水 CPU
- [x] bypass 前递/旁路单元
- [x] interrupt 异常/中断处理框架（配合 `cp0`）
- [x] AXI 总线接口（`AXI/` 目录）
- [x] TLB
- [x] I-cache & D-cache

## 历程

### bypass
为减少数据相关引入的流水线停顿，实现了前递/旁路单元

### interrupt
支持基本的异常/中断处理框架（配合 `cp0` 模块）

### AXI
针对 FPGA 外设/存储器，提供 AXI 总线接口模块（在 `AXI/` 目录）

### TLB & cache
实现了 TLB 和 cache

---

Copyright (c) 2025 Zhaoyang-Liang. All rights reserved.

Mail：budongjishubu@gmail.com
Class of 2023, Cryptography Science, Nankai University