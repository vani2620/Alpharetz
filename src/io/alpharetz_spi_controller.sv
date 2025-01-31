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
    input wire sync_rst,

    //From CPU
    input wire [SPI_DATA_WIDTH-1:0] tx_data,
    input wire start_txn, //DATA VALID
    input wire [P_ADDR_WIDTH-1:0] p_addr,

    //From peripheral
    input wire cipo,

    //To peripheral
    output reg copi,
    output wire p_clk,
    output reg [PERI_CNT-1:0] p_sel_n,

    //To CPU
    output reg [SPI_DATA_WIDTH-1:0] rx_data,
    output reg end_txn, //DATA VALID
    output reg busy
);


wire cpol = CPOL;
reg p_clk_reg;
reg [15:0] clk_counter;

clock_divider #(
    .CLOCK_RATIO(SPI_CLK_RATIO)
) spi_clk_div (
    .clk_in(sys_clk),
    .clk_en(sys_clk_en),
    .sync_rst(sync_rst),
    .cpol(cpol),
    .counter_out(clk_counter),
    .clk_out(p_clk_reg)
);
localparam int BITCOUNT = $clog2(SPI_DATA_WIDTH);
//? State Logic
    //* State control signals
    wire spi_clk_maxed = clk_counter == SPI_CLK_RATIO-1; // Controls P_CLK
    reg [BITCOUNT-1:0] spi_bit_counter;
    wire spi_cnt_maxed = spi_bit_counter == SPI_DATA_WIDTH-1; // Controls shifting
    reg [PERI_CNT-1:0] p_sel_n_reg; // Starts transfer of data
    wire p_selected = ~p_sel_n_reg != 0;
    reg rx_data_valid; // Signifies end of transaction
    //* State Machine
    typedef enum bit [1:0] {IDLE = 2'b00, INIT = 2'b01, TXF = 2'b10, STOP = 2'b11} spi_state_t;
    reg [1:0] current_state;
    wire active = |current_state;
    logic [2:0] state_tracker;
    always_comb begin : track_state
        case (current_state)
        IDLE: state_tracker = {start_txn, INIT};
        INIT: state_tracker = {p_selected, TXF};
        TXF: state_tracker = {spi_cnt_maxed, STOP};
        STOP: state_tracker = {rx_data_valid, IDLE};
        default: state_tracker = 0;
        endcase
    end
    wire [1:0] next_state = sync_rst ? 0 : state_tracker[1:0];
    wire state_trigger = sync_rst || sys_clk_en && state_tracker[2];
    always_ff @( posedge sys_clk ) begin : update_state
        if (state_trigger) current_state <= next_state;
    end

wire p_decode_en = sync_rst || (sys_clk_en && spi_bit_counter == 0);
logic [PERI_CNT-1:0] p_selector_next;
always_comb begin : decode_peripheral_select
    p_selector_next = {PERI_CNT{1'b1}};
    p_selector_next[p_addr] = !(sync_rst || spi_clk_maxed);
end
always_ff @(negedge sys_clk) begin
    if (p_decode_en) p_sel_n_reg <= p_selector_next;
end

reg [SPI_DATA_WIDTH-1:0] shift_buffer;
wire buf_en = current_state == INIT || current_state == TXF;
wire regwrite = sync_rst || sys_clk_en && buf_en && p_selected;
logic [SPI_DATA_WIDTH-1:0] buf_data;
always_comb begin : set_data
    case(current_state)
    INIT: buf_data = tx_data;
    TXF: buf_data = spi_clk_maxed ? {cipo, shift_buffer[SPI_DATA_WIDTH-1:1]} : shift_buffer;
    default: buf_data = 0;
    endcase
end
always_ff @(posedge sys_clk) begin : update_buffer
    if (regwrite) shift_buffer <= buf_data;
end
wire copi_data = sync_rst ? 0 : shift_buffer[0];
wire copi_trigger = sync_rst || (sys_clk_en && current_state == TXF);
always_ff @(posedge sys_clk) begin
    if (copi_trigger) copi <= copi_data;
end

wire [BITCOUNT-1:0] bit_count = sync_rst ? 0 : spi_bit_counter + 'd1;
wire cnt_trigger = sync_rst || (sys_clk_en && spi_clk_maxed && p_selected);
always_ff @(posedge sys_clk) begin
    if (cnt_trigger) spi_bit_counter <= bit_count;
end

wire rx_dv = sync_rst ? 0 : spi_cnt_maxed;
wire rx_data_trigger = sync_rst || sys_clk_en && spi_cnt_maxed;
wire rx_data_next = sync_rst ? 0 : shift_buffer;
always_ff @(posedge sys_clk) begin
    if (rx_data_trigger) begin
        rx_data_valid <= rx_dv;
        rx_data <= rx_data_next;
    end
end

assign end_txn = rx_data_valid;
assign busy = active;
assign p_clk = p_selected ? cpol : p_clk_reg;
assign p_sel_n = p_sel_n_reg;

endmodule

`ifdef FORMAL
initial last_clk = 1'b0;
always @($global_clock)
    assume(sys_clk != last_clk)
`endif

`default_nettype wire
