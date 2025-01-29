/*
 *Author: vani2620
 *Date created: 08012025
 */

`include "alpharetz_cpu_params.svh"
`default_nettype none
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

module alpharetz_alu (
    input wire clk,
    input wire clk_en,
    input wire sync_rst,
    input wire sys_en,

    input wire [OPCODE_WIDTH-1:0] opcode,
    input wire [OPCODE_WIDTH-1:0] funct_code,

    input wire [SHORT_IMM_WIDTH-1:0] s_imm,

    input wire carry_in,
    input wire [CPU_DATA_WIDTH-1:0] src_1,
    input wire [CPU_DATA_WIDTH-1:0] src_2,

    output wire [CPU_DATA_WIDTH-1:0] result,
    output reg [FLAG_REG_WIDTH-1:0] flag_reg
);

wire [CPU_DATA_WIDTH:0] z_ext_src_1 = {1'b0, src_1};
wire [CPU_DATA_WIDTH:0] z_ext_src_2 = {1'b0, src_2};

logic [CPU_DATA_WIDTH + 1:0] alu_output; /* {carry_out, result, underflow} */
always_comb begin
    case(opcode)
    4'h1: alu_output = {z_ext_src_1 + z_ext_src_2, 1'b0};
    4'h2: alu_output = {z_ext_src_1 - z_ext_src_2, 1'b0};
    4'h3: alu_output = z_ext_src_1 >> s_imm;
    4'h4: alu_output = {z_ext_src_1 & z_ext_src_2, 1'b0};
    4'h5: alu_output = {z_ext_src_1 | z_ext_src_2, 1'b0};
    4'h6: alu_output = {z_ext_src_1 ^ z_ext_src_2, 1'b0};
    default: alu_output = 0;
    endcase
end

wire sgn_src_1 = z_ext_src_1[CPU_DATA_WIDTH];
wire sgn_src_2 = z_ext_src_2[CPU_DATA_WIDTH];
wire sgn_result = alu_output[CPU_DATA_WIDTH];

wire zero = alu_output == 0;
wire carry = alu_output[CPU_DATA_WIDTH+1];
wire overflow = (opcode == 4'h1) & (sgn_src_1 != sgn_result) & (sgn_src_2 != sgn_result) ||
                    (opcode == 4'h2) & (sgn_src_1 == sgn_result) & (sgn_src_2 == sgn_result);
wire underflow = alu_output[0]; //? Currently only represents shift underflow...what about arithmetic?
wire negative = alu_output[CPU_DATA_WIDTH]; //! Is this correct?
wire parity = ^alu_output[CPU_DATA_WIDTH:1];
wire half_carry = 0;
wire flag_trigger = sync_rst || (clk_en & sys_en);
wire [FLAG_REG_WIDTH-1:0] flags = sync_rst ? 0 : {1'b0, parity, negative, half_carry, underflow, overflow, carry, zero};
always_ff @(posedge clk) begin
    flag_reg <= flags;
end

assign result = alu_output[CPU_DATA_WIDTH:1];

endmodule

`default_nettype wire
