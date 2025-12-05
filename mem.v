`timescale 1ns / 1ps
`define IF_ID_BUS_WIDTH     64
`define ID_EXE_BUS_WIDTH    167
`define EXE_MEM_BUS_WIDTH   155
`define MEM_WB_BUS_WIDTH    153
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
    output reg         axi_start,      // 发起 AXI 事务 (1 个周期脉冲)
    output reg         axi_rw,         // 1 = load, 0 = store
    output reg [31:0]  axi_addr,       // 读/写地址
    output reg [31:0]  axi_wdata,      // store 数据
    output reg         axi_wvalid,     // 写数据有效
    input              axi_wready,     // 写数据握手
    input      [31:0]  axi_rdata,      // 读数据
    input              axi_done,       // AXI 事务完成
    input              axi_busy,       // AXI 忙

    // ===============================
    // pipeline interface
    // ===============================
    output             MEM_over,
    output     [152:0] MEM_WB_bus,
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
    // 发起 AXI load/store
    //---------------------------------------------
    reg mem_valid_hold;

    always @(posedge clk) begin
        if (!resetn)
            mem_valid_hold <= 1'b0;
        else if (MEM_allow_in)
            mem_valid_hold <= 1'b0;
        else if (MEM_valid)
            mem_valid_hold <= 1'b1;
    end

    wire do_load  = MEM_valid && inst_load;
    wire do_store = MEM_valid && inst_store;

    //---------------------------------------------
    // AXI handshake 控制
    //---------------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            axi_start  <= 1'b0;
            axi_rw     <= 1'b0;
            axi_addr   <= 32'b0;
            axi_wdata  <= 32'b0;
            axi_wvalid <= 1'b0;
        end
        else begin
            axi_start  <= 1'b0;
            axi_wvalid <= 1'b0;

            // ---------------- store ----------------
            if (do_store) begin
                axi_addr  <= exe_result;
                axi_rw    <= 1'b0;        // 写
                axi_wdata <= store_data;
                axi_start <= 1'b1;        // 发起 write

                if (!axi_busy)
                    axi_wvalid <= 1'b1;   // 发送写数据
            end

            // ---------------- load ----------------
            if (do_load) begin
                axi_addr  <= exe_result;
                axi_rw    <= 1'b1;     // 读
                axi_start <= 1'b1;     // 发起 read
            end
        end
    end

    //---------------------------------------------
    // MEM_over：
    //  load : wait axi_done
    //  store: wait axi_done (写响应 BVALID)
    //---------------------------------------------
    assign MEM_over = axi_done;

    //---------------------------------------------
    // MEM_result：load 返回 axi_rdata
    //             store 返回 exe_result (不影响写回寄存器的情况通常 store 不写寄存器)
    //---------------------------------------------
    assign MEM_result = inst_load ? axi_rdata : exe_result;

    //---------------------------------------------
    // MEM->WB 总线
    //---------------------------------------------
    wire mem_ex_adel = 1'b0;
    wire mem_ex_ades = 1'b0;

    assign MEM_WB_bus = {
        rf_wen, rf_wdest,
        MEM_result,         // 写回寄存器的数据
        lo_result,
        hi_write, lo_write,
        mfhi, mflo,
        mtc0, mfc0, cp0r_addr,
        syscall, brk, eret,
        mem_ex_adel, mem_ex_ades,
        exe_result,         // BADVADDR 占位
        pc
    };

    assign MEM_wdest = rf_wdest & {5{MEM_valid}};

endmodule
