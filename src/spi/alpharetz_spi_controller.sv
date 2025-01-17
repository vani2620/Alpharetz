/*
 *Author: vani2620
 *Date created: 08012025
 */

`include "alpharetz_spi_params.svh"
`default_nettype none
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style
module alpharetz_spi_controller(
    input wire sys_clk,
    input wire sys_clk_en,
    input wire sync_rst_n,

    //From CPU
    input wire [SPI_DATA_WIDTH-1:0] tx_data,
    input wire start_txn, //DATA VALID
    input wire [P_ADDR_WIDTH-1:0] p_addr,

    //From peripheral
    input wire cipo,

    //To peripheral
    output reg copi,
    output reg p_clk,
    output reg [PERI_CNT-1:0] p_sel_n,

    //To CPU
    //output reg [SPI_DATA_WIDTH-1:0] rx_data,
    output reg end_txn,
    //output reg busy,

    output reg [15:0] clk_counter //Remove later
);


wire cpol = CPOL;
reg p_clk_reg;

clock_divider spi_clk_div (
    .clk_in(sys_clk),
    .clk_en(sys_clk_en),
    .sync_rst_n(sync_rst_n),
    .cpol(cpol),
    .counter_out(clk_counter),
    .clk_out(p_clk_reg)
);

/* NOTES
Controller starts off in IDLE state. p_clk = cpol,
p_sel_n = {PERI_CNT{1'b1}}
First, start_txn is asserted, and the controller
reads and stores the data coming in from tx_data
and the address from p_addr. <- STATE: INIT
Set busy signal to 1, de-assert start_txn, and pull
p_sel_n[p_addr] low. p_clk should also begin
sending signal from clock divider at the same time
and data should be getting shifted out in-time
with p_clk cycles. Since tx_data is stored on sys_clk,
shifting should ONLY occur when clk_counter == CLOCK_RATIO-1.
Increment spi_bit_counter with each bit shifted out, and when
counter hits SPI_DATA_WIDTH-1, de-assert p_sel_n[p_addr].  <- STATE: TXF
Store inshifted data from cipo into rx_data. De-assert busy
signal. Assert end_txn.  <- STATE: STOP
Then go back to IDLE state.
*/

typedef enum reg[1:0] {IDLE = 2'b00, INIT = 2'b01, TXF = 2'b10, STOP = 2'b11} state_t;
state_t current_state, next_state;

localparam int BITCOUNT = $clog2(SPI_DATA_WIDTH);
reg [BITCOUNT-1:0] spi_bit_counter;


wire [BITCOUNT-1:0] count = !sync_rst_n ? 0  : spi_bit_counter + 'd1;
always_ff @(posedge sys_clk) begin
    if (shift_trigger) begin
        spi_bit_counter <= count;
    end
end

wire addr_dec_en = (sys_clk_en & sync_rst_n) && (spi_bit_counter == 0);
reg [PERI_CNT-1:0] p_sel_n_reg;
always_ff @(negedge sys_clk) begin
    if (!sync_rst_n) begin
        p_sel_n_reg <= {PERI_CNT{1'b1}};
    end else if (addr_dec_en) begin
        p_sel_n_reg[p_addr] <= 1'b0;
    end
end

reg [SPI_DATA_WIDTH-1:0] data_reg;
wire reg_write = !sync_rst_n || sys_clk_en;
wire [SPI_DATA_WIDTH-1:0] data = !sync_rst_n ? 0 : tx_data;
always_ff @(posedge sys_clk) begin
    if (reg_write) begin
        data_reg <= data;
    end
end

wire txf_en = (~p_sel_n_reg != 0) && sys_clk_en;
wire [SPI_DATA_WIDTH-1:0] shift_in_data = (!sync_rst_n) ? 0 : {cipo, data_reg[SPI_DATA_WIDTH-1:1]};
wire copi_data = !sync_rst_n ? 0 : data_reg[0];
wire shift_trigger = !sync_rst_n || (txf_en && clk_counter == CLOCK_RATIO-1);
always_ff @(posedge sys_clk) begin
    if (shift_trigger) begin
        copi <= copi_data;
        data_reg <= shift_in_data;
    end
end

reg rx_data_valid;
always_comb begin
    case(current_state)
        IDLE:
        begin
            next_state = start_txn ? INIT : current_state;
        end
        INIT:
        begin
            next_state = ~p_sel_n_reg != 0 ? TXF : current_state;
        end
        TXF:
        begin
            next_state = spi_bit_counter == BITCOUNT-1 ? STOP : current_state;
        end
        STOP:
        begin
            next_state = rx_data_valid ? IDLE : current_state;
        end
        default:
            next_state = current_state;
    endcase
end

wire state_trigger = !sync_rst_n || sys_clk_en;
always_ff @(posedge sys_clk) begin
    if (state_trigger) begin
        current_state <= !sync_rst_n ? IDLE : next_state;
    end
end


assign p_sel_n = txf_en ? {PERI_CNT{1'b1}} : p_sel_n_reg;
assign p_clk = txf_en ? cpol : p_clk_reg;

endmodule

`default_nettype wire
