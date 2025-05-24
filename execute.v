module execute (
    input wire [63:0] ReadData1,       // Value from register rs1
    input wire [63:0] ReadData2,       // Value from register rs2
    input wire [63:0] ImmExt,          // Extended immediate value
    input wire [4:0] Rd,               // Destination register
    input wire [3:0] ALUOp,            // ALU operation code
    input wire ALUSrc,                 // ALU source selector (0: reg, 1: imm)
    
    // Control signals from decode stage
    input wire Branch,                 // Branch instruction
    input wire MemRead,                // Load instruction
    input wire MemtoReg,               // Load instruction
    input wire MemWrite,               // Store instruction
    input wire RegWrite,               // Register write control
    
    // Output signals to memory stage
    output wire [63:0] ALUResult,      // ALU computation result
    output wire Zero,                  // Zero flag for branch decisions
    output wire BranchTaken,           // Indicates if branch should be taken
    output wire [63:0] WriteData,      // Data to be written to memory (for store)
    output wire [4:0] RdOut,           // Destination register
    
    // Control signals to memory stage
    output wire MemReadOut,            // Load instruction
    output wire MemtoRegOut,           // Load instruction
    output wire MemWriteOut,           // Store instruction
    output wire RegWriteOut            // Register write control
);

    // ALU input selection
    wire [63:0] ALUInput1, ALUInput2;
    
    // First ALU input is always ReadData1 (rs1 value)
    assign ALUInput1 = ReadData1;
    
    // Second ALU input depends on ALUSrc control signal
    assign ALUInput2 = (ALUSrc) ? ImmExt : ReadData2;
    
    // ALU Operation
    reg [63:0] alu_result;
    reg zero_flag;
    
    always @(*) begin
        // ALU operations based on ALUOp
        case (ALUOp)
            4'b0010: alu_result = ALUInput1 + ALUInput2;           // ADD
            4'b0110: alu_result = ALUInput1 - ALUInput2;           // SUB
            4'b0111: alu_result = ALUInput1 & ALUInput2;           // AND
            4'b0001: alu_result = ALUInput1 | ALUInput2;           // OR
            4'b0000: alu_result = ALUInput1 + ALUInput2;           // Add for ld/sd
            default: alu_result = 64'h0;                           // Default case
        endcase
        
        // Set Zero flag if result is zero (for branch instructions)
        zero_flag = (alu_result == 64'h0);
    end
    
    // Branch logic for beq instruction
    // BranchTaken is high when:
    // 1. It's a branch instruction (Branch = 1)
    // 2. The comparison result is equal (Zero = 1)
    assign BranchTaken = Branch & zero_flag;
    
    // Assign outputs directly (single-cycle, no pipeline registers needed)
    assign ALUResult = alu_result;
    assign Zero = zero_flag;
    assign WriteData = ReadData2;      // Forward rs2 value for store operations
    assign RdOut = Rd;                 // Forward destination register
    
    // Forward control signals directly
    assign MemReadOut = MemRead;
    assign MemtoRegOut = MemtoReg;
    assign MemWriteOut = MemWrite;
    assign RegWriteOut = RegWrite;

endmodule