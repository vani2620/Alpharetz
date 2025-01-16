/*
 *Author: vani2620
 *Date created: 08012025
 */

`include "../../src/spi/spi_params.svh"
`default_nettype none
`timescale 1ns/1ps


// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style


module clock_divider_tb;

reg clk_in_tb;
reg clk_en_tb;
reg sync_rst_n_tb;
reg cpol;
wire [15:0] counter_out_tb;
wire clk_out_tb;

clock_divider #(
    .CLOCK_RATIO(4)
) clk_div_tb (
    .clk_in(clk_in_tb),
    .clk_en(clk_en_tb),
    .sync_rst_n(sync_rst_n_tb),
    .cpol(cpol),

    .counter_out(counter_out_tb),
    .clk_out(clk_out_tb)
);


initial begin
    cpol = 1;
    clk_in_tb = 0;
    forever #10 clk_in_tb = ~clk_in_tb;
end

initial begin
    clk_en_tb = 1;
    sync_rst_n_tb = 1;
    #10 sync_rst_n_tb = 0;
    #10 sync_rst_n_tb = 1;
end

initial begin
    $monitor("time = %3d, clk_in = %b, reset = %b, counter = %5d, clk_out = %b",
            $time, clk_in_tb, sync_rst_n_tb, counter_out_tb, clk_out_tb);
end

endmodule
