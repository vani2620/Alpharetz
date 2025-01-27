/*
 *Author: vani2620
 *Date created: 24012025
*/

`include "alpharetz_uart_params.svh"

`default_nettype none
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

module alpharetz_uart_tx(
    input wire sys_clk,
    input wire sys_clk_en,
    input wire sync_rst,

    // From CPU
    input wire [UART_DATA_WIDTH-1:0] tx_data,
    input wire start_tx,

    // To device
    output wire uart_tx,

    //To CPU
    output wire busy
);

wire cpol = 0;
wire uart_clk;
wire [15:0] uart_clk_counter;
clock_divider #(
    .CLOCK_RATIO(UART_CLK_RATIO)
) uart_tx_clk_div (
    .clk_in(sys_clk),
    .clk_en(sys_clk_en),
    .sync_rst(sync_rst),
    .cpol(cpol),
    .clk_out(uart_clk),
    .counter_out(uart_clk_counter)
);

localparam int UART_COUNTER_WIDTH = $clog2(UART_DATA_WIDTH);
//? State logic
        //* Control wires
        wire uart_clk_maxed = uart_clk_counter == UART_CLK_RATIO; //state transitions
        reg [UART_COUNTER_WIDTH-1:0] uart_bit_counter; //controls data transmission
        //* State machine
        typedef enum bit [2:0] {IDLE=3'b000, START=3'b001, DATA=3'b010, PARITY=3'b011, STOP=3'b100} uart_state_t;
        reg [2:0] current_state;
        wire active = |current_state;
        logic [3:0] state_tracker;
        always_comb begin : state_update
            case(current_state)
                IDLE: state_tracker = {start_tx, START};
                START: state_tracker = {uart_clk_counter, DATA};
                DATA: state_tracker = {uart_bit_counter, PARITY};
                PARITY: state_tracker = {uart_clk_counter, STOP};
                STOP: state_tracker = {!busy, IDLE};
                default: state_tracker = 0;
            endcase
        end
        wire [2:0] next_state = sync_rst ? 0 : state_tracker[2:0];
        wire change_state = sync_rst || sys_clk_en & state_tracker[3];
        always_ff @(posedge sys_clk) begin
            if (change_state) begin
                current_state <= next_state;
            end
        end

reg [UART_DATA_WIDTH-1:0] shift_reg;
wire regwrite = sync_rst || sys_clk_en & current_state == START;
wire start_bit = 1'b0;
wire stop_bit = 1'b1;
wire parity_bit = ^tx_data;
logic [UART_DATA_WIDTH-1:0] data;
always_comb begin : update_shift_reg
    case(current_state)
        START: data = tx_data;
        DATA: data = shift_reg << 1;
    default: data = 0;
    endcase
end
always_ff @(posedge sys_clk) begin : store_data
    if (regwrite) begin
        shift_reg <= data;
    end
end

wire [UART_COUNTER_WIDTH-1:0] count = sync_rst ? 0 : uart_bit_counter + 1;
wire counter_trigger = sync_rst || sys_clk_en & current_state == DATA;
always_ff @(posedge sys_clk) begin : update_count
    if (counter_trigger) begin
        uart_bit_counter <= count;
    end
end

wire transmit_en = sync_rst || sys_clk_en & active;
logic tx;
always_ff @(posedge sys_clk) begin : transmit
    if (transmit_en) begin
        case (current_state)
            IDLE: tx <= 0;
            START: tx <= start_bit;
            DATA: tx <= shift_reg[0];
            PARITY: tx <= parity_bit;
            STOP: tx <= stop_bit;
            default: tx <= 1;
        endcase
    end
end

assign uart_tx = tx;
assign busy = active;

endmodule

`default_nettype wire
