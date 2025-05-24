module writeback (
    // Input signals from memory stage
    input wire [63:0] ReadData,       // Data read from memory
    input wire [63:0] ALUResult,      // Result from ALU
    input wire [4:0] Rd,              // Destination register
    
    // Control signals from memory stage
    input wire MemtoReg,              // Memory to register control
    input wire RegWrite,              // Register write control
    
    // Output signals to register file
    output wire [63:0] WriteData,     // Data to write to register file
    output wire [4:0] WriteReg,       // Register to write to
    output wire RegWriteOut           // Register write control
);
    // Select data to write back to register file
    assign WriteData = MemtoReg ? ReadData : ALUResult;
    
    // Pass through destination register
    assign WriteReg = Rd;
    
    // Pass through register write control
    assign RegWriteOut = RegWrite;
    
endmodule