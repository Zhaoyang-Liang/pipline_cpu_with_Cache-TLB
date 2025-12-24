# Pipeline CPU on FPGA

## 声明
- 一定不要抄袭啊孩子们
- 目前版本无需vivado IP核
- 所有报告在bagao分支（不是baogao分支）

## 项目简介
一个基于 Verilog 的五级流水 MIPS-like CPU，主要模块包括：
- `fetch / decode / exe / mem / wb` 五级流水
- `regfile`、`alu`、`multiply`、`cp0` 等基础功能部件
- 顶层 `top` 负责把 CPU、AXI 接口、外设等连接在一起，方便在 FPGA 上综合和调试

## CPU架构图

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

实现了TLB和cache

---

Copyright (c) 2025 Zhaoyang-Liang All rights reserved.