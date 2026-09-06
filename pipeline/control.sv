module imm_sign_extend #(
    parameter IMM_WIDTH_IN = 12,
    parameter IMM_WIDTH_OUT = 64
)(
    input logic [IMM_WIDTH_IN - 1 : 0] imm_in,
    output logic [IMM_WIDTH_OUT - 1 : 0] imm_out
);

assign imm_out = {
    {(IMM_WIDTH_OUT - IMM_WIDTH_IN){imm_in[IMM_WIDTH_IN - 1]}}, 
    imm_in};

endmodule

task automatic ld_and_sd (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [31:0] instr,
    inout logic reg_write,
    inout logic use_imm_in_alu,
    inout logic [11:0] imm12,
    inout logic [3:0] alu_opcode,
    inout logic dmem_read,
    inout logic dmem_write,
    inout logic load_instr,
    inout logic illegal
);

case (opcode)
    //ld
    7'b0000011: begin
        if (funct3 == 3'b011) begin
            reg_write = 1'b1;
            use_imm_in_alu = 1'b1;
            imm12 = instr[31:20];
            alu_opcode = 4'b0010;
            dmem_read = 1'b1;
            load_instr = 1'b1;
            illegal = 1'b0;
        end
    end
    //sd
    7'b0100011: begin
        if (funct3 == 3'b011) begin
            use_imm_in_alu = 1'b1;
            imm12 = {instr[31:25], instr[11:7]};
            alu_opcode = 4'b0010;
            dmem_write = 1'b1;
            illegal = 1'b0;
        end
    end
endcase

endtask

task automatic rtype_decode (
    input logic [6:0] funct7,
    input logic [2:0] funct3,
    output logic reg_write,
    output logic [3:0] alu_opcode,
    output logic illegal
);

case ({funct7, funct3})
    10'b0000000111: begin
        reg_write = 1'b1;
        alu_opcode = 4'b0;
        illegal = 1'b0;
    end
    10'b0000000110: begin
        reg_write = 1'b1;
        alu_opcode = 4'b0001;
        illegal = 1'b0;
    end
    10'b0000000000: begin
        reg_write = 1'b1;
        alu_opcode = 4'b0010;
        illegal = 1'b0;
    end
    10'b0100000000: begin
        reg_write = 1'b1;
        alu_opcode = 4'b0110;
        illegal = 1'b0;
    end
endcase

endtask

task automatic immediate_arithmetic_decode (
    input logic [2:0] funct3,
    input logic [31:0] instr,
    output logic reg_write,
    output logic [3:0] alu_opcode,
    output logic use_imm_in_alu,
    output logic [11:0] imm12,
    output logic illegal
);

case (funct3)
    3'b111: begin
        reg_write = 1'b1;
        alu_opcode = 4'b0;
        use_imm_in_alu = 1'b1;
        imm12 = instr[31:20];
        illegal = 1'b0;
    end
    3'b110: begin
        reg_write = 1'b1;
        alu_opcode = 4'b0001;
        use_imm_in_alu = 1'b1;
        imm12 = instr[31:20];
        illegal = 1'b0;
    end
    3'b000: begin
        reg_write = 1'b1;
        alu_opcode = 4'b0010;
        use_imm_in_alu = 1'b1;
        imm12 = instr[31:20];
        illegal = 1'b0;
    end
endcase

endtask

module riscv_subset_decoder (
    input logic [31:0] instr,
    output logic reg_write,
    output logic [4:0] reg_waddr,
    output logic [4:0] reg_raddr1,
    output logic [4:0] reg_raddr2,
    output logic use_imm_in_alu,
    output logic [63:0] imm,
    output logic [3:0] alu_opcode,
    output logic dmem_read,
    output logic dmem_write,
    output logic load_instr,
    output logic branch,
    output logic illegal
);

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = instr[6:0];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];

logic [11:0] imm12;

imm_sign_extend #(
    .IMM_WIDTH_IN(12),
    .IMM_WIDTH_OUT(64)
) imm_extender (
    .imm_in(imm12),
    .imm_out(imm)
);

assign reg_waddr = instr[11:7];
assign reg_raddr1 = instr[19:15];
assign reg_raddr2 = instr[24:20];

always_comb begin
    reg_write = 1'b0;
    use_imm_in_alu = 1'b0;
    imm12 = 12'b0;
    alu_opcode = 4'b0;
    dmem_read = 1'b0;
    dmem_write = 1'b0;
    load_instr = 1'b0;
    branch = 1'b0;
    illegal = 1'b1;

    ld_and_sd(
        opcode,
        funct3,
        instr,
        reg_write,
        use_imm_in_alu,
        imm12,
        alu_opcode,
        dmem_read,
        dmem_write,
        load_instr,
        illegal
    );

    case (opcode)
        //beq: SL1 will be outsourced to PC update logic.
        7'b1100011: begin
            if (funct3 == 3'b000) begin
                alu_opcode = 4'b0110;
                branch = 1'b1;
                imm12 = {
                    instr[31],
                    instr[7],
                    instr[30:25],
                    instr[11:8]
                };
                illegal = 1'b0;
            end
        end
        //arith: and, or, add, sub
        7'b0110011: begin
            rtype_decode(funct7, funct3, reg_write, alu_opcode, illegal);
        end
        //immediate arithmetic: andi, ori, addi
        7'b0010011: begin
            immediate_arithmetic_decode(funct3, instr, reg_write, alu_opcode, use_imm_in_alu, imm12, illegal);
        end
    endcase
end

endmodule