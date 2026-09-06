module alu_64 (
    input logic [63:0] operand_1,
    input logic [63:0] operand_2,
    input logic [3:0] opcode,
    output logic [63:0] result,
    output logic zero_flag
);

assign zero_flag = ~(|result);

always_comb begin
    result = 64'b0;

    case (opcode)
        4'b0000:
            result = operand_1 & operand_2;
        4'b0001:
            result = operand_1 | operand_2;
        4'b0010:
            result = operand_1 + operand_2;
        4'b0110:
            result = operand_1 - operand_2;
    endcase
end

endmodule