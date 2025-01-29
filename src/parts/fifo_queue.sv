/*
 *Author: vani2620
 *Date created: 27012025
*/

`include "alpharetz_uart_params.svh"

`default_nettype none
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

module fifo_queue #(
    parameter int FIFO_DATA_WIDTH = 16,
    parameter int FIFO_DEPTH = 128
)(
    input wire clk,
    input wire clk_en,
    input wire sync_rst,

    input wire wr_en,
    input wire [FIFO_DATA_WIDTH-1:0] data_in,

    input wire rd_en,

    output reg [FIFO_DATA_WIDTH-1:0] data_out,
    output reg full,
    output reg empty
);

localparam int PTR_WIDTH = $clog2(FIFO_DEPTH);

reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
wire empty_msb_cmp = wr_ptr[PTR_WIDTH] ^ rd_ptr[PTR_WIDTH];
wire low_empty_chk = wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0];
wire full_chk = low_empty_chk && empty_msb_cmp;
wire empty_chk = low_empty_chk && !empty_msb_cmp;

wire wr_ptr_update = sync_rst || (clk_en & wr_en);
wire wr_ptr_next = sync_rst ? 0 : wr_ptr + 1;
always_ff @(posedge clk) begin : update_wr_ptr
    if (wr_ptr_update) wr_ptr <= wr_ptr_next;
end

logic [FIFO_DEPTH-1:0] wr_dec;
always_comb begin : decode
    wr_dec = 0;
    wr_dec[wr_ptr] = 1'b1;
end

wire [FIFO_DATA_WIDTH-1:0] fifo_read [FIFO_DEPTH];
genvar fifo_idx;
generate
    for (fifo_idx = 0; fifo_idx < FIFO_DEPTH; fifo_idx = fifo_idx + 1) begin : gen_queue
        if (!fifo_idx) begin: g_addr_0
            assign fifo_read[fifo_idx] = 0;
        end
        else begin: gen_other_addr
            reg [FIFO_DATA_WIDTH-1:0] fifo_entry;
            wire [FIFO_DATA_WIDTH-1:0] fifo_entry_data = sync_rst ? 0 : data_in;
            wire write_trigger = sync_rst || (clk_en & wr_dec[fifo_idx] & wr_en & !full_chk);
            always_ff @(posedge clk) begin : update_entries
                if (write_trigger) fifo_entry <= fifo_entry_data;
            end
            assign fifo_read[fifo_idx] = fifo_entry;
        end
    end
endgenerate

wire rd_ptr_update = sync_rst || (clk_en & rd_en & !empty_chk);
wire rd_ptr_next = sync_rst ? 0 : rd_ptr + 1;
always_ff @(posedge clk) begin : read_fifo
    if (rd_ptr_update) begin
        data_out <= fifo_read[rd_ptr];
        rd_ptr <= rd_ptr_next;
    end
end

assign full = full_chk;
assign empty = empty_chk;

endmodule
