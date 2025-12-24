`timescale 1ns / 1ps
`define IF_ID_BUS_WIDTH     64
`define ID_EXE_BUS_WIDTH    167
`define EXE_MEM_BUS_WIDTH   155
`define MEM_WB_BUS_WIDTH    156
`define JBR_BUS_WIDTH       33
`define EXC_BUS_WIDTH       33

module mem(
    input              clk,
    input              resetn,
    input              MEM_valid,
    input      [154:0] EXE_MEM_bus_r,

    // ===============================
    // AXI USER INTERFACE
    // ===============================
    output             axi_start,      // 发起 AXI 事务 (1 个周期脉冲)
    output             axi_rw,         // 1 = load, 0 = store
    output     [31:0]  axi_addr,       // 读/写地址
    output     [7:0]   axi_len,        // burst长度
    output     [31:0]  axi_wdata,      // store 数据
    output             axi_wvalid,     // 写数据有效
    input              axi_wready,     // 写数据握手
    input      [31:0]  axi_rdata,      // 读数据
    input              axi_rvalid,     // 读数据有效
    input              axi_done,       // AXI 事务完成
    input              axi_busy,       // AXI 忙

    // ===============================
    // pipeline interface
    // ===============================
    output             MEM_over,
    output     [155:0] MEM_WB_bus,
    input              MEM_allow_in,
    output     [4 :0]  MEM_wdest,
    output     [31:0]  MEM_result,

    output     [31:0]  MEM_pc
);

    //---------------------------------------------
    // 解出 EXE_MEM_bus_r
    //---------------------------------------------
    wire [3 :0] mem_control;
    wire [31:0] store_data;
    wire [31:0] exe_result;
    wire [31:0] lo_result;
    wire        hi_write, lo_write;
    wire        mfhi, mflo, mtc0, mfc0;
    wire [7:0]  cp0r_addr;
    wire        syscall, brk, eret;
    wire        rf_wen;
    wire [4:0]  rf_wdest;
    wire [31:0] pc;

    assign {
        mem_control,
        store_data,
        exe_result,
        lo_result,
        hi_write,
        lo_write,
        mfhi,
        mflo,
        mtc0,
        mfc0,
        cp0r_addr,
        syscall,
        brk,
        eret,
        rf_wen,
        rf_wdest,
        pc
    } = EXE_MEM_bus_r;

    assign MEM_pc = pc;

    //---------------------------------------------
    // load/store decode
    //---------------------------------------------
    wire inst_load, inst_store, ls_word, lb_sign;
    assign {inst_load, inst_store, ls_word, lb_sign} = mem_control;

    //---------------------------------------------
    // 地址与异常检测
    //---------------------------------------------
    wire [31:0] vaddr = exe_result;
    wire addr_unaligned = ls_word && (vaddr[1:0] != 2'b00);
    wire mem_ex_adel = inst_load  && addr_unaligned;
    wire mem_ex_ades = inst_store && addr_unaligned;

    //---------------------------------------------
    // TLB
    //---------------------------------------------
    wire        tlb_hit;
    wire [31:0] tlb_paddr;
    wire        tlb_exc_valid;
    wire [ 4:0] tlb_exc_code;
    wire        tlb_badvaddr_valid;
    wire [31:0] tlb_badvaddr;

    tlb_simple tlb_u (
        .clk            (clk),
        .resetn         (resetn),
        .req_valid      (MEM_valid && (inst_load | inst_store)),
        .vaddr          (vaddr),
        .is_store       (inst_store),
        .hit            (tlb_hit),
        .paddr          (tlb_paddr),
        .exc_valid      (tlb_exc_valid),
        .exc_code       (tlb_exc_code),
        .badvaddr_valid (tlb_badvaddr_valid),
        .badvaddr       (tlb_badvaddr)
    );

    wire mem_ex_tlbl = tlb_exc_valid && (tlb_exc_code == 5'd2);
    wire mem_ex_tlbs = tlb_exc_valid && (tlb_exc_code == 5'd3);
    wire mem_ex_mod  = tlb_exc_valid && (tlb_exc_code == 5'd1);
    wire mem_ex_any  = mem_ex_adel | mem_ex_ades | mem_ex_tlbl | mem_ex_tlbs | mem_ex_mod;

    always @(posedge clk) begin
        if (MEM_valid && (inst_load | inst_store) && mem_ex_any) begin
            $display("MEM_EXC: vaddr=%h adel=%b ades=%b tlbl=%b tlbs=%b mod=%b",
                     vaddr, mem_ex_adel, mem_ex_ades, mem_ex_tlbl, mem_ex_tlbs, mem_ex_mod);
        end
    end

    //---------------------------------------------
    // D-Cache
    //---------------------------------------------
    wire        cache_req_valid = MEM_valid && (inst_load | inst_store) && !mem_ex_any;
    wire        cache_req_ready;
    wire        cache_resp_valid;
    wire [31:0] cache_resp_rdata;

    dcache_simple dcache_u (
        .clk         (clk),
        .resetn      (resetn),
        .req_valid   (cache_req_valid),
        .req_is_store(inst_store),
        .req_size    (ls_word ? 2'b10 : 2'b00),
        .req_paddr   (tlb_paddr),
        .req_wdata   (store_data),
        .req_ready   (cache_req_ready),
        .resp_valid  (cache_resp_valid),
        .resp_rdata  (cache_resp_rdata),
        .axi_start   (axi_start),
        .axi_rw      (axi_rw),
        .axi_addr    (axi_addr),
        .axi_len     (axi_len),
        .axi_wdata   (axi_wdata),
        .axi_wvalid  (axi_wvalid),
        .axi_wready  (axi_wready),
        .axi_rdata   (axi_rdata),
        .axi_rvalid  (axi_rvalid),
        .axi_done    (axi_done),
        .axi_busy    (axi_busy)
    );

    always @(posedge clk) begin
        if (cache_req_valid) begin
            $display("MEM_REQ: vaddr=%h paddr=%h load=%b store=%b",
                     vaddr, tlb_paddr, inst_load, inst_store);
        end
        if (cache_resp_valid) begin
            $display("MEM_CACHE_RESP: rdata=%h", cache_resp_rdata);
        end
    end

    //---------------------------------------------
    // MEM_over：
    //  非访存指令：立即完成
    //  load/store：等待cache响应或异常
    //---------------------------------------------
    assign MEM_over = (inst_load | inst_store) ?
                      (mem_ex_any ? MEM_valid : cache_resp_valid) :
                      MEM_valid;

    //---------------------------------------------
    // MEM_result：load 返回cache结果并做符号扩展
    //---------------------------------------------
    wire [7:0] load_byte = (vaddr[1:0] == 2'd0) ? cache_resp_rdata[7:0]  :
                           (vaddr[1:0] == 2'd1) ? cache_resp_rdata[15:8] :
                           (vaddr[1:0] == 2'd2) ? cache_resp_rdata[23:16]:
                                                  cache_resp_rdata[31:24];
    wire [31:0] load_data = ls_word ? cache_resp_rdata :
                            (lb_sign ? {{24{load_byte[7]}}, load_byte} :
                                       {24'd0, load_byte});

    assign MEM_result = inst_load ? load_data : exe_result;

    //---------------------------------------------
    // MEM->WB 总线
    //---------------------------------------------
    assign MEM_WB_bus = {
        rf_wen, rf_wdest,
        MEM_result,         // 写回寄存器的数据
        lo_result,
        hi_write, lo_write,
        mfhi, mflo,
        mtc0, mfc0, cp0r_addr,
        syscall, brk, eret,
        mem_ex_adel, mem_ex_ades,
        mem_ex_tlbl, mem_ex_tlbs, mem_ex_mod,
        vaddr,              // BADVADDR
        pc
    };

    assign MEM_wdest = rf_wdest & {5{MEM_valid}};

endmodule
