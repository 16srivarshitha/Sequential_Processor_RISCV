module unified_memory #(
    parameter MEM_SIZE = 12288  // 12KB total (4KB instruction + 8KB data)
)(
    input wire clk,
    input wire reset,
    
    // Memory control signals
    input wire MemRead,
    input wire MemWrite,
    input wire IorD,  // 0 = instruction fetch (PC), 1 = data access (ALUOut)
    
    // Address inputs
    input wire [63:0] pc_addr,
    input wire [63:0] data_addr,
    
    // Data inputs
    input wire [63:0] write_data,
    
    // Data outputs
    output reg [31:0] instruction,
    output reg [63:0] read_data
);

    // Memory array - byte addressable
    reg [7:0] memory [0:MEM_SIZE-1];
    
    // Address selection
    wire [63:0] address;
    assign address = IorD ? data_addr : pc_addr;
    
    // Ensure address is within bounds
    wire [63:0] bounded_addr;
    assign bounded_addr = (address >= MEM_SIZE) ? 64'b0 : address;
    
    // Memory read operation
    always @(*) begin
        if (MemRead) begin
            if (IorD) begin
                // Data read (64-bit)
                read_data = {
                    memory[bounded_addr + 7],
                    memory[bounded_addr + 6],
                    memory[bounded_addr + 5],
                    memory[bounded_addr + 4],
                    memory[bounded_addr + 3],
                    memory[bounded_addr + 2],
                    memory[bounded_addr + 1],
                    memory[bounded_addr]
                };
            end else begin
                // Instruction fetch (32-bit)
                instruction = {
                    memory[bounded_addr + 3],
                    memory[bounded_addr + 2],
                    memory[bounded_addr + 1],
                    memory[bounded_addr]
                };
                read_data = 64'b0;
            end
        end else begin
            instruction = 32'b0;
            read_data = 64'b0;
        end
    end
    
    // Memory write operation
    always @(posedge clk) begin
        if (MemWrite && IorD) begin
            memory[bounded_addr]     <= write_data[7:0];
            memory[bounded_addr + 1] <= write_data[15:8];
            memory[bounded_addr + 2] <= write_data[23:16];
            memory[bounded_addr + 3] <= write_data[31:24];
            memory[bounded_addr + 4] <= write_data[39:32];
            memory[bounded_addr + 5] <= write_data[47:40];
            memory[bounded_addr + 6] <= write_data[55:48];
            memory[bounded_addr + 7] <= write_data[63:56];
        end
    end
    
    // Initialize memory from file
    integer i;
    initial begin
        // Initialize all memory to zero
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            memory[i] = 8'b0;
        end
        
        // Load instruction memory (first 4KB)
        if ($test$plusargs("INSTR_MEM_FILE")) begin
            $readmemh("instruction_memory.hex", memory, 0, 4095);
        end
        
        // Load data memory (next 8KB)
        if ($test$plusargs("DATA_MEM_FILE")) begin
            $readmemh("data_memory.hex", memory, 4096, 12287);
        end
    end

endmodule