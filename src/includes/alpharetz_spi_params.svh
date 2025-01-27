/*
 *Author: vani2620
 *Date created: 08012025
*/

// verilog_lint: waive-start macro-name-style
// verilog_lint: waive-start parameter-name-style

`ifndef spi_params
`define spi_params
parameter int SPI_DATA_WIDTH = 8;
parameter int PERI_CNT = 8;
localparam int P_ADDR_WIDTH = $clog2(PERI_CNT);
parameter shortint SPI_CLK_RATIO = 4;
parameter bit CPOL = 0;
`endif
