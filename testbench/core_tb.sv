`timescale 1ns/1ps

module riscv64_core_tb;

logic clk;
logic reset;

logic [31:0] instr;
logic [63:0] imem_addr;

logic [63:0] dmem_fetch;
logic        dmem_read;
logic        dmem_write;
logic [63:0] dmem_addr;
logic [63:0] dmem_data;

riscv64_core dut (
    .clk        (clk),
    .reset      (reset),

    .instr      (instr),
    .imem_addr  (imem_addr),

    .dmem_fetch (dmem_fetch),
    .dmem_read  (dmem_read),
    .dmem_write (dmem_write),
    .dmem_addr  (dmem_addr),
    .dmem_data  (dmem_data)
);

synchronous_memory #(
    .ADDR_WIDTH(12),
    .WORD_SIZE(32)
) instr_memory (
    .clk(clk),
    .reset(reset),
    .read_enable(1'b1),
    .write_enable(1'b0),
    .addr(imem_addr[13:2]),
    .write_data(32'b0),
    .read_data(instr)
);

synchronous_memory #(
    .ADDR_WIDTH(12),
    .WORD_SIZE(64)
) data_memory (
    .clk(clk),
    .reset(reset),
    .read_enable(dmem_read),
    .write_enable(dmem_write),
    .addr(dmem_addr[14:3]),
    .write_data(dmem_data),
    .read_data(dmem_fetch)
);

initial begin
    clk = 1'b0;

    forever begin
        #5;
        clk = ~clk;
    end
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, riscv64_subset_core_multicycle_tb);
end

initial begin
    reset = 1'b1;
    #12;
    reset = 1'b0;
end

initial begin
    // addi x1, x0, 16
    #13;
    instr_memory.memory[0] = {
        12'b000000010000,
        5'b00000,
        3'b000,
        5'b00001,
        7'b0010011
    };

    // addi x2, x0, 48
    instr_memory.memory[1] = {
        12'b000000110000,
        5'b00000,
        3'b000,
        5'b00010,
        7'b0010011
    };

    // sub x3, x2, x1
    instr_memory.memory[2] = {
        7'b0100000,
        5'b00001,
        5'b00010,
        3'b000,
        5'b00011,
        7'b0110011
    };

    // sd x3, 8(x2)
    instr_memory.memory[3] = {
        7'b0000000,
        5'b00011,
        5'b00010,
        3'b011,
        5'b01000,
        7'b0100011
    };

    // ld, x4, 40(x1)
    instr_memory.memory[4] = {
        12'b000000101000,
        5'b00001,
        3'b011,
        5'b00100,
        7'b0000011
    };

    // beq x0, x0, -20
    instr_memory.memory[5] = {
        7'b1111111,
        5'b00000,
        5'b00000,
        3'b000,
        5'b01101,
        7'b1100011
    };
end

always @(posedge clk) begin
    $display(
        "time=%0t PC=%0d state=%0d x1=%0d x2=%0d x3=%0d x4=%0d ALU=%0d",
        $time,
        imem_addr,
        dut.processor_state,
        dut.regfile.data[1],
        dut.regfile.data[2],
        dut.regfile.data[3],
        dut.regfile.data[4],
        dut.alu_result
    );
end

initial begin
    repeat (150) @(posedge clk);
    #1;
    $finish;
end

endmodule