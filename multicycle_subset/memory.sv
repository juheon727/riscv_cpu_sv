module synchronous_memory #(
    parameter ADDR_WIDTH = 12,
    parameter WORD_SIZE = 64
)(
    input logic clk,
    input logic reset,
    input logic read_enable,
    input logic write_enable,
    input logic [WORD_SIZE - 1 : 0] addr,
    input logic [WORD_SIZE - 1 : 0] write_data,
    output logic [WORD_SIZE - 1 : 0] read_data
);

localparam NUM_WORDS = 1 << ADDR_WIDTH;
logic [WORD_SIZE - 1 : 0] memory [0 : NUM_WORDS - 1];

integer i;
always_ff @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < 1 << ADDR_WIDTH - 1; i = i + 1) begin
            memory[i] <= {{WORD_SIZE}{1'b0}};
        end
    end
    
    else begin
        if (write_enable) begin
            memory[addr] <= write_data;
        end
        if (read_enable) begin
            read_data <= memory[addr];
        end
    end
end

endmodule