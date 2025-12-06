# Pipeline CPU on FPGA

上次更新时间 2025-12-06

## 声明
- 如果你参考了本项目，帮孩子点个 star 吧（报告在 `bagao` 分支）
- 如果你参考了报告，请避免图片以及话术复用，本人的实现有比较鲜明的特色与编程习惯
- 持续更新中...
- 一定不要抄袭啊孩子们
- 目前版本无需vivado IP核

## 项目简介
一个基于 Verilog 的五级流水 MIPS-like CPU，主要模块包括：
- `fetch / decode / exe / mem / wb` 五级流水
- `regfile`、`alu`、`multiply`、`cp0` 等基础功能部件
- 顶层 `top` 负责把 CPU、AXI 接口、外设等连接在一起，方便在 FPGA 上综合和调试

## 功能模块概览
- [x] 五级流水 CPU
- [x] bypass 前递/旁路单元
- [x] interrupt 异常/中断处理框架（配合 `cp0`）
- [x] AXI 总线接口（`AXI/` 目录）
- [ ] TLB（预留，暂未实现）
- [ ] cache（预留，暂未实现）

## 历程

### bypass
为减少数据相关引入的流水线停顿，实现了前递/旁路单元

### interrupt
支持基本的异常/中断处理框架（配合 `cp0` 模块）

### AXI
针对 FPGA 外设/存储器，提供 AXI 总线接口模块（在 `AXI/` 目录）

### TLB

### cache
