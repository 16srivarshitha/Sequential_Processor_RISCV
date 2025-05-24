module instruction_fetch (
    input wire clk,              // System clock
    input wire rst_n,            // Active low reset
    input wire stall,            // Stall signal from hazard unit
    input wire branch_taken,     // Branch taken signal
    input wire [63:0] branch_target_addr, // Branch target address
    output reg [31:0] instruction,  // 32-bit instruction fetched
    output reg [63:0] pc_current,   // Current program counter
    output reg [63:0] pc_next       // Next program counter (pc+4)
);

    // Instruction memory (could be replaced with actual memory interface)
    reg [31:0] instr_mem [0:1023];  // 1024 entries of 32-bit instructions
    
    // Initialize PC
    initial begin
        pc_current = 64'h0000_0000_0000_0000;  // Starting address
        pc_next = 64'h0000_0000_0000_0004;     // Initialize pc_next as well
        instruction = 32'h0000_0000;           // Initialize instruction to NOP
    end
    
    // Instruction fetch logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            pc_current <= 64'h0000_0000_0000_0000;
            pc_next <= 64'h0000_0000_0000_0004;
            instruction <= 32'h0000_0000;  // NOP instruction
        end 
        else if (!stall) begin
            // Update PC
            if (branch_taken) begin
                pc_current <= branch_target_addr;  // Jump to branch target
                pc_next <= branch_target_addr + 64'h4;
            end 
            else begin
                pc_current <= pc_next;  // Normal sequential execution
                pc_next <= pc_next + 64'h4;
            end
            
            // Fetch instruction from memory based on PC
            // The memory is accessed using the PC value directly
            // For proper alignment, we need to select the correct word
            instruction <= instr_mem[(pc_current >> 2)];
        end
        // If stalled, maintain the current state (PC and instruction remain unchanged)
    end
    
    // Memory initialization could be done here or via external file
    // initial $readmemh("program.hex", instr_mem);

endmodule