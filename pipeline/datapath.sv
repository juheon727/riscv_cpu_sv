typedef struct packed {
    logic reg_write;
    logic [4:0] reg_raddr1;
    logic [4:0] reg_raddr2;
    logic [4:0] reg_waddr;
    logic use_imm_in_alu;
    logic [63:0] imm;
    logic [3:0] alu_opcode;
    logic dmem_read;
    logic dmem_write;
    logic load_instr;
    logic branch;
    logic [63:0] pc;
} ctrl_id_t;

typedef struct packed {
    logic reg_write;
    logic [4:0] reg_waddr;
    logic dmem_read;
    logic dmem_write;
    logic load_instr;
    logic [63:0] alu_result;
    logic [63:0] fw_read2;
} ctrl_ex_t;

typedef struct packed {
    logic reg_write;
    logic [4:0] reg_waddr;
    logic load_instr;
    logic [63:0] alu_result;
} ctrl_mem_t;

module pc_register (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic branch_cond,
    input logic [63:0] branch_pc,
    output logic [63:0] pc
);

always_ff @(posedge clk) begin
    if (reset)
        pc <= 64'd0;
    else begin
        if (!stall) begin
            if (branch_cond)
                pc <= branch_pc;
            else
                pc <= pc + 64'd4;
        end
    end
end

endmodule

module pipeline_register #(
    parameter type T = logic [63:0]
)(
    input logic clk,
    input logic reset,
    input logic flush,
    input logic stall,
    input T ctrl,
    output T ctrl_out
);

always_ff @(posedge clk) begin
    if (reset | flush)
        ctrl_out <= '0;
    else if (!stall)
        ctrl_out <= ctrl;
end

endmodule


module datapath (
    input logic clk,
    input logic reset,
    input logic flush,
    input logic stall,
    input logic [63:0] fw_data1,
    input logic fw_enable1,
    input logic [63:0] fw_data2,
    input logic fw_enable2,
    input logic [31:0] imem_read,
    output logic [63:0] imem_addr,
    input logic [63:0] dmem_rdata,
    output logic dmem_read,
    output logic dmem_write,
    output logic [63:0] dmem_addr,
    output logic [63:0] dmem_wdata,
    output logic [4:0] fw_mem_reg_waddr,
    output logic fw_mem_reg_write,
    output logic [63:0] fw_mem_reg_wdata,
    output logic [4:0] fw_wb_reg_waddr,
    output logic fw_wb_reg_write,
    output logic [63:0] fw_wb_reg_wdata
);

logic branch_cond;
logic [63:0] branch_pc;
logic [63:0] pc_id;

//IF
pc_register pcreg (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .branch_cond(branch_cond),
    .branch_pc(branch_pc),
    .pc(imem_addr)
);

pipeline_register #(
    .T(logic [63:0])
) if_id (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .stall(stall),
    .ctrl(imem_addr),
    .ctrl_out(pc_id)
);

//ID
logic [31:0] instr;
assign instr = flush ? 32'b0 : imem_read;

logic illegal;
ctrl_id_t ctrl_id, ctrl_id_out;
logic [63:0] reg_waddr;
logic [63:0] reg_wdata;
logic reg_write;

riscv_subset_decoder decoder (
    .instr(instr),
    .reg_write(ctrl_id.reg_write),
    .reg_waddr(ctrl_id.reg_waddr),
    .reg_raddr1(ctrl_id.reg_raddr1),
    .reg_raddr2(ctrl_id.reg_raddr2),
    .use_imm_in_alu(ctrl_id.use_imm_in_alu),
    .imm(ctrl_id.imm),
    .alu_opcode(ctrl_id.alu_opcode),
    .dmem_read(ctrl_id.dmem_read),
    .dmem_write(ctrl_id.dmem_write),
    .load_instr(ctrl_id.load_instr),
    .branch(ctrl_id.branch),
    .illegal(illegal)
);

assign ctrl_id.pc = pc_id;

//EX
pipeline_register #(
    .T(ctrl_id_t)
) id_ex (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .stall(stall),
    .ctrl(ctrl_id),
    .ctrl_out(ctrl_id_out)
);

logic [63:0] reg_read1, reg_read2;
logic [63:0] fw_read1, fw_read2;
logic [63:0] alu_operand2;
logic [63:0] alu_result;
logic [63:0] imm_sl1;
logic zero_flag;

riscv_regfile regfile (
    .clk(clk),
    .reset(reset),
    .write_enable(reg_write),
    .write_data(reg_wdata),
    .read_addr1(ctrl_id_out.reg_raddr1),
    .read_addr2(ctrl_id_out.reg_raddr2),
    .read_port1(reg_read1),
    .read_port2(reg_read2)
);

assign fw_read1 = fw_enable1? fw_data1 : reg_read1;
assign fw_read2 = fw_enable2? fw_data2 : reg_read2;
assign alu_operand2 = ctrl_id_out.use_imm_in_alu? ctrl_id_out.imm : fw_read2;

alu_64 alu (
    .operand_1(fw_read1),
    .operand_2(alu_operand2),
    .opcode(ctrl_id_out.alu_opcode),
    .result(alu_result),
    .zero_flag(zero_flag)
);

ctrl_ex_t ctrl_ex, ctrl_ex_out;
assign ctrl_ex = '{
    reg_write: ctrl_id_out.reg_write,
    reg_waddr: ctrl_id_out.reg_waddr,
    dmem_read: ctrl_id_out.dmem_read,
    dmem_write: ctrl_id_out.dmem_write,
    load_instr: ctrl_id_out.load_instr,
    alu_result: alu_result,
    fw_read2: fw_read2
};

pipeline_register #(
    .T(ctrl_ex_t)
) ex_mem (
    .clk(clk),
    .reset(reset),
    .flush(1'b0),
    .stall(1'b0),
    .ctrl(ctrl_ex),
    .ctrl_out(ctrl_ex_out)
);

assign branch_cond = ctrl_id_out.branch & zero_flag;
assign imm_sl1 = {ctrl_id_out.imm[62:0], 1'b0};
assign branch_pc = ctrl_id_out.pc + imm_sl1;

//MEM: handled by external memory module
assign dmem_read = ctrl_ex_out.dmem_read;
assign dmem_write = ctrl_ex_out.dmem_write;
assign dmem_addr = ctrl_ex_out.alu_result;
assign dmem_wdata = ctrl_ex_out.fw_read2;

assign fw_mem_reg_waddr = ctrl_ex_out.reg_waddr;
assign fw_mem_reg_wdata = ctrl_ex_out.alu_result;
assign fw_mem_reg_write = ctrl_ex_out.reg_write;

ctrl_mem_t ctrl_mem, ctrl_mem_out;
assign ctrl_mem = '{
    reg_write: ctrl_ex_out.reg_write,
    reg_waddr: ctrl_ex_out.reg_waddr,
    load_instr: ctrl_ex_out.load_instr,
    alu_result: ctrl_ex_out.alu_result
};

pipeline_register #(
    .T(ctrl_mem_t)
) mem_wb (
    .clk(clk),
    .reset(reset),
    .flush(1'b0),
    .stall(1'b0),
    .ctrl(ctrl_mem),
    .ctrl_out(ctrl_mem_out)
);

endmodule