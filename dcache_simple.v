`timescale 1ns / 1ps

//*************************************************************************
//   > 文件名: dcache_simple.v
//   > 描述  :最简D-Cache（4行，16B/行，直映，写直达+写分配）
//*************************************************************************

module dcache_simple(
    input             clk,
    input             resetn,
    // 请求接口
    input             req_valid,
    input             req_is_store,
    input      [1:0]  req_size,     // 2'b10=word, 2'b00=byte
    input      [31:0] req_paddr,
    input      [31:0] req_wdata,
    output            req_ready,
    // 响应接口
    output reg        resp_valid,
    output reg [31:0] resp_rdata,
    // AXI USER 接口
    output reg        axi_start,
    output reg        axi_rw,        // 1=read, 0=write
    output reg [31:0] axi_addr,
    output reg [7:0]  axi_len,
    output reg [31:0] axi_wdata,
    output reg        axi_wvalid,
    input             axi_wready,
    input      [31:0] axi_rdata,
    input             axi_rvalid,
    input             axi_done,
    input             axi_busy
);

    function [31:0] merge_byte;
        input [31:0] old_word;
        input [31:0] wdata;
        input [1:0]  byte_off;
        reg   [31:0] mask;
    begin
        mask = 32'hFF << (byte_off * 8);
        merge_byte = (old_word & ~mask) | ((wdata[7:0] << (byte_off * 8)) & mask);
    end
    endfunction

    // cache结构：4行，每行4个word
    reg [31:0] data [0:3][0:3];
    reg [25:0] tag  [0:3];
    reg        valid[0:3];
    reg        init_done;

    // 状态机
    localparam ST_IDLE   = 2'd0;
    localparam ST_REFILL = 2'd1;
    localparam ST_WRITE  = 2'd2;
    reg [1:0] state;

    // 请求保持寄存
    reg [31:0] req_addr_r;
    reg [31:0] req_wdata_r;
    reg        req_is_store_r;
    reg [1:0]  req_size_r;
    reg [1:0]  beat_cnt;
    reg        refill_started;
    reg        write_started;
    reg [31:0] refill_word_r;

    wire [1:0] idx   = req_paddr[5:4];
    wire [25:0] cur_tag = req_paddr[31:6];
    wire [1:0] word_off = req_paddr[3:2];
    wire [1:0] byte_off = req_paddr[1:0];
    wire [31:0] write_addr = {req_addr_r[31:2], 2'b00};

    wire hit = valid[idx] && (tag[idx] == cur_tag);
    wire [31:0] hit_word = data[idx][word_off];

    assign req_ready = (state == ST_IDLE);

    integer i, j;

    initial begin
        init_done = 1'b0;
    end

    // 复位清空
    always @(posedge clk) begin
        if (!resetn || !init_done) begin
            state      <= ST_IDLE;
            resp_valid <= 1'b0;
            axi_start  <= 1'b0;
            axi_rw     <= 1'b0;
            axi_addr   <= 32'd0;
            axi_len    <= 8'd1;
            axi_wdata  <= 32'd0;
            axi_wvalid <= 1'b0;
            beat_cnt   <= 2'd0;
            refill_started <= 1'b0;
            write_started  <= 1'b0;
            refill_word_r  <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin
                valid[i] <= 1'b0;
                tag[i]   <= 26'd0;
                for (j = 0; j < 4; j = j + 1) begin
                    data[i][j] <= 32'd0;
                end
            end
            $display("D$ RESET: all lines invalid");
            init_done <= 1'b1;
        end else begin
            resp_valid <= 1'b0;
            axi_start  <= 1'b0;
            axi_wvalid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (req_valid) begin
                        req_addr_r     <= req_paddr;
                        req_wdata_r    <= req_wdata;
                        req_is_store_r <= req_is_store;
                        req_size_r     <= req_size;
                        $display("D$ REQ: addr=%h idx=%0d tag=%h hit=%b is_store=%b size=%b",
                                 req_paddr, idx, cur_tag, hit, req_is_store, req_size);

                        if (hit) begin
                            if (!req_is_store) begin
                                resp_rdata <= hit_word;
                                resp_valid <= 1'b1;
                                $display("D$ HIT-LOAD: word=%h", hit_word);
                            end else begin
                                // store命中：更新cache行
                                if (req_size == 2'b10) begin
                                    data[idx][word_off] <= req_wdata;
                                    $display("D$ HIT-STORE-W: new=%h", req_wdata);
                                end else begin
                                    // byte store merge
                                    data[idx][word_off] <= merge_byte(hit_word, req_wdata, byte_off);
                                    $display("D$ HIT-STORE-B: old=%h new=%h",
                                             hit_word, merge_byte(hit_word, req_wdata, byte_off));
                                end

                                // write-through
                                state     <= ST_WRITE;
                                beat_cnt  <= 2'd0;
                                write_started <= 1'b0;
                            end
                        end else begin
                            // miss：发起refill
                            state     <= ST_REFILL;
                            beat_cnt  <= 2'd0;
                            refill_started <= 1'b0;
                            $display("D$ MISS: refill base=%h", {req_paddr[31:4], 4'b0});
                        end
                    end
                end

                ST_REFILL: begin
                    if (!refill_started && !axi_busy) begin
                        axi_start <= 1'b1;
                        axi_rw    <= 1'b1;
                        axi_addr  <= {req_addr_r[31:4], 4'b0};
                        axi_len   <= 8'd4;
                        refill_started <= 1'b1;
                        $display("D$ REFILL-START: addr=%h len=4", {req_addr_r[31:4], 4'b0});
                    end

                    if (axi_rvalid) begin
                        data[req_addr_r[5:4]][beat_cnt] <= axi_rdata;
                        if (beat_cnt == req_addr_r[3:2]) begin
                            refill_word_r <= axi_rdata;
                        end
                        $display("D$ REFILL-BEAT: beat=%0d data=%h", beat_cnt, axi_rdata);
                        beat_cnt <= beat_cnt + 2'd1;
                    end

                    if (axi_done) begin
                        valid[req_addr_r[5:4]] <= 1'b1;
                        tag[req_addr_r[5:4]]   <= req_addr_r[31:6];
                        $display("D$ REFILL-DONE: idx=%0d tag=%h", req_addr_r[5:4], req_addr_r[31:6]);

                        if (req_is_store_r) begin
                            // refill后再写cache
                            if (req_size_r == 2'b10) begin
                                data[req_addr_r[5:4]][req_addr_r[3:2]] <= req_wdata_r;
                                $display("D$ POST-REFILL-STORE-W: new=%h", req_wdata_r);
                            end else begin
                                data[req_addr_r[5:4]][req_addr_r[3:2]] <=
                                    merge_byte(refill_word_r,
                                               req_wdata_r, req_addr_r[1:0]);
                                $display("D$ POST-REFILL-STORE-B: old=%h new=%h",
                                         refill_word_r,
                                         merge_byte(refill_word_r,
                                                    req_wdata_r, req_addr_r[1:0]));
                            end
                            state <= ST_WRITE;
                            write_started <= 1'b0;
                        end else begin
                            resp_rdata <= refill_word_r;
                            resp_valid <= 1'b1;
                            state      <= ST_IDLE;
                        end
                    end
                end

                ST_WRITE: begin
                    if (!write_started && !axi_busy) begin
                        axi_start <= 1'b1;
                        axi_rw    <= 1'b0;
                        axi_len   <= 8'd1;
                        axi_addr  <= write_addr;
                        if (req_size_r == 2'b10) begin
                            axi_wdata <= req_wdata_r;
                        end else begin
                            axi_wdata <= data[req_addr_r[5:4]][req_addr_r[3:2]];
                        end
                        write_started <= 1'b1;
                        $display("D$ WRITE-START: addr=%h wdata=%h", write_addr, axi_wdata);
                    end

                    if (write_started) begin
                        axi_wvalid <= 1'b1;
                    end

                    if (axi_done) begin
                        resp_valid <= 1'b1;
                        state      <= ST_IDLE;
                        write_started <= 1'b0;
                        $display("D$ WRITE-DONE");
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
