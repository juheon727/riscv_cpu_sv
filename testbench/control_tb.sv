`timescale 1ns/1ps

module riscv_subset_decoder_tb;

    logic [31:0] instr;

    logic        reg_write;
    logic [4:0]  reg_waddr;
    logic [4:0]  reg_raddr1;
    logic [4:0]  reg_raddr2;
    logic        use_imm_in_alu;
    logic [63:0] imm;
    logic [3:0]  alu_opcode;
    logic        dmem_write;
    logic        load_instr;
    logic        branch;
    logic        illegal;

    // DUT
    riscv_subset_decoder dut (
        .instr          (instr),
        .reg_write      (reg_write),
        .reg_waddr      (reg_waddr),
        .reg_raddr1     (reg_raddr1),
        .reg_raddr2     (reg_raddr2),
        .use_imm_in_alu (use_imm_in_alu),
        .imm            (imm),
        .alu_opcode     (alu_opcode),
        .dmem_write     (dmem_write),
        .load_instr     (load_instr),
        .branch         (branch),
        .illegal        (illegal)
    );


    // ------------------------------------------------------------
    // Test helper
    // ------------------------------------------------------------
    task automatic check(
        input string test_name,
        input logic exp_reg_write,
        input logic exp_use_imm,
        input logic [63:0] exp_imm,
        input logic [3:0] exp_alu_opcode,
        input logic exp_dmem_write,
        input logic exp_load,
        input logic exp_branch,
        input logic exp_illegal
    );
        #1;

        if ((reg_write      !== exp_reg_write) ||
            (use_imm_in_alu !== exp_use_imm)   ||
            (imm            !== exp_imm)       ||
            (alu_opcode     !== exp_alu_opcode)||
            (dmem_write     !== exp_dmem_write)||
            (load_instr     !== exp_load)      ||
            (branch         !== exp_branch)    ||
            (illegal        !== exp_illegal)) begin

            $display("FAIL: %s", test_name);
            $display("  instr          = %h", instr);
            $display("  reg_write      = %b (expected %b)",
                     reg_write, exp_reg_write);
            $display("  use_imm_in_alu = %b (expected %b)",
                     use_imm_in_alu, exp_use_imm);
            $display("  imm            = %h (expected %h)",
                     imm, exp_imm);
            $display("  alu_opcode     = %b (expected %b)",
                     alu_opcode, exp_alu_opcode);
            $display("  dmem_write     = %b (expected %b)",
                     dmem_write, exp_dmem_write);
            $display("  load_instr     = %b (expected %b)",
                     load_instr, exp_load);
            $display("  branch         = %b (expected %b)",
                     branch, exp_branch);
            $display("  illegal        = %b (expected %b)",
                     illegal, exp_illegal);
        end
        else begin
            $display("PASS: %s", test_name);
        end
    endtask


    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, riscv_subset_decoder_tb);

        // ========================================================
        // 1. LD x5, 16(x3)
        //
        // imm    = 16
        // rs1    = x3
        // funct3 = 011
        // rd     = x5
        // opcode = 0000011
        // ========================================================

        instr = {
            12'd16,
            5'd3,
            3'b011,
            5'd5,
            7'b0000011
        };

        check(
            "LD x5, 16(x3)",
            1'b1,           // reg_write
            1'b1,           // use immediate
            64'd16,         // immediate
            4'b0010,        // ADD
            1'b0,           // dmem_write
            1'b1,           // load
            1'b0,           // branch
            1'b0            // illegal
        );


        // ========================================================
        // 2. LD with negative immediate
        // LD x5, -8(x3)
        // ========================================================

        instr = {
            12'hFF8,        // -8
            5'd3,
            3'b011,
            5'd5,
            7'b0000011
        };

        check(
            "LD x5, -8(x3)",
            1'b1,
            1'b1,
            64'hFFFF_FFFF_FFFF_FFF8,
            4'b0010,
            1'b0,
            1'b1,
            1'b0,
            1'b0
        );


        // ========================================================
        // 3. SD x7, 24(x4)
        //
        // S-type immediate:
        // imm[11:5] = 0
        // imm[4:0]  = 24
        // ========================================================

        instr = {
            7'b0000000,
            5'd7,           // rs2
            5'd4,           // rs1
            3'b011,
            5'd24,          // imm[4:0]
            7'b0100011
        };

        check(
            "SD x7, 24(x4)",
            1'b0,
            1'b1,
            64'd24,
            4'b0010,
            1'b1,
            1'b0,
            1'b0,
            1'b0
        );


        // ========================================================
        // 4. AND x5, x3, x4
        // ========================================================

        instr = {
            7'b0000000,
            5'd4,
            5'd3,
            3'b111,
            5'd5,
            7'b0110011
        };

        check(
            "AND x5, x3, x4",
            1'b1,
            1'b0,
            64'd0,
            4'b0000,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );


        // ========================================================
        // 5. OR x5, x3, x4
        // ========================================================

        instr = {
            7'b0000000,
            5'd4,
            5'd3,
            3'b110,
            5'd5,
            7'b0110011
        };

        check(
            "OR x5, x3, x4",
            1'b1,
            1'b0,
            64'd0,
            4'b0001,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );


        // ========================================================
        // 6. ADD x5, x3, x4
        // ========================================================

        instr = {
            7'b0000000,
            5'd4,
            5'd3,
            3'b000,
            5'd5,
            7'b0110011
        };

        check(
            "ADD x5, x3, x4",
            1'b1,
            1'b0,
            64'd0,
            4'b0010,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );


        // ========================================================
        // 7. SUB x5, x3, x4
        // ========================================================

        instr = {
            7'b0100000,
            5'd4,
            5'd3,
            3'b000,
            5'd5,
            7'b0110011
        };

        check(
            "SUB x5, x3, x4",
            1'b1,
            1'b0,
            64'd0,
            4'b0110,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );


        // ========================================================
        // 8. BEQ with offset +8
        //
        // B immediate:
        // imm[12]   -> instr[31]
        // imm[11]   -> instr[7]
        // imm[10:5] -> instr[30:25]
        // imm[4:1]  -> instr[11:8]
        // imm[0]    -> 0
        // ========================================================

        instr = {
            1'b0,           // imm[12]
            6'b000000,      // imm[10:5]
            5'd4,           // rs2
            5'd3,           // rs1
            3'b000,
            4'b0100,        // imm[4:1] => offset 8
            1'b0,           // imm[11]
            7'b1100011
        };

        check(
            "BEQ x3, x4, +8",
            1'b0,
            1'b0,
            64'd8,
            4'b0110,
            1'b0,
            1'b0,
            1'b1,
            1'b0
        );


        // ========================================================
        // 9. Illegal opcode
        // ========================================================

        instr = 32'h00000000;

        check(
            "Illegal opcode",
            1'b0,
            1'b0,
            64'd0,
            4'b0000,
            1'b0,
            1'b0,
            1'b0,
            1'b1
        );

        instr = 32'hdeadbeef;

        check(
            "Illegal opcode",
            1'b0,
            1'b0,
            64'd0,
            4'b0000,
            1'b0,
            1'b0,
            1'b0,
            1'b1
        );


        // ========================================================
        // 10. Correct opcode but unsupported funct3
        // Example: load opcode with funct3 = 010
        // ========================================================

        instr = {
            12'd8,
            5'd3,
            3'b010,
            5'd5,
            7'b0000011
        };

        check(
            "Illegal load funct3",
            1'b0,
            1'b0,
            64'd0,
            4'b0000,
            1'b0,
            1'b0,
            1'b0,
            1'b1
        );

        instr = {
            12'b000000110000,
            5'b00000,
            3'b000,
            5'b00010,
            7'b0010011
        };

        check(
            "ADDI x2, x0, 48",
            1'b1,
            1'b1,
            64'd48,
            4'b0010,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        $display("----------------------------------------");
        $display("Decoder tests completed.");
        $display("----------------------------------------");

        $finish;
    end

endmodule