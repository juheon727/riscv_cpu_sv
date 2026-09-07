module riscv64_core (
    input logic clk,
    input logic reset,
    input logic [31:0] instr,
    output logic [63:0] imem_addr,
    input logic [63:0] dmem_fetch,
    output logic dmem_read,
    output logic dmem_write,
    output logic [63:0] dmem_addr,
    output logic [63:0] dmem_data
);

endmodule