`timescale 1ns/1ps

module riscv64_subset_core_multicycle_tb;

    logic clk;
    logic reset;

    logic [31:0] instr;
    logic [63:0] imem_addr;

    logic [63:0] dmem_fetch;
    logic        dmem_read;
    logic        dmem_write;
    logic [63:0] dmem_addr;
    logic [63:0] dmem_data;


    riscv64_subset_core_multicycle dut (
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


    // 10 ns clock period
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

        // Initial values
        reset = 1'b1;
        instr = 32'b0;
        dmem_fetch = 64'b0;

        // Reset
        #12;
        reset = 1'b0;


        /*
         * add x3, x1, x2
         *
         * funct7 = 0000000
         * rs2    = 00010
         * rs1    = 00001
         * funct3 = 000
         * rd     = 00011
         * opcode = 0110011
         */

        instr = {
            7'b0000000,
            5'd2,
            5'd1,
            3'b000,
            5'd3,
            7'b0110011
        };


        /*
         * Testbench에서 DUT 내부 register를
         * 직접 초기화.
         *
         * x1 = 10
         * x2 = 20
         *
         * 따라서 예상:
         * x3 = 30
         */

        dut.regfile.data[1] = 64'd10;
        dut.regfile.data[2] = 64'd20;


        // IF → ID → EX → MEM → WB → IF까지 기다림
        repeat (6) @(posedge clk);

        #1;


        if (dut.regfile.data[3] == 64'd30)
            $display("PASS: x3 = %0d", dut.regfile.data[3]);
        else
            $display(
                "FAIL: x3 = %0d, expected 30",
                dut.regfile.data[3]
            );


        $finish;
    end


    // 매 clock마다 주요 signal 출력
    always @(posedge clk) begin
        $display(
            "time=%0t PC=%0d state=%0d x1=%0d x2=%0d x3=%0d ALU=%0d",
            $time,
            imem_addr,
            dut.processor_state,
            dut.regfile.data[1],
            dut.regfile.data[2],
            dut.regfile.data[3],
            dut.alu_result
        );
    end

endmodule