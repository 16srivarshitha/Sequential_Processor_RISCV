module execute (
    input wire [63:0] ReadData1,
    input wire [63:0] ReadData2,
    input wire [63:0] ImmExt,
    input wire [4:0] Rd,
    input wire [3:0] ALUOp,
    input wire ALUSrc,
    input wire Branch,
    input wire MemRead,
    input wire MemtoReg,
    input wire MemWrite,
    input wire RegWrite,
    
    output wire [63:0] ALUResult,
    output wire Zero,
    output wire BranchTaken,
    output wire [63:0] WriteData,
    output wire [4:0] RdOut,
    output wire MemReadOut,
    output wire MemtoRegOut,
    output wire MemWriteOut,
    output wire RegWriteOut
);

    // ALU input selection
    wire [63:0] ALUInput2 = ALUSrc ? ImmExt : ReadData2;
    
    // ALU computation
    reg [63:0] alu_result;
    reg zero_flag;
    
    always @(*) begin
        case (ALUOp)
            4'b0010: alu_result = ReadData1 + ALUInput2;  // ADD
            4'b0110: alu_result = ReadData1 - ALUInput2;  // SUB
            4'b0111: alu_result = ReadData1 & ALUInput2;  // AND
            4'b0001: alu_result = ReadData1 | ALUInput2;  // OR
            4'b0000: alu_result = ReadData1 + ALUInput2;  // ADD (for ld/sd)
            default: alu_result = 64'd0;
        endcase
        
        zero_flag = (alu_result == 64'd0);
    end
    
    // Branch decision
    assign BranchTaken = Branch & zero_flag;
    
    // Outputs
    assign ALUResult = alu_result;
    assign Zero = zero_flag;
    assign WriteData = ReadData2;
    assign RdOut = Rd;
    
    // Control forwarding
    assign MemReadOut = MemRead;
    assign MemtoRegOut = MemtoReg;
    assign MemWriteOut = MemWrite;
    assign RegWriteOut = RegWrite;

endmodule