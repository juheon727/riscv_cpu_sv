module pc_register (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic branch_cond,
    input logic [63:0] branch_pc,
    output logic [63:0] pc
);

always_ff @(posedge clk) begin
    if (!stall) begin
        if (branch_cond)
            pc <= branch_pc;
        else
            pc <= pc + 64'd4;
    end
end

endmodule