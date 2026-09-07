module riscv_regfile (
    input logic clk,
    input logic reset,
    input logic write_enable,
    input logic [63:0] write_data,
    input logic [4:0] write_addr,
    input logic [4:0] read_addr1,
    input logic [4:0] read_addr2,
    output logic [63:0] read_port1,
    output logic [63:0] read_port2
);

logic [63:0] data [0:31];
logic write_addr_nonzero, read_addr1_nonzero, read_addr2_nonzero;

always_comb begin
    write_addr_nonzero = |write_addr;
    read_addr1_nonzero = |read_addr1;
    read_addr2_nonzero = |read_addr2;
end

integer i;

always_ff @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < 32; i = i + 1) begin
            data[i] <= 64'b0;
        end
        read_port1 <= '0;
        read_port2 <= '0;
    end
    else begin
        if (write_enable && write_addr_nonzero) begin
            data[write_addr] <= write_data;
        end

        read_port1 <= data[read_addr1] & {64{read_addr1_nonzero}};
        read_port2 <= data[read_addr2] & {64{read_addr2_nonzero}};
    end
end

endmodule

module packed_dff #(
    parameter WORD_SIZE = 64
)(
    input logic clk,
    input logic reset,
    input logic write_enable,
    input logic [WORD_SIZE - 1 : 0] write_data,
    output logic [WORD_SIZE - 1 : 0] stored_data
);

always_ff @(posedge clk) begin
    if (reset) begin
        stored_data <= {(WORD_SIZE){1'b0}};
    end
    else if (write_enable) begin
        stored_data <= write_data;
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