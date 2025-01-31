/*
 *Author: vani2620
 *Date created: 30012025
 */


`default_nettype none
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

module adder_subtractor #(
    parameter int DATA_WIDTH = 16
)(
    input wire mode,

    input wire [DATA_WIDTH-1:0] arg_a,
    input wire [DATA_WIDTH-1:0] arg_b,
    input wire carry_in,

    output reg [DATA_WIDTH-1:0] sum,
    output reg carry_out,
    output reg [DATA_WIDTH-1:0] internal_carries,
    output reg overflow
);

wire [DATA_WIDTH:0] zext_arg_a = {1'b0, arg_a};
wire [DATA_WIDTH:0] zext_arg_b = {1'b0, arg_b};
wire [DATA_WIDTH:0] zext_carry_in = {{DATA_WIDTH-1{1'b0}}, carry_in};
wire [DATA_WIDTH:0] result = mode ? (zext_arg_a - zext_arg_b - zext_carry_in) :
                                     (zext_arg_a + zext_arg_b + zext_carry_in);

wire [DATA_WIDTH-1:0] bit_carries = mode ? (arg_a ^ ~arg_b ^ result[DATA_WIDTH-1:0]) :
                                            (arg_a ^ arg_b ^ result[DATA_WIDTH-1:0]);

assign internal_carries = bit_carries;
assign overflow = bit_carries[DATA_WIDTH-1] != result[DATA_WIDTH];

assign {carry_out, sum} = result;

endmodule

`default_nettype wire
