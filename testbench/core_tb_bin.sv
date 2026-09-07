`timescale 1ns/1ps

module riscv64_core_tb;

logic clk;
logic reset;

logic [31:0] instr;
logic [63:0] imem_addr;
logic imem_read;

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
    .imem_read  (imem_read),

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
    .read_enable(imem_read),
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
    $dumpvars(0, riscv64_core_tb);
end

initial begin
    reset = 1'b1;
    #12;
    reset = 1'b0;
end

initial begin
    #13;
    $readmemh("testbench/assembly/ld_use.hex", instr_memory.memory);
end

always @(posedge clk) begin
    $display(
        "time=%0t PC=%0d x1=%0d x2=%0d x3=%0d x4=%0d ALU=%0d",
        $time,
        imem_addr,
        //dut.processor_state,
        dut.datapath_i.regfile.data[1],
        dut.datapath_i.regfile.data[2],
        dut.datapath_i.regfile.data[3],
        dut.datapath_i.regfile.data[4],
        dut.datapath_i.alu_result
    );
end

initial begin
    repeat (150) @(posedge clk);
    #1;
    $finish;
end

endmodule