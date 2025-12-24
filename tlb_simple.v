`timescale 1ns / 1ps

//*************************************************************************
//   > 文件名: tlb_simple.v
//   > 描述  :最简TLB（4项，全相联，固定映射）
//   > 说明  :仅支持4KB页，ASID=0
//*************************************************************************

module tlb_simple(
    input             clk,
    input             resetn,
    input             req_valid,
    input      [31:0] vaddr,
    input             is_store,
    output reg        hit,
    output reg [31:0] paddr,
    output reg        exc_valid,
    output reg [ 4:0] exc_code,
    output reg        badvaddr_valid,
    output reg [31:0] badvaddr
);

    // 4KB页：VPN/PPN = [31:12]
    reg [19:0] tlb_vpn [0:3];
    reg [19:0] tlb_ppn [0:3];
    reg        tlb_valid [0:3];
    reg        tlb_dirty [0:3];

    integer i;
    reg init_done;

    initial begin
        init_done = 1'b0;
    end

    // 固定表项初始化（0~3页，1:1映射）
    always @(posedge clk) begin
        if (!resetn || !init_done) begin
            for (i = 0; i < 4; i = i + 1) begin
                tlb_vpn[i]   <= i[19:0];
                tlb_ppn[i]   <= i[19:0];
                tlb_valid[i] <= 1'b1;
                tlb_dirty[i] <= 1'b1;
                $display("TLB_INIT: idx=%0d vpn=%h ppn=%h v=%b d=%b",
                         i, i[19:0], i[19:0], 1'b1, 1'b1);
            end
            init_done <= 1'b1;
        end
    end

    // 查找逻辑
    reg        match_found;
    reg [1:0]  match_idx;
    reg        match_valid;
    reg        match_dirty;

    always @(*) begin
        match_found = 1'b0;
        match_idx   = 2'd0;
        match_valid = 1'b0;
        match_dirty = 1'b0;

        for (i = 0; i < 4; i = i + 1) begin
            if (tlb_vpn[i] == vaddr[31:12]) begin
                match_found = 1'b1;
                match_idx   = i[1:0];
                match_valid = tlb_valid[i];
                match_dirty = tlb_dirty[i];
            end
        end
    end

    always @(*) begin
        hit            = match_found & match_valid;
        paddr          = {tlb_ppn[match_idx], vaddr[11:0]};
        exc_valid      = 1'b0;
        exc_code       = 5'd0;
        badvaddr_valid = 1'b0;
        badvaddr       = vaddr;

        if (req_valid) begin
            if (!match_found) begin
                exc_valid = 1'b1;
                exc_code  = is_store ? 5'd3 : 5'd2; // TLBS/TLBL
            end else if (!match_valid) begin
                exc_valid = 1'b1;
                exc_code  = is_store ? 5'd3 : 5'd2; // invalid当作TLBL/TLBS
            end else if (is_store && !match_dirty) begin
                exc_valid = 1'b1;
                exc_code  = 5'd1; // Modify
            end
        end

        if (exc_valid) begin
            badvaddr_valid = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (req_valid) begin
            $display("TLB_LOOKUP: vaddr=%h vpn=%h hit=%b idx=%0d v=%b d=%b exc=%b code=%0d",
                     vaddr, vaddr[31:12], hit, match_idx, match_valid, match_dirty,
                     exc_valid, exc_code);
        end
    end

endmodule
