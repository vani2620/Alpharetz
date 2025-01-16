/*
 *Author: vani2620
 *Date created: 04012025
 */

`default_nettype none
`include "../spi/spi_params.svh"

// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

module clock_divider(
    input wire clk_in,
    input wire clk_en,
    input wire sync_rst_n,
    input wire cpol,

    output wire [15:0] counter_out,
    output reg clk_out
);

reg [15:0] counter;

wire counter_trigger = !sync_rst_n || clk_en;
wire [15:0] counter_next = !sync_rst_n ? 0 : (counter >= CLOCK_RATIO-1) ? 0 : counter + 1;
always_ff @(posedge clk_in) begin
  if (counter_trigger) begin
    counter <= counter_next;
  end
end



always_comb begin
    if (!sync_rst_n) begin
        clk_out = clk_in;
    end else if (clk_en) begin
        clk_out = (counter < CLOCK_RATIO/2) ? cpol : ~cpol;
    end else begin
        clk_out = 0;
    end
end

assign counter_out = counter;

endmodule

`default_nettype wire
