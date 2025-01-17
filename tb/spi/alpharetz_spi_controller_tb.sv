/*
 *Author: vani2620
 *Date created: 09012025
 */

`include "../../src/spi/alpharetz_spi_params.svh"
`default_nettype none
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

module alpharetz_spi_controller_tb;

reg sys_clk_tb;
reg sys_clk_en_tb;
reg sync_rst_n_tb;
reg start_txn_tb;
reg [SPI_DATA_WIDTH-1:0] tx_data_tb;
reg [P_ADDR_WIDTH-1:0] p_addr_tb;
reg cipo_tb;
reg copi_tb;
reg p_clk_tb;
reg [PERI_CNT-1:0] p_sel_n_tb;
reg end_txn;
reg [15:0] clk_counter_tb;

alpharetz_spi_controller spi_ctrl_tb(
    .sys_clk(sys_clk_tb),
    .sys_clk_en(sys_clk_en_tb),
    .sync_rst_n(sync_rst_n_tb),
    .start_txn(start_txn_tb),
    .tx_data(tx_data_tb),
    .p_addr(p_addr_tb),
    .cipo(cipo_tb),
    .copi(copi_tb),
    .p_clk(p_clk_tb),
    .p_sel_n(p_sel_n_tb),
    .end_txn(end_txn),
    .clk_counter(clk_counter_tb)
);



initial begin
    sys_clk_tb = 0;

    forever #10 sys_clk_tb = !sys_clk_tb;
end

initial begin
    sys_clk_en_tb = 1;
    sync_rst_n_tb = 1;
    #10 sync_rst_n_tb = 0;
    #10 sync_rst_n_tb = 1;
end

endmodule
