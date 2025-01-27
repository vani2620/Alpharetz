/*
 *Author: vani2620
 *Date created: 18012025
*/

// verilog_lint: waive-start macro-name-style
// verilog_lint: waive-start parameter-name-style
`ifndef alpharetz_cpu_params
`define alpharetz_cpu_params
parameter int CPU_DATA_WIDTH = 16;
parameter int CPU_REG_COUNT = 16;
localparam int REG_ADDR_WIDTH = $clog2(CPU_REG_COUNT);
parameter int OPCODE_WIDTH = 4;
parameter int CPU_INST_WIDTH = 16;
parameter int LONG_IMM_WIDTH = 8;
parameter int SHORT_IMM_WIDTH = 4;
parameter int FLAG_REG_WIDTH = 8;
`endif
