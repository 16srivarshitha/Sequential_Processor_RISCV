module instruction_fetch (
    input wire clk,
    input wire rst_n,
    input wire stall,
    input wire branch_taken,
    input wire [63:0] branch_target_addr,
    output reg [31:0] instruction,
    output reg [63:0] pc_current
);

// Instruction memory - 1024 x 32-bit
reg [31:0] instr_mem [0:1023];

wire [63:0] pc_next;
assign pc_next = branch_taken ? branch_target_addr : (pc_current + 64'd4);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_current <= 64'h0;
        instruction <= 32'h00000013; // NOP
    end 
    else if (!stall) begin
        pc_current <= pc_next;
        instruction <= instr_mem[pc_current[11:2]]; 
    end
    // If stalled, maintain current state
end

endmodule