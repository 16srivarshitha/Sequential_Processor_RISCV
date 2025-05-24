module memory (
    input wire clk,                    // Clock signal
    input wire reset,                  // Reset signal
    
    // Input signals from execute stage
    input wire [63:0] ALUResult,       // Memory address
    input wire [63:0] WriteData,       // Data to write to memory
    input wire [4:0] Rd,               // Destination register
    input wire Zero,                   // Zero flag from ALU
    input wire BranchTaken,            // Branch decision
    
    // Control signals from execute stage
    input wire MemRead,                // Memory read control
    input wire MemWrite,               // Memory write control
    input wire MemtoReg,               // Memory to register control
    input wire RegWrite,               // Register write control
    
    // Output signals to writeback stage
    output wire [63:0] ReadData,       // Data read from memory
    output wire [63:0] ALUResultOut,   // Pass through ALU result
    output wire [4:0] RdOut,           // Pass through destination register
    output wire BranchTakenOut,        // Pass through branch decision
    
    // Control signals to writeback stage
    output wire MemtoRegOut,           // Pass through memory to register control
    output wire RegWriteOut            // Pass through register write control
);

    // Memory array (64-bit words)
    // 1024 locations = 8KB of memory
    reg [63:0] memory [0:1023];
    
    // Declare read_data register
    reg [63:0] read_data;
    
    // Initialize memory with zeros
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] = 64'h0;
        end
    end
    
    // Memory read logic
    always @(*) begin
        if (MemRead) begin
            // Check if address is within bounds
            if (ALUResult >> 3 < 1024) begin
                read_data = memory[ALUResult >> 3]; // Address divided by 8 (for 64-bit words)
            end else begin
                read_data = 64'h0; // Return 0 for out-of-bounds
            end
        end else begin
            read_data = 64'h0;
        end
    end
    
    // Memory write logic
    always @(posedge clk) begin
        if (reset) begin
            // Reset memory (optional, can be removed if not needed)
            for (i = 0; i < 1024; i = i + 1) begin
                memory[i] <= 64'h0;
            end
        end else if (MemWrite) begin
            // Check if address is within bounds
            if (ALUResult >> 3 < 1024) begin
                memory[ALUResult >> 3] <= WriteData;
            end
        end
    end
    
    // Output assignments
    assign ReadData = read_data;
    assign ALUResultOut = ALUResult;
    assign RdOut = Rd;
    assign BranchTakenOut = BranchTaken;
    
    // Control signal forwarding
    assign MemtoRegOut = MemtoReg;
    assign RegWriteOut = RegWrite;
    
endmodule