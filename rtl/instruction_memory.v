module instruction_memory #(
    parameter MEM_SIZE = 4096
)(
    input wire [11:0] address,
    output wire [31:0] instruction
);

    reg [7:0] memory [0:MEM_SIZE-1];
    
    // Read instruction (32-bit aligned)
    assign instruction = {memory[address + 3],
                         memory[address + 2],
                         memory[address + 1],
                         memory[address]};
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            memory[i] = 8'b0;
        end
        
        // Load from file if provided
        if ($test$plusargs("INSTR_MEM_FILE")) begin
            $readmemh("instruction_memory.hex", memory);
        end
    end

endmodule