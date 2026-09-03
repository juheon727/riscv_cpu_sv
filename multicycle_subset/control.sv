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
logic [12:0] imm13;
logic [63:0] imm_mem;
logic [63:0] imm_b;

imm_sign_extend #(
    .IMM_WIDTH_IN(12),
    .IMM_WIDTH_OUT(64)
) imm_extender_mem (
    .imm_in(imm12),
    .imm_out(imm_mem)
);

imm_sign_extend #(
    .IMM_WIDTH_IN(13),
    .IMM_WIDTH_OUT(64)
) imm_extender_b (
    .imm_in(imm13),
    .imm_out(imm_b)
);

assign reg_waddr = instr[11:7];
assign reg_raddr1 = instr[19:15];
assign reg_raddr2 = instr[24:20];

always_comb begin
    reg_write = 1'b0;
    use_imm_in_alu = 1'b0;
    imm12 = 12'b0;
    imm13 = 13'b0;
    imm = 64'b0;
    alu_opcode = 4'b0;
    dmem_read = 1'b0;
    dmem_write = 1'b0;
    load_instr = 1'b0;
    branch = 1'b0;
    illegal = 1'b1;

    case (opcode)
        //ld
        7'b0000011: begin
            if (funct3 == 3'b011) begin
                reg_write = 1'b1;
                use_imm_in_alu = 1'b1;
                imm12 = instr[31:20];
                imm = imm_mem;
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
                imm = imm_mem;
                alu_opcode = 4'b0010;
                dmem_write = 1'b1;
                illegal = 1'b0;
            end
        end
        //beq
        7'b1100011: begin
            if (funct3 == 3'b000) begin
                alu_opcode = 4'b0110;
                branch = 1'b1;
                imm13 = {
                    instr[31],
                    instr[7],
                    instr[30:25],
                    instr[11:8],
                    1'b0
                };
                imm = imm_b;
                illegal = 1'b0;
            end
        end
        //arith: and, or, add, sub
        7'b0110011: begin
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
        end
        //immediate arithmetic: andi, ori, addi
        7'b0010011: begin
            case (funct3)
                3'b111: begin
                    reg_write = 1'b1;
                    alu_opcode = 4'b0;
                    use_imm_in_alu = 1'b1;
                    imm12 = instr[31:20];
                    imm = imm_mem;
                    illegal = 1'b0;
                end
                3'b110: begin
                    reg_write = 1'b1;
                    alu_opcode = 4'b0001;
                    use_imm_in_alu = 1'b1;
                    imm12 = instr[31:20];
                    imm = imm_mem;
                    illegal = 1'b0;
                end
                3'b000: begin
                    reg_write = 1'b1;
                    alu_opcode = 4'b0010;
                    use_imm_in_alu = 1'b1;
                    imm12 = instr[31:20];
                    imm = imm_mem;
                    illegal = 1'b0;
                end
            endcase
        end
    endcase
end

endmodule