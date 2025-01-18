/*
 *Author: vani2620
 *Date created: 08012025
 */
`include "alpharetz_cpu_params.svh"
`default_nettype none
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

module alpharetz_regfile(
    input wire clk,
    input wire clk_en,
    input wire sync_rst,

    input wire wr_en,
    input wire [CPU_DATA_WIDTH-1:0] wr_data,
    input wire [REG_ADDR_WIDTH-1:0] wr_addr,

    input wire rd_en_a,
    input wire [REG_ADDR_WIDTH-1:0] rd_addr_a,
    output wire [CPU_DATA_WIDTH-1:0] rd_data_a,

    input wire rd_en_b,
    input wire [REG_ADDR_WIDTH-1:0] rd_addr_b,
    output wire [CPU_DATA_WIDTH-1:0] rd_data_b
);

wire [CPU_REG_COUNT-1:0] wr_dec;
always_comb begin
    wr_dec = 0;
    wr_dec[wr_addr] = 1'b1;
end

reg [CPU_DATA_WIDTH-1:0] regfile [CPU_REG_COUNT];
wire [CPU_DATA_WIDTH-1:0] data = sync_rst || wr_addr == 0 ? 0 : wr_data;
wire wr_trigger = sync_rst || (clk_en & wr_dec[wr_addr] & wr_en);
always @(posedge clk ) begin
    if (wr_trigger) begin
        regfile[wr_addr] <= data;
    end
end

assign rd_data_a = rd_en_a ? regfile[rd_addr_a] : 0;
assign rd_data_b = rd_en_b ? regfile[rd_addr_b] : 0;

endmodule

`default_nettype wire
