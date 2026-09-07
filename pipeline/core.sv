typedef struct packed {
    logic [4:0] fw_ex_reg_raddr1;
    logic [4:0] fw_ex_reg_raddr2;
    logic [4:0] fw_mem_reg_waddr;
    logic fw_mem_reg_write;
    logic [63:0] fw_mem_reg_wdata;
    logic [4:0] fw_wb_reg_waddr;
    logic fw_wb_reg_write;
    logic [63:0] fw_wb_reg_wdata;
} fw_control_in_t;

typedef struct packed {
    logic [63:0] fw_data1;
    logic fw_enable1;
    logic [63:0] fw_data2;
    logic fw_enable2;
} fw_control_out_t;


module fw_controller (
    input fw_control_in_t fw_control_in,
    output fw_control_out_t fw_control_out
);

always_comb begin
    fw_control_out.fw_data1 = 64'b0;
    fw_control_out.fw_enable1 = 1'b0;

    if (fw_control_in.fw_mem_reg_write && 
        (fw_control_in.fw_ex_reg_raddr1 == fw_control_in.fw_mem_reg_waddr)) begin
        fw_control_out.fw_data1 = fw_control_in.fw_mem_reg_wdata;
        fw_control_out.fw_enable1 = 1'b1;
    end
    else if (fw_control_in.fw_wb_reg_write &&
        (fw_control_in.fw_ex_reg_raddr1 == fw_control_in.fw_wb_reg_waddr)) begin
        fw_control_out.fw_data1 = fw_control_in.fw_wb_reg_wdata;
        fw_control_out.fw_enable1 = 1'b1;
    end
end

always_comb begin
    fw_control_out.fw_data2 = 64'b0;
    fw_control_out.fw_enable2 = 1'b0;

    if (fw_control_in.fw_mem_reg_write && 
        (fw_control_in.fw_ex_reg_raddr2 == fw_control_in.fw_mem_reg_waddr)) begin
        fw_control_out.fw_data2 = fw_control_in.fw_mem_reg_wdata;
        fw_control_out.fw_enable2 = 1'b1;
    end
    else if (fw_control_in.fw_wb_reg_write &&
        (fw_control_in.fw_ex_reg_raddr2 == fw_control_in.fw_wb_reg_waddr)) begin
        fw_control_out.fw_data2 = fw_control_in.fw_wb_reg_wdata;
        fw_control_out.fw_enable2 = 1'b1;
    end
end

endmodule

module riscv64_core (
    input logic clk,
    input logic reset,
    input logic [31:0] instr,
    output logic [63:0] imem_addr,
    input logic [63:0] dmem_fetch,
    output logic dmem_read,
    output logic dmem_write,
    output logic [63:0] dmem_addr,
    output logic [63:0] dmem_data
);

fw_control_in_t fw_control_in;
fw_control_out_t fw_control_out;
logic stall;
logic flush;
logic fl_branch_cond;
logic [4:0] st_id_reg_raddr1, st_id_reg_raddr2, st_ex_reg_waddr;
logic st_ex_load_instr;

datapath datapath_i (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .stall(stall),
    .imem_read(instr),
    .imem_addr(imem_addr),
    .dmem_rdata(dmem_fetch),
    .dmem_read(dmem_read),
    .dmem_write(dmem_write),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_data),
    .st_id_reg_raddr1(st_id_reg_raddr1),
    .st_id_reg_raddr2(st_id_reg_raddr2),
    .st_ex_reg_waddr(st_ex_reg_waddr),
    .st_ex_load_instr(st_ex_load_instr),
    .fl_branch_cond(fl_branch_cond),
    .fw_data1(fw_control_out.fw_data1),
    .fw_enable1(fw_control_out.fw_enable1),
    .fw_data2(fw_control_out.fw_data2),
    .fw_enable2(fw_control_out.fw_enable2),
    .fw_ex_reg_raddr1(fw_control_in.fw_ex_reg_raddr1),
    .fw_ex_reg_raddr2(fw_control_in.fw_ex_reg_raddr2),
    .fw_mem_reg_waddr(fw_control_in.fw_mem_reg_waddr),
    .fw_mem_reg_write(fw_control_in.fw_mem_reg_write),
    .fw_mem_reg_wdata(fw_control_in.fw_mem_reg_wdata),
    .fw_wb_reg_waddr(fw_control_in.fw_wb_reg_waddr),
    .fw_wb_reg_write(fw_control_in.fw_wb_reg_write),
    .fw_wb_reg_wdata(fw_control_in.fw_wb_reg_wdata)
);

fw_controller fwc (
    .fw_control_in(fw_control_in),
    .fw_control_out(fw_control_out)
);

assign flush = fl_branch_cond;
assign stall = st_ex_load_instr && (
    (st_id_reg_raddr1 == st_ex_reg_waddr) ||
    (st_id_reg_raddr2 == st_ex_reg_waddr)
);

endmodule