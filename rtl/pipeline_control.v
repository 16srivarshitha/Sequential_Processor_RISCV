module pipeline_control (
    input wire [6:0] opcode,
    
    // Control signals
    output reg Branch,
    output reg MemRead,
    output reg MemtoReg,
    output reg [1:0] ALUOp,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite
);

    // Opcode definitions
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_ITYPE  = 7'b0010011;  // I-type ALU operations
    
    always @(*) begin
        // Default values
        Branch = 0;
        MemRead = 0;
        MemtoReg = 0;
        ALUOp = 2'b00;
        MemWrite = 0;
        ALUSrc = 0;
        RegWrite = 0;
        
        case (opcode)
            OP_RTYPE: begin
                // R-type: ADD, SUB, AND, OR, etc.
                RegWrite = 1;
                ALUOp = 2'b10;
                ALUSrc = 0;
                MemtoReg = 0;
                MemRead = 0;
                MemWrite = 0;
                Branch = 0;
            end
            
            OP_LOAD: begin
                // Load: LD
                RegWrite = 1;
                ALUOp = 2'b00;
                ALUSrc = 1;
                MemtoReg = 1;
                MemRead = 1;
                MemWrite = 0;
                Branch = 0;
            end
            
            OP_STORE: begin
                // Store: SD
                RegWrite = 0;
                ALUOp = 2'b00;
                ALUSrc = 1;
                MemtoReg = 0;
                MemRead = 0;
                MemWrite = 1;
                Branch = 0;
            end
            
            OP_BRANCH: begin
                // Branch: BEQ
                RegWrite = 0;
                ALUOp = 2'b01;
                ALUSrc = 0;
                MemtoReg = 0;
                MemRead = 0;
                MemWrite = 0;
                Branch = 1;
            end
            
            OP_ITYPE: begin
                // I-type ALU: ADDI, ANDI, ORI, etc.
                RegWrite = 1;
                ALUOp = 2'b10;
                ALUSrc = 1;
                MemtoReg = 0;
                MemRead = 0;
                MemWrite = 0;
                Branch = 0;
            end
            
            default: begin
                // NOP or invalid instruction
                RegWrite = 0;
                ALUOp = 2'b00;
                ALUSrc = 0;
                MemtoReg = 0;
                MemRead = 0;
                MemWrite = 0;
                Branch = 0;
            end
        endcase
    end

endmodule