`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: icache_simple.v
//   > 描述  :最简I-Cache（4行，16B/行，直映，只读）
//*************************************************************************

module icache_simple(
    input             clk,
    input             resetn,
    // 请求接口
    input             req_valid,
    input      [31:0] req_addr,
    output            req_ready,
    // 响应接口
    output reg        resp_valid,
    output reg [31:0] resp_inst,
    // AXI USER 接口
    output reg        axi_start,
    output reg [31:0] axi_addr,
    output reg [7:0]  axi_len,
    input      [31:0] axi_rdata,
    input             axi_rvalid,
    input             axi_done,
    input             axi_busy
);

    // cache结构：4行，每行4个word
    reg [31:0] data [0:3][0:3];
    reg [25:0] tag  [0:3];
    reg        valid[0:3];
    reg        init_done;

    localparam ST_IDLE   = 2'd0;
    localparam ST_REFILL = 2'd1;
    reg [1:0] state;

    reg [31:0] req_addr_r;
    reg [1:0]  beat_cnt;
    reg        refill_started;
    reg [31:0] refill_word_r;

    wire [1:0] idx      = req_addr[5:4];
    wire [25:0] cur_tag = req_addr[31:6];
    wire [1:0] word_off = req_addr[3:2];
    wire hit = valid[idx] && (tag[idx] == cur_tag);
    wire [31:0] hit_word = data[idx][word_off];

    assign req_ready = (state == ST_IDLE);

    integer i, j;

    initial begin
        init_done = 1'b0;
    end

    always @(posedge clk) begin
        if (!resetn || !init_done) begin
            state      <= ST_IDLE;
            resp_valid <= 1'b0;
            axi_start  <= 1'b0;
            axi_addr   <= 32'd0;
            axi_len    <= 8'd1;
            beat_cnt   <= 2'd0;
            refill_started <= 1'b0;
            refill_word_r  <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin
                valid[i] <= 1'b0;
                tag[i]   <= 26'd0;
                for (j = 0; j < 4; j = j + 1) begin
                    data[i][j] <= 32'd0;
                end
            end
            init_done <= 1'b1;
            $display("I$ RESET: all lines invalid");
        end else begin
            resp_valid <= 1'b0;
            axi_start  <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (req_valid) begin
                        req_addr_r <= req_addr;
                        $display("I$ REQ: addr=%h idx=%0d tag=%h hit=%b",
                                 req_addr, idx, cur_tag, hit);
                        if (hit) begin
                            resp_inst  <= hit_word;
                            resp_valid <= 1'b1;
                            $display("I$ HIT: inst=%h", hit_word);
                        end else begin
                            state <= ST_REFILL;
                            beat_cnt <= 2'd0;
                            refill_started <= 1'b0;
                            $display("I$ MISS: refill base=%h", {req_addr[31:4], 4'b0});
                        end
                    end
                end
                ST_REFILL: begin
                    if (!refill_started && !axi_busy) begin
                        axi_start <= 1'b1;
                        axi_addr  <= {req_addr_r[31:4], 4'b0};
                        axi_len   <= 8'd4;
                        refill_started <= 1'b1;
                        $display("I$ REFILL-START: addr=%h len=4", {req_addr_r[31:4], 4'b0});
                    end

                    if (axi_rvalid) begin
                        data[req_addr_r[5:4]][beat_cnt] <= axi_rdata;
                        if (beat_cnt == req_addr_r[3:2]) begin
                            refill_word_r <= axi_rdata;
                        end
                        $display("I$ REFILL-BEAT: beat=%0d data=%h", beat_cnt, axi_rdata);
                        beat_cnt <= beat_cnt + 2'd1;
                    end

                    if (axi_done) begin
                        valid[req_addr_r[5:4]] <= 1'b1;
                        tag[req_addr_r[5:4]]   <= req_addr_r[31:6];
                        resp_inst  <= refill_word_r;
                        resp_valid <= 1'b1;
                        state      <= ST_IDLE;
                        $display("I$ REFILL-DONE: idx=%0d tag=%h inst=%h",
                                 req_addr_r[5:4], req_addr_r[31:6], refill_word_r);
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
