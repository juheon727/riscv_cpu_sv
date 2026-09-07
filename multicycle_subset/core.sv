module datapath (
    input logic clk,
    input logic reset,
    input logic [31:0] instr, // Loaded on IF -> ID edge
    output logic [63:0] imem_addr,
    input logic [63:0] dmem_fetch, // A synchronized data memory module will load the correct value of data memory on an ld instruction on EX -> MEM edge.
    output logic dmem_read,
    output logic dmem_write,
    output logic [63:0] dmem_addr,
    output logic [63:0] dmem_data
);

enum {
    IF, ID, EX, MEM, WB
} processor_state;

// ID phase

logic reg_write_dec;
logic [4:0] reg_waddr;
logic [4:0] reg_raddr1;
logic [4:0] reg_raddr2;
logic use_imm_in_alu;
logic [63:0] imm;
logic [3:0] alu_opcode;
logic dmem_read_dec;
logic dmem_write_dec;
logic load_instr;
logic branch;
logic illegal;

riscv_subset_decoder instr_decoder (
    .instr(instr),
    .reg_write(reg_write_dec),
    .reg_waddr(reg_waddr),
    .reg_raddr1(reg_raddr1),
    .reg_raddr2(reg_raddr2),
    .use_imm_in_alu(use_imm_in_alu),
    .imm(imm),
    .alu_opcode(alu_opcode),
    .dmem_read(dmem_read_dec),
    .dmem_write(dmem_write_dec),
    .load_instr(load_instr),
    .branch(branch),
    .illegal(illegal)
);

logic reg_write;
assign reg_write = reg_write_dec & (processor_state == WB);
assign dmem_read = dmem_read_dec & (processor_state == MEM);
assign dmem_write = dmem_write_dec & (processor_state == MEM);

logic [63:0] reg_wdata;
logic [63:0] reg_rdata1;
logic [63:0] reg_rdata2; // Loaded on ID -> EX edge
logic [63:0] alu_input2;

// ID/EX

riscv_regfile regfile (
    .clk(clk),
    .reset(reset),
    .write_enable(reg_write),
    .write_data(reg_wdata),
    .write_addr(reg_waddr),
    .read_addr1(reg_raddr1),
    .read_addr2(reg_raddr2),
    .read_port1(reg_rdata1), // Regfile output ports
    .read_port2(reg_rdata2)
);

// EX phase

logic zero_flag; // Used for branching
logic [63:0] alu_result;

always_comb begin
    if (use_imm_in_alu)
        alu_input2 = imm;
    else
        alu_input2 = reg_rdata2;
end

alu_64 alu (
    .operand_1(reg_rdata1),
    .operand_2(alu_input2),
    .opcode(alu_opcode),
    .result(alu_result),
    .zero_flag(zero_flag)
);

// EX/MEM

packed_dff #(
    .WORD_SIZE(64)
) alu_result_dff_ex_mem (
    .clk(clk),
    .reset(reset),
    .write_enable(1'b1),
    .write_data(alu_result),
    .stored_data(dmem_addr)
);

packed_dff #(
    .WORD_SIZE(64)
) reg_rdata2_dff_ex_mem (
    .clk(clk),
    .reset(reset),
    .write_enable(1'b1),
    .write_data(reg_rdata2),
    .stored_data(dmem_data)
);

// MEM will be handled by the external memory module.

// MEM/WB

logic [63:0] alu_result_wb;

packed_dff #(
    .WORD_SIZE(64)
) alu_result_dff_mem_wb (
    .clk(clk),
    .reset(reset),
    .write_enable(1'b1),
    .write_data(dmem_addr),
    .stored_data(alu_result_wb)
);

// WB phase
always_comb begin
    if (load_instr)
        reg_wdata = dmem_fetch;
    else
        reg_wdata = alu_result_wb;
end

logic [63:0] instr_addr; // PC will update on WB -> IF edge.
logic [63:0] next_instr_addr;
assign imem_addr = instr_addr;

always_comb begin
    if (branch & zero_flag)
        next_instr_addr = instr_addr + imm;
    else
        next_instr_addr = instr_addr + 64'd4;
end

always_ff @(posedge clk) begin
    if (reset) begin
        processor_state <= IF;
        instr_addr <= 64'b0;
    end
    else begin
        case (processor_state)
            IF: processor_state <= ID;
            ID: processor_state <= EX;
            EX: processor_state <= MEM;
            MEM: processor_state <= WB;
            WB: begin
                processor_state <= IF;
                instr_addr <= next_instr_addr;
            end
        endcase
    end
end

endmodule

module riscv64_core (
    input logic clk,
    input logic reset,
    input logic [31:0] instr, // Loaded on IF -> ID edge
    output logic [63:0] imem_addr,
    output logic imem_read,
    input logic [63:0] dmem_fetch, // A synchronized data memory module will load the correct value of data memory on an ld instruction on EX -> MEM edge.
    output logic dmem_read,
    output logic dmem_write,
    output logic [63:0] dmem_addr,
    output logic [63:0] dmem_data
);

assign imem_read = 1'b1;

// I know it's not datapath, but for compatibility reasons with testbench.
datapath datapath_i (
    .clk(clk),
    .reset(reset),
    .instr(instr),
    .imem_addr(imem_addr),
    .dmem_fetch(dmem_fetch),
    .dmem_read(dmem_read),
    .dmem_write(dmem_write),
    .dmem_addr(dmem_addr),
    .dmem_data(dmem_data)
);

endmodule;