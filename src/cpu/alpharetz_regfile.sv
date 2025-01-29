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
    input wire sys_en,

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

logic [CPU_REG_COUNT-1:0] wr_dec;
always_comb begin
    wr_dec = 0;
    wr_dec[wr_addr] = 1'b1;
end

wire [CPU_DATA_WIDTH-1:0] regfile_output [CPU_REG_COUNT];
genvar reg_idx;
generate
    for (reg_idx = 0; reg_idx < CPU_REG_COUNT; reg_idx = reg_idx + 1) begin : gen_regfile
        if (reg_idx == 0) begin : gen_zero_reg
            assign regfile_output[reg_idx] = 0;
        end else begin : gen_registers
            reg [CPU_DATA_WIDTH-1:0] register;
            wire [CPU_DATA_WIDTH-1:0] data = sync_rst ? 0 : wr_data;
            wire wr_trig = sync_rst || (clk_en && wr_dec[reg_idx] && wr_en && sys_en);
            always_ff @( posedge clk ) begin : update_reg
                if (wr_trig) register <= data;
            end
            assign regfile_output[reg_idx] = register;
        end
    end
endgenerate

assign rd_data_a = rd_en_a ? regfile_output[rd_addr_a] : 0;
assign rd_data_b = rd_en_b ? regfile_output[rd_addr_b] : 0;

endmodule

`default_nettype wire
